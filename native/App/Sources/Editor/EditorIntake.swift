import SwiftUI
import AidesCore
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics
#if canImport(PhotosUI)
import PhotosUI
#endif

// LA PORTE DES FICHIERS (`UP_KINDS`, `acceptFile`, `upTake`) et LE PRENEUR D'IMAGES (`downscale`).
// Ordre volontaire : la TAILLE d'abord (on refuse sans rien décoder), la SIGNATURE ensuite. Un
// fichier refusé EN SILENCE est pire qu'un fichier accepté à tort : chaque refus se dit.
//
// Images : réduites à 1 180 px de côté au plus (jamais agrandies), orientation appliquée, RÉ-ENCODÉES
// en JPEG qualité 0,78 — WebP ne s'encode pas nativement sur iOS, et une data-URI HEIC serait
// rejetée par `safeImg` chez les autres clients. Le ré-encodage retire EXIF et position GPS.
// Écart assumé : une image à transparence est posée sur fond BLANC avant l'encodage (le canvas du
// web la noircissait en JPEG ; un schéma sur fond transparent restait lisible en WebP).

enum EdIntake {
    enum Kind { case pdf, image
        var un: String { self == .pdf ? "un PDF" : "une image" }
        var ind: String { self == .pdf ? "PDF" : "PNG · JPEG · WebP · HEIC" }
        var max: Int { self == .pdf ? Guard.maxPdfBytes : Guard.maxImgBytes }
    }
    struct File { var name: String; var data: Data? }
    struct Img { var data: String; var w: Int; var h: Int }

    /// `upShortName(n)` : ≤ 44 caractères, « … » au-delà.
    static func shortName(_ n: String) -> String {
        var s = Guard.safeFileName(.string(n))
        if s.isEmpty { s = "ce fichier" }
        return s.count > 44 ? String(s.prefix(41)) + "…" : s
    }

    /// `acceptFile(kind, file)` : rend la phrase de refus, ou nil.
    static func gate(_ kind: Kind, _ f: File) -> String? {
        let nom = shortName(f.name)
        guard let d = f.data else { return "« " + nom + " » est illisible." }
        if d.isEmpty { return "« " + nom + " » est vide." }
        if d.count > kind.max {
            return "« " + nom + " » est trop volumineux (" + EdKit.fmtBytes(d.count) + ") : " + EdKit.fmtBytes(kind.max) + " maximum."
        }
        let ok = kind == .pdf ? Guard.isPdf(d) : Guard.imageKind(d) != nil
        if ok { return nil }
        let autre: String? = Guard.isPdf(d) ? "un PDF" : (Guard.imageKind(d) != nil ? "une image" : (Guard.dataKind(d) != nil ? "un fichier .json ou .zip" : nil))
        let fin = (autre != nil && autre != kind.un) ? "est " + autre! + "." : "n’en est pas un."
        return "Ici, on n’accepte que " + kind.un + " (" + kind.ind + ") — « " + nom + " » " + fin
    }

    /// `upTake` : trie les fichiers, annonce les refus (réponse à un geste : le toast est légitime).
    @MainActor
    static func take(_ kind: Kind, _ files: [File], model: AppModel) -> [File] {
        var ok: [File] = [], bad: [String] = []
        for f in files { if let why = gate(kind, f) { bad.append(why) } else { ok.append(f) } }
        if !bad.isEmpty {
            model.toast("⚠ " + (bad.count > 1 ? "\(bad.count) fichiers ignorés — " + bad[0] : bad[0]), seconds: 8)
        }
        return ok
    }

    /// Lit les fichiers choisis (accès « security-scoped » des sélecteurs du système).
    static func read(_ urls: [URL]) -> [File] {
        urls.map { u in
            let scoped = u.startAccessingSecurityScopedResource()
            defer { if scoped { u.stopAccessingSecurityScopedResource() } }
            return File(name: u.lastPathComponent, data: try? Data(contentsOf: u))
        }
    }

    // MARK: Documents PDF (`upPdfTaker`)

    /// Ajoute les PDF acceptés : 10 au plus par entité ; chaque blob est écrit tout de suite et suivi
    /// dans `newAtts` (purgé si le brouillon est abandonné).
    @MainActor
    static func takePdfs(_ files: [File], existing: Int, model: AppModel, add: (Attachment) -> Void) {
        var n = existing
        for f in take(.pdf, files, model: model) {
            if n >= Guard.maxAttPerEntity { model.toast("⚠ \(Guard.maxAttPerEntity) documents maximum.", seconds: 6); break }
            guard let d = f.data else { model.toast("⚠ « " + shortName(f.name) + " » est illisible.", seconds: 6); continue }
            do {
                var a = try model.library.addAttachment(data: d, name: f.name)
                if a.name.isEmpty { a.name = "document.pdf" }
                add(a)
                n += 1
            } catch {
                model.toast("⚠ Stockage saturé : document non enregistré.", seconds: 9)
                break
            }
        }
    }

    // MARK: Images (`edImgTaker`, `pImgTaker`, `downscale`)

    @MainActor
    static func takeImages(_ files: [File], existing: Int, single: Bool, tooMany: String, model: AppModel, add: (Img) -> Void) {
        var n = existing
        for f in take(.image, files, model: model) {
            if !single && n >= Guard.maxImgPerEntity { model.toast(tooMany, seconds: 6); break }
            guard let d = f.data, let img = downscale(d) else {
                model.toast("⚠ « " + shortName(f.name) + " » est illisible.", seconds: 6); continue
            }
            add(img)
            n += 1
            if single { break }
        }
    }

    /// `downscale(file, 1180, 0.78)` : même calcul que le web (`Math.round`), orientation appliquée.
    static func downscale(_ data: Data, maxDim: Double = 1180, quality: Double = 0.78) -> Img? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(src) > 0 else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        var w = (props?[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? 0
        var h = (props?[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? 0
        let orient = (props?[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        if orient >= 5 { swap(&w, &h) }
        guard w > 0, h > 0 else { return nil }
        let sc = min(1, maxDim / max(w, h))
        let cw = Int(JS.round(w * sc)), ch = Int(JS.round(h * sc))
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(cw, ch),
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        // Fond blanc sous la transparence, dimensions exactes du calcul du web.
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: cw, height: ch, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))  // design: fond blanc du JPEG produit (donnée image, pas interface)
        ctx.fill(CGRect(x: 0, y: 0, width: cw, height: ch))
        ctx.interpolationQuality = .high
        ctx.draw(thumb, in: CGRect(x: 0, y: 0, width: cw, height: ch))
        guard let flat = ctx.makeImage() else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, flat, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        let uri = "data:image/jpeg;base64," + (out as Data).base64EncodedString()
        guard Guard.safeImg(.string(uri)) != nil else { return nil }
        return Img(data: uri, w: cw, h: ch)
    }

    #if canImport(PhotosUI)
    /// Photothèque : les éléments choisis, lus en données brutes.
    static func load(_ items: [PhotosPickerItem]) async -> [File] {
        var out: [File] = []
        for it in items {
            let d = try? await it.loadTransferable(type: Data.self)
            out.append(File(name: "photo", data: d))
        }
        return out
    }
    #endif

    /// Types proposés au sélecteur de fichiers.
    static func types(_ k: EdImport) -> [UTType] {
        switch k {
        case .pdf: return [.pdf]
        case .image:
            var t: [UTType] = [.png, .jpeg, .gif, .heic]
            if let w = UTType("org.webmproject.webp") { t.append(w) }
            if let h = UTType("public.heif") { t.append(h) }
            return t
        }
    }
}

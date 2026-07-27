// Décodeur QR INDÉPENDANT — utilisé par scripts/audit-qr.mjs.
//
// POURQUOI CE FICHIER EXISTE. Un encodeur QR peut produire des matrices parfaitement dessinées et
// parfaitement illisibles : motifs au bon endroit, format valide, et pourtant aucun lecteur n'y
// arrive. Aucun contrôle de cohérence interne ne le voit — seul un DÉCODEUR le voit. Celui-ci est
// celui d'Apple (CoreImage), c'est-à-dire exactement celui qu'utilise l'appareil photo de
// l'iPhone : la cible réelle de la fonctionnalité.
//
// Lit un fichier texte de lignes « 0101… » (1 = module sombre), en fabrique une image avec zone de
// silence, la décode, et imprime « OK:<contenu> » ou « ERR:<motif> ».
import Foundation
import CoreImage
import AppKit

/* DEUX ENTRÉES, ET LA SECONDE EXISTE PARCE QUE LA PREMIÈRE ÉTAIT AVEUGLE (v4.47.0).
   Décoder la MATRICE prouve que l'encodeur est juste. Elle ne prouve RIEN sur ce qu'un iPhone
   photographie : entre la matrice et l'appareil photo il y a la génération du SVG, des variables
   CSS de couleur, un `shape-rendering`, une taille en `vw` et un rendu sous-pixel. Un utilisateur
   a rapporté « aucune donnée utilisable trouvée » sur un QR que ce harnais déclarait bon — le
   contrôle était donc aveugle au défaut qu'il prétend couvrir (leçon v4.31.1).
   Passer un fichier `.png` décode donc l'IMAGE RÉELLEMENT PEINTE, capturée dans le navigateur. */
let args = CommandLine.arguments
if args.count >= 2, args[1].hasSuffix(".png") {
    guard let img = NSImage(contentsOfFile: args[1]),
          let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let cgp = rep.cgImage else { print("ERR:png"); exit(2) }
    let det = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                         options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
    let f = det.features(in: CIImage(cgImage: cgp)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    if let s = f.first { print("OK:" + s) } else { print("ERR:indéchiffrable") }
    exit(0)
}
guard args.count >= 2, let txt = try? String(contentsOfFile: args[1], encoding: .utf8) else {
    print("ERR:lecture"); exit(2)
}
let rows = txt.split(separator: "\n").map { Array($0) }
guard let n = rows.first?.count, n > 0, rows.count == n else { print("ERR:matrice"); exit(2) }

let quiet = 4, scale = 8
let side = (n + quiet * 2) * scale
guard let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                          bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(),
                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { print("ERR:ctx"); exit(2) }
ctx.setFillColor(gray: 1, alpha: 1)
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
ctx.setFillColor(gray: 0, alpha: 1)
for y in 0..<n {
    for x in 0..<n where rows[y][x] == "1" {
        // L'origine de CGContext est en BAS à gauche ; la matrice se lit du HAUT vers le bas.
        ctx.fill(CGRect(x: (x + quiet) * scale, y: (n - 1 - y + quiet) * scale,
                        width: scale, height: scale))
    }
}
guard let cg = ctx.makeImage() else { print("ERR:image"); exit(2) }

let det = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                     options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
let found = det.features(in: CIImage(cgImage: cg)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
if let s = found.first { print("OK:" + s) } else { print("ERR:indéchiffrable") }

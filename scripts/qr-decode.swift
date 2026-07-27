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

let args = CommandLine.arguments
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

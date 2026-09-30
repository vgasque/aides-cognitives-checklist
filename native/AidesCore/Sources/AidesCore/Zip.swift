import Foundation
#if canImport(Compression)
import Compression
#endif

/// ZIP maison — conteneur d'export « avec documents » (port de `zipBuild`/`zipParse`, v4.5.0).
///
/// Écriture STORE seul (PDF déjà compressés), noms UTF-8 (drapeau 0x0800), horodatage DOS fixe
/// 1980-01-01 : un export au contenu identique produit des octets identiques.
/// Lecture STORE + DEFLATE, CRC vérifié : une archive endommagée est rejetée d'un bloc, jamais
/// importée à moitié. Bornes anti-« zip bomb » identiques à la PWA.
public enum Zip {
    public struct Entry: Equatable {
        public var name: String
        public var data: Data
        public init(name: String, data: Data) { self.name = name; self.data = data }
    }

    public enum Failure: Error, Equatable, CustomStringConvertible {
        case message(String)
        public var description: String { if case .message(let m) = self { return m }; return "" }
    }

    public static let maxEntry = 64 * 1024 * 1024
    public static let maxTotal = 256 * 1024 * 1024
    public static let maxEntries = 1000

    // MARK: CRC-32 (polynôme 0xEDB88320)
    private static let crcTable: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
        return c
    }
    public static func crc32(_ d: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        d.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            for b in p { c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        }
        return c ^ 0xFFFFFFFF
    }

    /// Détection par SIGNATURE (PK\x03\x04), jamais par extension.
    public static func looksLikeZip(_ d: Data) -> Bool {
        d.count >= 4 && d[d.startIndex] == 0x50 && d[d.startIndex + 1] == 0x4B && d[d.startIndex + 2] == 3 && d[d.startIndex + 3] == 4
    }

    // MARK: Écriture
    public static func build(_ entries: [Entry]) -> Data {
        var out = Data()
        var central = Data()
        var count: UInt16 = 0
        func u16(_ v: Int, _ d: inout Data) { d.append(UInt8(v & 255)); d.append(UInt8((v >> 8) & 255)) }
        func u32(_ v: UInt32, _ d: inout Data) { for s in stride(from: 0, to: 32, by: 8) { d.append(UInt8((v >> UInt32(s)) & 255)) } }
        for e in entries {
            let name = Data(e.name.utf8)
            let crc = crc32(e.data)
            let off = UInt32(out.count)
            out.append(contentsOf: [0x50, 0x4B, 3, 4])
            u16(20, &out); u16(0x0800, &out); u16(0, &out); u16(0, &out); u16(0x21, &out)
            u32(crc, &out); u32(UInt32(e.data.count), &out); u32(UInt32(e.data.count), &out)
            u16(name.count, &out); u16(0, &out)
            out.append(name); out.append(e.data)
            central.append(contentsOf: [0x50, 0x4B, 1, 2])
            u16(20, &central); u16(20, &central); u16(0x0800, &central); u16(0, &central); u16(0, &central); u16(0x21, &central)
            u32(crc, &central); u32(UInt32(e.data.count), &central); u32(UInt32(e.data.count), &central)
            u16(name.count, &central); u16(0, &central); u16(0, &central); u16(0, &central); u16(0, &central)
            u32(0, &central); u32(off, &central)
            central.append(name)
            count += 1
        }
        let cdOff = UInt32(out.count)
        out.append(central)
        out.append(contentsOf: [0x50, 0x4B, 5, 6])
        u16(0, &out); u16(0, &out); u16(Int(count), &out); u16(Int(count), &out)
        u32(UInt32(central.count), &out); u32(cdOff, &out); u16(0, &out)
        return out
    }

    // MARK: Lecture
    public static func parse(_ data: Data) throws -> [Entry] {
        let u8 = [UInt8](data)
        guard u8.count >= 22 else { throw Failure.message("zip: archive vide") }
        func rd16(_ o: Int) throws -> Int {
            guard o >= 0, o + 2 <= u8.count else { throw Failure.message("zip: entrée corrompue") }
            return Int(u8[o]) | (Int(u8[o + 1]) << 8)
        }
        func rd32(_ o: Int) throws -> Int {
            guard o >= 0, o + 4 <= u8.count else { throw Failure.message("zip: entrée corrompue") }
            return Int(u8[o]) | (Int(u8[o + 1]) << 8) | (Int(u8[o + 2]) << 16) | (Int(u8[o + 3]) << 24)
        }
        func sig(_ o: Int, _ a: UInt8, _ b: UInt8) -> Bool {
            o >= 0 && o + 4 <= u8.count && u8[o] == 0x50 && u8[o + 1] == 0x4B && u8[o + 2] == a && u8[o + 3] == b
        }
        var e = -1
        var i = u8.count - 22
        let minI = max(0, u8.count - 22 - 65535)
        while i >= minI { if sig(i, 5, 6) { e = i; break }; i -= 1 }
        guard e >= 0 else { throw Failure.message("zip: répertoire introuvable") }
        let n = min(try rd16(e + 10), maxEntries)
        var o = try rd32(e + 16)
        var out: [Entry] = []
        var total = 0
        var seenLo = Set<Int>()
        for _ in 0..<n {
            guard sig(o, 1, 2) else { throw Failure.message("zip: entrée corrompue") }
            let method = try rd16(o + 10), crc = UInt32(truncatingIfNeeded: try rd32(o + 16))
            let csize = try rd32(o + 20), usize = try rd32(o + 24)
            let nl = try rd16(o + 28), xl = try rd16(o + 30), cl = try rd16(o + 32), lo = try rd32(o + 42)
            if csize > maxEntry || usize > maxEntry { throw Failure.message("zip: entrée trop volumineuse") }
            if total + usize > maxTotal { throw Failure.message("zip: archive trop volumineuse") }
            guard o + 46 + nl <= u8.count else { throw Failure.message("zip: entrée corrompue") }
            let name = String(decoding: u8[(o + 46)..<(o + 46 + nl)], as: UTF8.self)
            guard sig(lo, 3, 4) else { throw Failure.message("zip: entrée corrompue") }
            if seenLo.contains(lo) { throw Failure.message("zip: entrée dupliquée") }
            seenLo.insert(lo)
            let ds = lo + 30 + (try rd16(lo + 26)) + (try rd16(lo + 28))
            guard ds >= 0, ds + csize <= u8.count else { throw Failure.message("zip: entrée corrompue") }
            var payload = Data(u8[ds..<(ds + csize)])
            if method == 8 { payload = try inflateRaw(payload, limit: usize) }
            else if method != 0 { throw Failure.message("zip: méthode non prise en charge") }
            if payload.count != usize || crc32(payload) != crc { throw Failure.message("zip: contenu endommagé") }
            total += payload.count
            out.append(Entry(name: name, data: payload))
            o += 46 + nl + xl + cl
        }
        return out
    }

    /// DEFLATE brut borné : s'arrête NET au-delà de `limit` octets produits.
    static func inflateRaw(_ input: Data, limit: Int) throws -> Data {
        #if canImport(Compression)
        if limit == 0 { return Data() }
        var dst = Data(count: limit + 1)
        let produced: Int = input.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Int in
            dst.withUnsafeMutableBytes { (d: UnsafeMutableRawBufferPointer) -> Int in
                guard let s = src.baseAddress, let dp = d.baseAddress else { return 0 }
                return compression_decode_buffer(dp.assumingMemoryBound(to: UInt8.self), limit + 1,
                                                 s.assumingMemoryBound(to: UInt8.self), input.count,
                                                 nil, COMPRESSION_ZLIB)
            }
        }
        if produced > limit { throw Failure.message("zip: contenu trop volumineux") }
        return dst.prefix(produced)
        #else
        throw Failure.message("zip: méthode non prise en charge")
        #endif
    }
}

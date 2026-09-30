import Foundation

/// DEFLATE BRUT (RFC 1951, sans en-tête zlib) — la compression des charges « par l'écran ».
///
/// La PWA emballe l'instantané par `CompressionStream('deflate-raw')` et le déballe par
/// `DecompressionStream('deflate-raw')`, borné à 4 Mio (`ltSnapUnpack`). Le natif doit lire ce
/// que le navigateur produit (Huffman dynamique compris) et produire ce que le navigateur lit.
/// Pur Swift : le framework `Compression` d'Apple n'existe pas sous Linux, et un seul code sur
/// toutes les plateformes est un seul code à vérifier (vecteurs croisés avec la PWA dans
/// `ShareOracleTests`).
///
/// L'encodeur produit des blocs à Huffman FIXE avec LZ77 (fenêtre 32 Kio, chaînes de hachage
/// bornées) : moins dense de quelques pour cent que zlib sur du JSON, mais le rendement se paie
/// en trames QR (195 octets chacune), pas en octets réseau — l'écart reste d'une poignée de trames.
public enum ShareDeflate {
    public enum Failure: Error, Equatable { case corrupt, tooLarge }

    // MARK: Tables communes
    static let lenBase: [Int] = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
    static let lenExtra: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
    static let distBase: [Int] = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
    static let distExtra: [Int] = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
    static let clOrder: [Int] = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

    // MARK: Décompression (bornée)

    struct Huffman {
        var counts = [Int](repeating: 0, count: 16)
        var symbols: [Int] = []
        init(_ lengths: [Int]) {
            for l in lengths { counts[l] += 1 }
            counts[0] = 0
            var offs = [Int](repeating: 0, count: 16)
            for i in 1..<16 { offs[i] = offs[i - 1] + counts[i - 1] }
            symbols = [Int](repeating: 0, count: lengths.count)
            for (s, l) in lengths.enumerated() where l != 0 { symbols[offs[l]] = s; offs[l] += 1 }
        }
    }

    struct BitReader {
        let d: [UInt8]; var pos = 0; var bit = 0
        init(_ d: [UInt8]) { self.d = d }
        mutating func bits(_ n: Int) throws -> Int {
            var v = 0
            for i in 0..<n {
                guard pos < d.count else { throw Failure.corrupt }
                v |= Int((d[pos] >> UInt8(bit)) & 1) << i
                bit += 1; if bit == 8 { bit = 0; pos += 1 }
            }
            return v
        }
        mutating func decode(_ h: Huffman) throws -> Int {
            var code = 0, first = 0, index = 0
            for len in 1..<16 {
                code |= try bits(1)
                let count = h.counts[len]
                if code - count < first { return h.symbols[index + (code - first)] }
                index += count; first += count; first <<= 1; code <<= 1
            }
            throw Failure.corrupt
        }
        mutating func align() { if bit != 0 { bit = 0; pos += 1 } }
    }

    static let fixedLit: Huffman = {
        var l = [Int](repeating: 8, count: 288)
        for i in 144..<256 { l[i] = 9 }
        for i in 256..<280 { l[i] = 7 }
        return Huffman(l)
    }()
    static let fixedDist = Huffman([Int](repeating: 5, count: 30))

    /// Décompresse un flux DEFLATE brut ; échoue NET au-delà de `limit` octets produits
    /// (même précaution qu'`inflateBounded` : le flux d'un QR hostile ne se matérialise pas).
    public static func inflate(_ input: [UInt8], limit: Int = 4_194_304) throws -> [UInt8] {
        var br = BitReader(input)
        var out: [UInt8] = []
        var final = 0
        repeat {
            final = try br.bits(1)
            let type = try br.bits(2)
            if type == 0 {
                br.align()
                guard br.pos + 4 <= input.count else { throw Failure.corrupt }
                let len = Int(input[br.pos]) | Int(input[br.pos + 1]) << 8
                let nlen = Int(input[br.pos + 2]) | Int(input[br.pos + 3]) << 8
                guard len == (~nlen & 0xffff) else { throw Failure.corrupt }
                br.pos += 4
                guard br.pos + len <= input.count else { throw Failure.corrupt }
                if out.count + len > limit { throw Failure.tooLarge }
                out += input[br.pos..<(br.pos + len)]
                br.pos += len
            } else if type == 1 || type == 2 {
                var lit = fixedLit, dist = fixedDist
                if type == 2 {
                    let hlit = try br.bits(5) + 257, hdist = try br.bits(5) + 1, hclen = try br.bits(4) + 4
                    var cl = [Int](repeating: 0, count: 19)
                    for i in 0..<hclen { cl[clOrder[i]] = try br.bits(3) }
                    let clh = Huffman(cl)
                    var lens: [Int] = []
                    while lens.count < hlit + hdist {
                        let sym = try br.decode(clh)
                        if sym < 16 { lens.append(sym) }
                        else if sym == 16 { guard let p = lens.last else { throw Failure.corrupt }; lens += [Int](repeating: p, count: 3 + (try br.bits(2))) }
                        else if sym == 17 { lens += [Int](repeating: 0, count: 3 + (try br.bits(3))) }
                        else { lens += [Int](repeating: 0, count: 11 + (try br.bits(7))) }
                    }
                    guard lens.count == hlit + hdist else { throw Failure.corrupt }
                    lit = Huffman(Array(lens[0..<hlit])); dist = Huffman(Array(lens[hlit...]))
                }
                while true {
                    let sym = try br.decode(lit)
                    if sym < 256 {
                        if out.count >= limit { throw Failure.tooLarge }
                        out.append(UInt8(sym))
                    } else if sym == 256 { break }
                    else {
                        let li = sym - 257
                        guard li < 29 else { throw Failure.corrupt }
                        let len = lenBase[li] + (try br.bits(lenExtra[li]))
                        let ds = try br.decode(dist)
                        guard ds < 30 else { throw Failure.corrupt }
                        let d = distBase[ds] + (try br.bits(distExtra[ds]))
                        guard d <= out.count else { throw Failure.corrupt }
                        if out.count + len > limit { throw Failure.tooLarge }
                        let start = out.count - d
                        for k in 0..<len { out.append(out[start + k]) }
                    }
                }
            } else { throw Failure.corrupt }
        } while final == 0
        return out
    }

    // MARK: Compression (Huffman fixe + LZ77)

    struct BitWriter {
        var out: [UInt8] = []; var acc: UInt32 = 0; var n: UInt32 = 0
        mutating func put(_ v: Int, _ bits: Int) {
            acc |= UInt32(v) << n; n += UInt32(bits)
            while n >= 8 { out.append(UInt8(acc & 0xff)); acc >>= 8; n -= 8 }
        }
        /// Code de Huffman : bits de poids fort d'abord (RFC 1951 § 3.1.1).
        mutating func putRev(_ code: Int, _ len: Int) {
            var r = 0
            for i in 0..<len { r |= ((code >> i) & 1) << (len - 1 - i) }
            put(r, len)
        }
        mutating func flush() -> [UInt8] { if n > 0 { out.append(UInt8(acc & 0xff)) }; acc = 0; n = 0; return out }
    }

    static func putLit(_ w: inout BitWriter, _ s: Int) {
        switch s {
        case 0..<144: w.putRev(0x30 + s, 8)
        case 144..<256: w.putRev(0x190 + (s - 144), 9)
        case 256..<280: w.putRev(s - 256, 7)
        default: w.putRev(0xc0 + (s - 280), 8)
        }
    }

    /// Compresse en DEFLATE brut (un bloc final à Huffman fixe).
    public static func deflate(_ input: [UInt8]) -> [UInt8] {
        var w = BitWriter()
        w.put(1, 1); w.put(1, 2)
        let n = input.count
        let hashSize = 1 << 15
        var head = [Int](repeating: -1, count: hashSize)
        var prev = [Int](repeating: -1, count: max(n, 1))
        @inline(__always) func hash(_ i: Int) -> Int {
            (Int(input[i]) << 10 ^ Int(input[i + 1]) << 5 ^ Int(input[i + 2])) & (hashSize - 1)
        }
        func insert(_ i: Int) { if i + 2 < n { let h = hash(i); prev[i] = head[h]; head[h] = i } }
        var i = 0
        while i < n {
            var bestLen = 0, bestDist = 0
            if i + 2 < n {
                var cand = head[hash(i)], chain = 64
                while cand >= 0, i - cand <= 32768, chain > 0 {
                    var l = 0
                    let maxL = min(258, n - i)
                    while l < maxL, input[cand + l] == input[i + l] { l += 1 }
                    if l > bestLen { bestLen = l; bestDist = i - cand; if l == maxL { break } }
                    cand = prev[cand]; chain -= 1
                }
            }
            if bestLen >= 3 {
                var li = 28
                while lenBase[li] > bestLen { li -= 1 }
                putLit(&w, 257 + li); w.put(bestLen - lenBase[li], lenExtra[li])
                var di = 29
                while distBase[di] > bestDist { di -= 1 }
                w.putRev(di, 5); w.put(bestDist - distBase[di], distExtra[di])
                for k in 0..<bestLen { insert(i + k) }
                i += bestLen
            } else {
                putLit(&w, Int(input[i])); insert(i); i += 1
            }
        }
        putLit(&w, 256)
        return w.flush()
    }
}

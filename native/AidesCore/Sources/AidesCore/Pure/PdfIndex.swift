import Foundation

// CHERCHER DANS LES DOCUMENTS PDF — port de l'index inversé de la PWA (`ixTokens`, `ixBuild`,
// `ixOpen`, `ixPagesOf`, `ixSearch`, `IX_V`).
//
// LE FORMAT BINAIRE EST LE MÊME, OCTET POUR OCTET : dictionnaire front-codé (longueur du préfixe
// commun sur 1 octet, suffixe, 0x0A), postings en écarts varint ou en BITMAP de pages quand c'est
// plus court (drapeau 1/0). Un index construit par un client est donc lisible par l'autre — la PWA
// ne le partage pas aujourd'hui (index DÉRIVÉ, strictement local, reconstruit depuis le PDF), mais
// rien ne l'interdira demain. Même sémantique de recherche : SOUS-CHAÎNE (« drenalin » trouve
// « adrénaline »), ET logique entre les termes, nil si un terme ne trouve rien.
//
// Limite dite : les jetons sont ASCII par construction (`ixTokens` : [a-z0-9]). Un appelant qui
// indexerait d'autres unités verrait la troncature 8 bits d'`Uint8Array.from` reproduite, mais pas
// le décodage UTF-8 de `TextDecoder` (le natif compare des octets) — cas hors de l'usage de l'app.

public enum PdfIndex {
    /// `IX_V` : version du format.
    public static let version = 1

    static let rxSplit = JSRegExp("[^a-z0-9]+")
    /// `ixTokens(s)` : mots indexables (même normalisation que la recherche, 2 à 24 caractères).
    public static func tokens(_ s: String) -> [String] {
        rxSplit.split(Txt.txNorm(s)).filter { JS.length($0) >= 2 && JS.length($0) <= 24 }
    }

    /// Enregistrement rangé (IndexedDB côté web) : `dict` et `post` sont les deux tampons binaires.
    public struct Record: Equatable, Sendable {
        public var v: Int
        public var pages: Int
        public var terms: Int
        public var dict: [UInt8]
        public var post: [UInt8]
        public init(v: Int, pages: Int, terms: Int, dict: [UInt8], post: [UInt8]) { self.v = v; self.pages = pages; self.terms = terms; self.dict = dict; self.post = post }
    }

    static func varint(_ arr: inout [UInt8], _ n0: UInt32) {
        var n = n0
        repeat {
            let b = UInt8(n & 0x7f)
            n >>= 7
            arr.append(n != 0 ? b | 0x80 : b)
        } while n != 0
    }

    /// `ixBuild(pages)` : `pageTokens` = un tableau de mots par page.
    public static func build(_ pageTokens: [[String]]) -> Record {
        let nP = pageTokens.count
        var post: [[UInt16]: [Int]] = [:]
        for (i, toks) in pageTokens.enumerated() {
            var seen = Set<[UInt16]>()
            for t in toks {
                let u = Array(t.utf16)
                if seen.contains(u) { continue }
                seen.insert(u)
                post[u, default: []].append(i)
            }
        }
        // Tri JS par défaut : unités UTF-16.
        let terms = post.keys.sorted { $0.lexicographicallyPrecedes($1) }
        let bm = (nP + 7) / 8
        var dict: [UInt8] = [], pb: [UInt8] = []
        var prev: [UInt16] = []
        for t in terms {
            var k = 0
            while k < prev.count && k < t.count && prev[k] == t[k] { k += 1 }
            dict.append(UInt8(truncatingIfNeeded: k))
            for j in k..<t.count { dict.append(UInt8(truncatingIfNeeded: t[j])) }   // Uint8Array.from : modulo 256
            dict.append(10)
            prev = t
            let l = post[t]!
            var v: [UInt8] = []
            var pv = 0
            for n in l { varint(&v, UInt32(truncatingIfNeeded: n - pv)); pv = n }
            if bm < v.count + 1 {
                pb.append(1)
                var a = [UInt8](repeating: 0, count: bm)
                for p in l { a[p >> 3] |= UInt8(1 << (p & 7)) }
                pb.append(contentsOf: a)
            } else {
                pb.append(0)
                varint(&pb, UInt32(truncatingIfNeeded: l.count))
                pb.append(contentsOf: v)
            }
        }
        return Record(v: version, pages: nP, terms: terms.count, dict: dict, post: pb)
    }

    /// Poignée de recherche (`ixOpen`) : le dictionnaire redevient UNE chaîne d'octets (mots séparés
    /// par 0x0A) + offsets ; les postings ne sont décodés qu'à la demande.
    public struct Handle: Sendable {
        public let pages: Int
        public let n: Int
        let txt: [UInt8]
        let off: [Int]
        let pos: [Int]
        let p: [UInt8]
        let bm: Int
        /// Le mot n° i du dictionnaire.
        public func term(_ i: Int) -> String { String(decoding: txt[off[i]..<max(off[i], off[i + 1] - 1)], as: UTF8.self) }
    }

    /// `ixRdVar` : varint total (un octet hors tampon vaut 0, la lecture s'arrête).
    static func rdVar(_ p: [UInt8], _ i: inout Int) -> UInt32 {
        var v: UInt32 = 0, sh: UInt32 = 0, b: UInt8
        repeat {
            b = i >= 0 && i < p.count ? p[i] : 0
            i += 1
            v |= UInt32(b & 0x7f) << sh
            sh += 7
        } while (b & 0x80) != 0 && sh < 35
        return v
    }

    /// `ixOpen(rec)` : nil si l'enregistrement est d'une autre version, vide, tronqué ou incohérent
    /// (jamais « à moitié »).
    public static func open(_ rec: Record?) -> Handle? {
        guard let rec, rec.v == version else { return nil }
        let d = rec.dict, p = rec.post, n = rec.terms
        if n <= 0 { return nil }
        var need = 0, di = 0, i = 0
        while i < n && di < d.count {
            let k = Int(d[di]); di += 1
            var L = 0
            while di < d.count && d[di] != 10 { di += 1; L += 1 }
            di += 1
            need += k + L + 1
            i += 1
        }
        if i < n { return nil }
        var buf = [UInt8](repeating: 0, count: need)
        var off = [Int](repeating: 0, count: n + 1), pos = [Int](repeating: 0, count: n + 1)
        let bm = (max(0, rec.pages) + 7) / 8
        var o = 0, pStart = 0, pLen = 0, pi = 0
        di = 0
        func at(_ a: [UInt8], _ x: Int) -> UInt8? { x >= 0 && x < a.count ? a[x] : nil }
        for t in 0..<n {
            let k = Int(at(d, di) ?? 0); di += 1
            off[t] = o
            if k > 0 && k <= pLen { for x in 0..<k { buf[o + x] = buf[pStart + x] }; o += k }
            let s = di
            while di < d.count && d[di] != 10 { di += 1 }
            if di > s { for x in s..<di { buf[o] = d[x]; o += 1 } }
            di += 1
            pStart = off[t]; pLen = o - off[t]
            buf[o] = 10; o += 1
            pos[t] = pi
            let flag = at(p, pi); pi += 1
            if flag == 1 { pi += bm }
            else {
                var cur = pi
                let c = rdVar(p, &cur)
                pi = cur
                var j: UInt32 = 0
                while j < c && pi < p.count {
                    while true { let b = at(p, pi) ?? 0; pi += 1; if b & 0x80 == 0 { break } }
                    j += 1
                }
            }
            if pi > p.count + 1 { return nil }
        }
        off[n] = o; pos[n] = pi
        return Handle(pages: max(0, rec.pages), n: n, txt: buf, off: off, pos: pos, p: p, bm: bm)
    }

    /// `ixPagesOf(h, i)` : pages du terme n° i (bornées au document).
    public static func pagesOf(_ h: Handle, _ i: Int) -> [Int] {
        var out: [Int] = []
        var pi = h.pos[i]
        let flag: UInt8? = pi < h.p.count ? h.p[pi] : nil
        pi += 1
        if flag == 1 {
            for b in 0..<h.bm {
                let v = pi + b < h.p.count ? h.p[pi + b] : 0
                if v == 0 { continue }
                for k in 0..<8 where v & (1 << k) != 0 {
                    let pg = b * 8 + k
                    if pg < h.pages { out.append(pg) }
                }
            }
        } else {
            var cur = pi
            let c = min(Int(rdVar(h.p, &cur)), h.pages)
            var acc = 0
            for _ in 0..<max(0, c) {
                acc += Int(rdVar(h.p, &cur))
                if acc < h.pages { out.append(acc) }
            }
        }
        return out
    }
    /// `ixTermAt` : le terme qui contient la position `at` (dichotomie sur les offsets).
    static func termAt(_ h: Handle, _ at: Int) -> Int {
        var lo = 0, hi = h.n - 1, r = -1
        while lo <= hi {
            let m = (lo + hi) >> 1
            if h.off[m] <= at { r = m; lo = m + 1 } else { hi = m - 1 }
        }
        return r
    }
    /// `ixSearch(h, terms)` : pages où TOUS les termes apparaissent (sous-chaîne), triées ; nil si
    /// l'un d'eux ne trouve rien (rien n'est « à peu près » trouvé).
    public static func search(_ h: Handle?, _ terms: [String]) -> [Int]? {
        let T = terms.filter { JS.length($0) >= 2 }
        guard let h, h.n != 0, !T.isEmpty else { return nil }
        var acc: Set<Int>? = nil
        for t in T {
            let tb = Array(t.utf8)
            var set = Set<Int>()
            var at = 0
            while true {
                at = indexOf(h.txt, tb, from: at)
                if at < 0 { break }
                let i = termAt(h, at)
                if i >= 0 { set.formUnion(pagesOf(h, i)) }
                at += 1
            }
            if set.isEmpty { return nil }
            acc = acc.map { $0.intersection(set) } ?? set
            if acc!.isEmpty { return nil }
        }
        return acc!.sorted()
    }
    static func indexOf(_ s: [UInt8], _ t: [UInt8], from: Int) -> Int {
        let n = s.count, m = t.count
        if m == 0 { return from <= n ? from : -1 }
        var i = from
        while i + m <= n {
            if s[i] == t[0] {
                var j = 1
                while j < m && s[i + j] == t[j] { j += 1 }
                if j == m { return i }
            }
            i += 1
        }
        return -1
    }
}

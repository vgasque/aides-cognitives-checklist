import Foundation

// SÉRIALISATION — rend exactement les clés qu'écrit la PWA (export, stockage, synchro).
// Le chemin inverse est TOUJOURS `Sanitize` : rien ne se relit sans repasser par `migrate`.

extension JSON {
    static func str(_ s: String?) -> JSON { s.map { .string($0) } ?? .null }
    static func num(_ d: Double?) -> JSON { d.map { .number($0) } ?? .null }
    static func int(_ i: Int) -> JSON { .number(Double(i)) }
}

extension Item {
    public var json: JSON {
        var o: [String: JSON] = ["id": .string(id), "role": .string(role.rawValue), "do": .string(self.do), "expect": .string(expect),
                                 "level": .int(level), "memory": .bool(memory), "dual": .bool(dual), "note": .string(note)]
        if let starts { o["starts"] = .string(starts) }
        if let counts { o["counts"] = .string(counts) }
        if let from { o["from"] = ["counter": .string(from.counter), "n": .int(from.n)] }
        if let r = self.repeat { o["repeat"] = .string(r.rawValue) }
        if let review { o["review"] = .string(review) }
        if let poso { o["poso"] = .string(poso) }
        return .object(o)
    }
}

extension Excursion {
    public var json: JSON {
        var o: [String: JSON] = ["label": .string(label), "target": .string(target)]
        if let short { o["short"] = .string(short) }
        return .object(o)
    }
}

extension TimerDef {
    public var json: JSON {
        var o: [String: JSON] = ["id": .string(id), "label": .string(label), "type": .string(type.rawValue), "seconds": .int(seconds),
                                 "autoloop": .bool(autoloop), "onDue": .string(onDue)]
        if let short { o["short"] = .string(short) }
        return .object(o)
    }
}

extension CounterDef {
    public var json: JSON {
        var o: [String: JSON] = ["id": .string(id), "label": .string(label), "step": .int(step), "start": .int(start), "timerId": .string(timerId)]
        if let short { o["short"] = .string(short) }
        return .object(o)
    }
}

extension Milestone {
    public var json: JSON {
        ["at": .string(at.rawValue), "n": .int(n), "counter": .string(counter), "text": .string(text), "go": .string(go)]
    }
}

extension Block {
    public var json: JSON {
        var o = extra
        o["id"] = .string(id); o["kind"] = .string(kind.rawValue); o["title"] = .string(title); o["phase"] = .string(phase)
        o["image"] = .str(image); o["imageW"] = .int(imageW); o["imageH"] = .int(imageH)
        if let timer { o["timer"] = .string(timer) }
        o["milestones"] = .array(milestones.map(\.json))
        switch kind {
        case .decision:
            o["question"] = .string(question)
            o["options"] = .array(options.map { ["label": .string($0.label), "target": .str($0.target)] })
        case .do:
            o["items"] = .array(items.map { .string($0) })
            o["next"] = .str(next); o["nextLbl"] = .string(nextLbl)
        case .review:
            o["items"] = .array(items.map { .string($0) })
        }
        return .object(o)
    }
}

extension ImageRef {
    public var json: JSON {
        ["id": .string(id), "data": .string(data), "w": .int(w), "h": .int(h), "caption": .string(caption), "scale": .int(scale)]
    }
}

extension Attachment {
    public var json: JSON { ["id": .string(id), "name": .string(name), "size": .int(size)] }
}

extension Entity {
    func commonJSON(into o: inout [String: JSON]) {
        o["id"] = .string(id); o["title"] = .string(title); o["validatedAt"] = .string(validatedAt); o["category"] = .string(category)
        o["order"] = .number(order); o["images"] = .array(images.map(\.json)); o["docs"] = .array(docs.map(\.json))
        o["status"] = .string(status.rawValue); o["code"] = .string(code); o["discriminant"] = .string(discriminant)
        o["links"] = .array(links.map { .string($0) }); o["updatedBy"] = .string(updatedBy); o["updatedAt"] = .number(updatedAt)
        o["deletedAt"] = .num(deletedAt); o["ownerId"] = .str(ownerId); o["library"] = .str(library)
    }
}

extension Fiche {
    public var json: JSON {
        var o = extra
        commonJSON(into: &o)
        o["v"] = 4; o["kind"] = "procedure"
        o["local"] = .string(local); o["sources"] = .array(sources.map { .string($0) })
        o["items"] = .array(items.map(\.json)); o["excursions"] = .array(excursions.map(\.json))
        o["blocks"] = .array(blocks.map(\.json)); o["start"] = .str(start)
        o["timers"] = .array(timers.map(\.json)); o["counters"] = .array(counters.map(\.json))
        return .object(o)
    }
}

extension Reference {
    public var json: JSON {
        var o = extra
        commonJSON(into: &o)
        o["body"] = .string(body); o["sources"] = .array(sources.map { .string($0) })
        return .object(o)
    }
}

extension Category {
    public var json: JSON { ["id": .string(id), "name": .string(name), "color": .string(color), "library": .str(library)] }
    /// Forme exportée (sans bibliothèque).
    public var exportJSON: JSON { ["id": .string(id), "name": .string(name), "color": .string(color)] }
}

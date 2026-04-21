import Foundation

enum InitialsGenerator {
    static func initials(from text: String?) -> String {
        guard let text else { return "?" }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "?" }

        let words = trimmed
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .filter { !$0.isEmpty }

        if words.isEmpty {
            return String(trimmed.prefix(1)).uppercased()
        }

        if words.count == 1 {
            return String(words[0].prefix(1)).uppercased()
        }

        let first = words.first?.prefix(1) ?? ""
        let last = words.last?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    static func deterministicValue(for text: String) -> UInt64 {
        var hash: UInt64 = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt64(scalar.value)
        }
        return hash
    }
}

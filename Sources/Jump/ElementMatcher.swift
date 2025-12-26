import Foundation

/// Represents a UI element with matching score
struct MatchedElement {
    let element: AccessibleElement
    let score: Int
    let matchedText: String
}

/// Performs substring matching on UI element labels
class ElementMatcher {
    /// Match elements against a search query using substring matching
    /// - Parameters:
    ///   - query: The search text entered by user
    ///   - elements: List of accessible elements to search
    /// - Returns: Sorted list of matched elements (best matches first)
    func match(query: String, appName _: String, in elements: [AccessibleElement]) -> [MatchedElement] {
        guard !query.isEmpty else { return [] }

        let lowercaseQuery = query.lowercased()
        var matches: [MatchedElement] = []

        for element in elements {
            if let (score, matchedText) = calculateMatchScore(
                query: lowercaseQuery,
                element: element
            ) {
                matches.append(MatchedElement(
                    element: element,
                    score: score,
                    matchedText: matchedText
                ))
            }
        }

        // Sort by score (lower is better) and return
        return matches.sorted { $0.score < $1.score }
    }

    /// Calculate match score for an element using substring matching
    /// - Returns: Tuple of (score, matched text) or nil if no match
    private func calculateMatchScore(
        query: String,
        element: AccessibleElement
    ) -> (Int, String)? {
        let candidates: [String]
        let matcher: String
        if query.starts(with: "t ") {
            candidates = [
                element.value,
            ].compactMap { $0 }
            matcher = String(query.dropFirst(2))
        } else {
            candidates = [
                element.label,
                element.title,
                // element.value,
                element.description,
            ].compactMap { $0 }
            matcher = query
        }
        // let candidates = [
        //     element.label,
        //     element.title,
        //     element.value,
        //     element.description
        // ].compactMap { $0 }

        var bestScore: Int?
        var bestMatch: String?

        for candidate in candidates {
            let lowercaseCandidate = candidate.lowercased()

            // Only match if query is a substring
            if lowercaseCandidate.contains(matcher) {
                let score = calculateSubstringScore(
                    query: matcher,
                    in: lowercaseCandidate
                )
                if bestScore == nil || score < bestScore! {
                    bestScore = score
                    bestMatch = candidate
                }
            }
        }

        if let score = bestScore, let match = bestMatch {
            return (score, match)
        }
        return nil
    }

    /// Calculate score for substring matches (lower is better)
    /// Prefers matches at the beginning of the text
    private func calculateSubstringScore(query: String, in text: String) -> Int {
        if let range = text.range(of: query) {
            let position = text.distance(from: text.startIndex, to: range.lowerBound)
            // Score = position (0 = perfect match at start)
            return position
        }
        return Int.max
    }
}

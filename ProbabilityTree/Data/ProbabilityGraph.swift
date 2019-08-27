//  ProbabilityGraph.swift
//  Created by Jake Hawken on 8/8/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

class ProbabilityGraph: FakeMarkovChain {
    private var allWords = Set<Node>()
    private var sentenceLengths = [Int]()
    
    func add(wordSequence words: [String]) {
        var lastNode: Node?
        var sentenceLength = 0
        for word in words {
            let currentNode = findOrCreateNode(forWord: word)
            lastNode?.insertChild(currentNode)
            lastNode = currentNode
            sentenceLength += 1
            if word.isTerminalWord {
                sentenceLengths.append(sentenceLength)
                sentenceLength = 0
            }
        }
    }
    
    func generateSentence() -> String {
        guard let startingNode = allWords.weightedRandomNode(loggingEnabled: true) else {
            return ""
        }
        let sentenceStats = sentenceLengths.stats()
        let words = startingNode.generateSentence(sentenceStats: sentenceStats)
        return words.joined(separator: " ")
    }
    
    func reset() {
        allWords.forEach { $0.clear() }
        allWords.removeAll()
        sentenceLengths.removeAll()
    }
    
    internal func logAllNodes() {
        let string = allWords.map { $0.description }.reduce(into: "", +=)
        print(string)
    }
    
    private func findOrCreateNode(forWord rawWord: String) -> Node {
        if let existing = allWords.first(where: {$0.word == rawWord.strippedOfTrailingSpacesAndTerminators()}) {
            existing.update(withWord: rawWord)
            return existing
        }
        let new = Node(word: rawWord)
        allWords.insert(new)
        return new
    }
}

private extension ProbabilityGraph {
    class Node {
        let word: String
        private(set) var incidence: UInt = 1
        private(set) var nextWords = Set<Node>()
        private(set) var terminatorIncidences = TerminatorIncidences()
        
        private var totalIncidence: UInt {
            return nextWords.map { $0.incidence }.reduce(into: 0, +=)
        }
        
        init(word: String) {
            self.word = word.strippedOfTrailingSpacesAndTerminators()
            updateTerminatorIncidences(forWord: word)
        }
        
        func update(withWord newWord: String) {
            guard newWord.strippedOfTrailingSpacesAndTerminators() == word else {
                return
            }
            incidence += 1
            updateTerminatorIncidences(forWord: newWord)
        }
        
        func clear() {
            nextWords.removeAll()
            terminatorIncidences = TerminatorIncidences()
        }
        
        func insertChild(_ node: Node) {
            nextWords.insert(node)
        }
        
        func generateSentence(sentenceStats stats: Array<Int>.SentenceStats) -> [String] {
            var outputWords = [word]
            if stats.averageLength > 0 {
                appendTo(sentence: &outputWords, sentenceStats: stats)
            }
            return outputWords
        }
        
        private func appendTo(sentence: inout [String], sentenceStats stats: Array<Int>.SentenceStats) {
            sentence.append(word)
            guard let next = nextNode(stats: stats, currentSentenceLength: sentence.count) else {
                terminateSentence(&sentence)
                return
            }
            next.appendTo(sentence: &sentence, sentenceStats: stats)
        }
        
        private func nextNode(stats: Array<Int>.SentenceStats, currentSentenceLength: Int) -> Node? {
            guard !nextWords.isEmpty else {
                return nil
            }
            
            var currentShouldBeLast = false
            if currentSentenceLength >= stats.maxLength {
                currentShouldBeLast = true
            }
            else if currentSentenceLength >= stats.minLength {
                let terminalNode = GenericWeightedNode(identifier: "terminal", incidence: terminatorIncidences.total)
                let continueNode = GenericWeightedNode(identifier: "continue", incidence: totalIncidence)
                let set = Set([terminalNode, continueNode])
                currentShouldBeLast = (set.weightedRandomNode() == terminalNode)
            }
            
            if currentShouldBeLast {
                return nil
            }
            
            return nextWords.weightedRandomNode()
        }
        
        private func terminateSentence(_ sentence: inout [String]) {
            if var lastWord = sentence.last {
                lastWord += terminatorIncidences.weightedRandomTerminator()
                sentence[sentence.count - 1] = lastWord
            }
        }
        
        private func updateTerminatorIncidences(forWord word: String) {
            terminatorIncidences.updateIfNecessaryWith(word: word)
        }
    }
}

extension ProbabilityGraph.Node: HashableWeightedNode, CustomStringConvertible {
    static func == (lhs: ProbabilityGraph.Node, rhs: ProbabilityGraph.Node) -> Bool {
        return lhs.word == rhs.word
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(word)
    }
    
    var description: String {
        return "(Word:\(word), Incidence: \(incidence), NextWords:\(nextWords.count))"
    }
}

private extension Array where Element==Int {
    struct SentenceStats {
        let minLength: Int
        let maxLength: Int
        let averageLength: Int
    }
    
    func stats() -> SentenceStats {
        let minimum = self.min() ?? 0
        let maximum = self.max() ?? 0
        return SentenceStats(minLength: minimum, maxLength: maximum, averageLength: average)
    }
}

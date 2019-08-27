//  ProbabilityTree.swift
//  Created by Jake Hawken on 8/4/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

public class ProbabilityTree: FakeMarkovChain {
    private let rootNode = Node(word: "", parent: nil)
    private var terminatorIncidences = TerminatorIncidences()
    
    func add(wordSequence words: [String]) {
        var currentNode = rootNode
        for word in words {
            currentNode = currentNode.insert(newWord: word)
            terminatorIncidences.updateIfNecessaryWith(word: word)
        }
    }
    
    func reset() {
        rootNode.reset()
        terminatorIncidences = TerminatorIncidences()
    }
    
    func generateSentence() -> String {
        var words = [String]()
        rootNode.appendTo(sentence: &words)
        guard !words.isEmpty else {
            return ""
        }
        
        if let firstWord = words.first {
            let capitalized = firstWord.capitalizingFirstLetter()
            words[0] = capitalized
        }
        var last = words.removeLast()
        if !last.isTerminalWord {
            last += terminatorIncidences.weightedRandomTerminator()
        }
        words.append(last)
        let output = words.joined(separator: " ")
        mainthreadPrint("\(Stories.Lovecraft.callOfCthulhu.contains(output))")
        return output
    }
}

extension ProbabilityTree {
    class Node: WeightedNode {
        let word: String
        let parent: Node?
        private(set) var incidence: UInt = 1
        private(set) var children = Set<Node>()
        
        init(word: String, parent: Node?) {
            self.word = word
            self.parent = parent
        }
        
        func reset() {
            incidence = 1
            children.forEach { $0.reset() }
            children.removeAll()
        }
        
        func insert(newWord word: String) -> Node {
            var newWord = word
            if newWord.isTerminalWord || !newWord.hasSentenceTerminator {
                newWord = newWord.lowercased()
            }
            incidence += 1
            if let existing = existingChild(forWord: newWord) {
                return existing
            }
            let new = newChild(forWord: newWord)
            children.insert(new)
            return new
        }
        
        func appendTo(sentence words: inout [String]) {
            guard let next = nextNode() else {
                return
            }
            words.append(next.word)
            if next.word.isTerminalWord {
                return
            }
            next.appendTo(sentence: &words)
        }
        
        private func nextNode() -> Node? {
            guard !word.isTerminalWord else {
                return nil
            }
            return children.weightedRandomNode()
        }
        
        private var root: Node {
            return parent ?? self
        }
        
        private func existingChild(forWord word: String) -> Node? {
            return children.first { $0.word == word }
        }
        
        private func newChild(forWord word: String) -> Node {
            return Node(word: word, parent: self)
        }
    }
}

extension ProbabilityTree.Node: HashableWeightedNode, CustomStringConvertible {
    static func == (lhs: ProbabilityTree.Node, rhs: ProbabilityTree.Node) -> Bool {
        return lhs.word == rhs.word
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(word)
    }
    
    var description: String {
        return "<NODE: {Word: \(word), Incidence: \(incidence), Chidren: \(children.count)} >"
    }
}

private extension Set where Element == ProbabilityTree.Node {
    func contains(word: String) -> Bool {
        return map { $0.word }.contains(word)
    }
}

//MARK: - debug

extension ProbabilityTree {
    func logState() {
        let dict = rootNode.dictionary()
        PrettyMaker.prettyPrintToConsole(dict)
    }
    
    func logTopTiers() {
        var string = "ROOT - \(rootNode.incidence)"
        var nextGen = rootNode.children.map { $0 }
        while nextGen.count > 0 {
            let nextGenStrings = nextGen.map { "(\($0.word): \($0.incidence))" }
            string += "\n-------------\n"
            string += nextGenStrings.joined(separator: "  ")
            nextGen = nextGen.reduce([Node](), { $0 + $1.children })
        }
        print(string)
    }
}

private extension ProbabilityTree.Node {
    func dictionary() -> [String: Any] {
        var childDict = [String: Any]()
        children.forEach {
            childDict[$0.word] = $0.dictionary()
        }
        return [word: childDict]
    }
}

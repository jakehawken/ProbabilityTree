//  ProbabilityTree.swift
//  Created by Jake Hawken on 8/4/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

public class ProbabilityTree {
    private let rootNode = Node(word: "", parent: nil)
    private var incidenceOfPeriod: UInt = 0
    private var incidenceOfQuestionMark: UInt = 0
    private var incidenceOfExclamation: UInt = 0
    
    func add(wordSequence words: [String]) {
        var currentNode = rootNode
        for word in words {
            currentNode = currentNode.insert(newWord: word)
            if currentNode.word.isTerminalWord {
                if let terminator = word.sentenceTerminator {
                    if terminator == "." {
                        incidenceOfPeriod += 1
                    }
                    else if terminator == "?" {
                        incidenceOfQuestionMark += 1
                    }
                    else if terminator == "!" {
                        incidenceOfExclamation += 1
                    }
                }
                currentNode = rootNode
            }
        }
    }
    
    func reset() {
        rootNode.reset()
        incidenceOfPeriod = 0
        incidenceOfQuestionMark = 0
        incidenceOfExclamation = 0
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
            last += sentenceTerminator()
        }
        words.append(last)
        let output = words.joined(separator: " ")
        mainthreadPrint("\(Stories.Lovecraft.callOfCthulhu.contains(output))")
        return output
    }
    
    private func sentenceTerminator() -> String {
        let totalIncidence = Float(incidenceOfPeriod + incidenceOfQuestionMark + incidenceOfExclamation)
        var likelihoodMapping: [(terminator: String, likelihood: Float)] = [
            (".", Float(incidenceOfPeriod)/totalIncidence),
            ("?", Float(incidenceOfQuestionMark)/totalIncidence),
            ("!", Float(incidenceOfExclamation)/totalIncidence)
        ]
        likelihoodMapping.sort { $0.likelihood < $1.likelihood }
        let random = Float.random(in: 0..<likelihoodMapping.last!.likelihood)
        if let terminator = likelihoodMapping.first(where: { random < $0.likelihood })?.terminator {
            return terminator
        }
        return "."
    }
}

extension ProbabilityTree {
    class Node {
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
            guard !children.isEmpty else {
                return nil
            }
            if children.count == 1, let only = children.first {
                return only
            }
            
            let sortedByIncidence = children.sorted { $0.incidence < $1.incidence }
            guard let maximumIncidence = sortedByIncidence.last?.incidence else {
                return nil
            }
            
            let totalIncidence = children.reduce(Float(0)) { $0 + Float($1.incidence) }
            let maxLikelihood = Float(maximumIncidence) / totalIncidence
            
            let randomValue = Float.random(in: 0...maxLikelihood)
            
            var likelihood: Float = 0
            let nodeForRandomValue: Node? = sortedByIncidence.first { (node) -> Bool in
                let overallLikelihood = Float(node.incidence) / totalIncidence
                likelihood += overallLikelihood
//                logLikelihoodState(overall: overallLikelihood, cumulative: likelihood)
                return randomValue <= likelihood
            }
            
            if let nextNode = nodeForRandomValue {
//                logSelectedWordState(totalIncidence: totalIncidence,
//                                     maximumIncidence: maximumIncidence,
//                                     maxLikelihood: maxLikelihood,
//                                     randomValue: randomValue,
//                                     likelihood: likelihood)
                return nextNode
            }
            return sortedByIncidence.last
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

extension ProbabilityTree.Node: Hashable, CustomStringConvertible {
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

private extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    var sentenceTerminator: String? {
        if hasSuffix("?") || hasSuffix("? ") || hasSuffix("?  ") {
            return "?"
        }
        else if hasSuffix(".") || hasSuffix(". ") || hasSuffix(".  ") {
            return "."
        }
        else if hasSuffix("!") || hasSuffix("! ") || hasSuffix("!  ") {
            return "!"
        }
        else {
            return nil
        }
    }
    
    var hasSentenceTerminator: Bool {
        return sentenceTerminator != nil
    }
    
    var isTerminalWord: Bool {
        let terminator = sentenceTerminator
        let isTerminated = terminator != nil
        var isAnInitial = false
        if let term = terminator, let first = components(separatedBy: term).first {
            isAnInitial = first.count == 1
        }
        return isTerminated && !isAnInitial
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
    
    func logLikelihoodState(overall: Float, cumulative: Float) {
        mainthreadPrint("""
            Overall Likelihood:    \(overall),
            Cumulative likelihood: \(cumulative)
            """)
    }
    
    func logSelectedWordState(totalIncidence: Float, maximumIncidence: UInt, maxLikelihood: Float, randomValue: Float, likelihood: Float) {
        mainthreadPrint("""
            TOTAL: \(totalIncidence)
            MAX INCIDENCE: \(maximumIncidence)
            MAX LIKELIHOOD: \(maxLikelihood)
            RANDOM: \(randomValue)
            Winning Likelihood: \(likelihood)
            """)
    }
}

private func mainthreadPrint(_ message: String) {
    DispatchQueue.main.sync {
        print(message)
    }
}

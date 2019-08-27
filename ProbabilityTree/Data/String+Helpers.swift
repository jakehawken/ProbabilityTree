//  String+Helpers.swift
//  Created by Jake Hawken on 8/14/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

internal extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func chomped() -> String {
        return self.removingLastCharactersWhere(shouldRemoveLast: { $0.hasSuffix(" ") })
    }
}

internal extension String {
    enum SentenceTerminator: String {
        case period = "."
        case question = "?"
        case exclamation = "!"
    }
    
    var sentenceTerminator: SentenceTerminator? {
        let chomped = self.chomped()
        if chomped.hasSuffix(".") {
            return .period
        }
        else if chomped.hasSuffix("?") {
            return .question
        }
        else if chomped.hasSuffix("!") {
            return .exclamation
        }
        else {
            return nil
        }
    }
    
    var hasSentenceTerminator: Bool {
        return sentenceTerminator != nil
    }
    
    func ifHasTerminator(_ doBlock: (SentenceTerminator)->()) {
        guard let terminator = sentenceTerminator else {
            return
        }
        doBlock(terminator)
    }
    
    var isTerminalWord: Bool {
        let terminator = sentenceTerminator
        let isTerminated = terminator != nil
        var isAnInitial = false
        if let term = terminator, let first = components(separatedBy: term.rawValue).first {
            isAnInitial = first.count == 1
        }
        return isTerminated && !isAnInitial
    }
    
    func strippedOfTrailingSpacesAndTerminators() -> String {
        return self.chomped().strippingTerminators()
    }
    
    func strippingTerminators() -> String {
        return self.removingLastCharactersWhere { $0.hasSentenceTerminator }
    }
    
    func removingLastCharactersWhere(shouldRemoveLast:(String)->Bool) -> String {
        var output = self
        while shouldRemoveLast(output) {
            _ = output.removeLast()
        }
        return output
    }
}

class TerminatorIncidences {
    private(set) var period: UInt = 0
    private(set) var question: UInt = 0
    private(set) var exclamation: UInt = 0
    
    var total: UInt {
        return period + question + exclamation
    }
    
    func weightedRandomTerminator() -> String {
        if total == 0 {
            return periodString
        }
        let periodIncidence = GenericWeightedNode(identifier: periodString, incidence: period)
        let questionIncidence = GenericWeightedNode(identifier: questionString, incidence: question)
        let exclamationIncidence = GenericWeightedNode(identifier: exclamationString, incidence: exclamation)
        let incidences = Set<GenericWeightedNode>([periodIncidence, questionIncidence, exclamationIncidence])
        return incidences.weightedRandomNode()?.identifier ?? periodString
    }
    
    func updateIfNecessaryWith(word: String) {
        word.ifHasTerminator { (terminator) in
            switch terminator {
            case .period:
                period += 1
            case .question:
                question += 1
            case .exclamation:
                exclamation += 1
            }
        }
    }
    
    private var periodString: String {
        return "."
    }
    
    private var questionString: String {
        return "?"
    }
    
    private var exclamationString: String {
        return "!"
    }
}

//
//  FakeMarkovChain.swift
//  ProbabilityTree
//
//  Created by Jake Hawken on 8/8/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.
//

import Foundation

protocol FakeMarkovChain {
    func add(wordSequence words: [String])
    func generateSentence() -> String
    func reset()
}

//  Probability.swift
//  Created by Jake Hawken on 8/13/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

internal protocol WeightedNode: CustomStringConvertible {
    var incidence: UInt { get }
}

internal protocol HashableWeightedNode: WeightedNode, Hashable {}

internal struct GenericWeightedNode: HashableWeightedNode {
    public let identifier: String
    public let incidence: UInt
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    public var description: String {
        return "{WeightedNode| identifier: \"\(identifier)\", incidence: \(incidence)}"
    }
}

extension Set where Element:HashableWeightedNode {
    enum SortOrder {
        case ascending
        case descending
    }
    
    struct ProbabilityMetadata: CustomStringConvertible {
        let sortedNodes: [Element]
        let totalIncidence: Float
        let maxLikelihood: Float
        let maxIncidence: Float
        let minIncidence: Float
        let minLikelihood: Float
        
        fileprivate init(nodes: Set<Element>) {
            let totalIncidence = nodes.reduce(into: Float(0), { $0 += Float($1.incidence) })
            self.totalIncidence = totalIncidence
            
            let sortedNodes = nodes.sortedByIncidence(order: .ascending)
            self.sortedNodes = sortedNodes
            
            let min = Float(sortedNodes.first?.incidence ?? 0)
            self.minIncidence = min
            self.minLikelihood = min / totalIncidence
            
            let max = Float(sortedNodes.last?.incidence ?? 0)
            self.maxIncidence = max
            self.maxLikelihood = max / totalIncidence
        }
        
        var description: String {
            let sortedIncidences = sortedNodes.prefix(10).map { $0.incidence }
            var incidencesString = "\(sortedIncidences)"
            if sortedNodes.count > 10 {
                incidencesString.removeLast()
                incidencesString += ", ...]"
            }
            return """
            {METADATA:
            TOTAL: \(UInt(totalIncidence))
            MAX INCIDENCE: \(UInt(maxIncidence))
            MAX LIKELIHOOD: \(maxLikelihood)
            MIN INCIDENCE: \(UInt(minIncidence))
            MIN LIKELIHOOD: \((minLikelihood as NSNumber).decimalValue)
            NUMBER OF NODES: \(sortedNodes.count)
            SORTED INCIDENCES: \(incidencesString)
            }
            """
        }
        
        func randomNode(withIncidence incidence: UInt) -> Element? {
            let filtered = sortedNodes.filter { $0.incidence == incidence }
            return filtered.randomElement()
        }
    }
    
    func probabilityMetadata() -> ProbabilityMetadata {
        return ProbabilityMetadata(nodes: self)
    }
    
    func sortedByIncidence(order: SortOrder) -> [Element] {
        return sorted {
            switch order {
            case .ascending:
                return $0.incidence < $1.incidence
            case .descending:
                return $0.incidence > $1.incidence
            }
        }
    }
    
    func weightedRandomNode(loggingEnabled: Bool = false) -> Element? {
        guard !isEmpty else {
            return nil
        }
        if count == 1, let first = first {
            return first
        }
        let metadata = probabilityMetadata()
        let logger = loggingEnabled ? ProbabilityLogger() : nil
        
        let randomLikelihood = Float.random(in: 0...metadata.maxLikelihood)
        
        
        
        var likelihood: Float = 0
        let nodeForRandomValue: Element? = metadata.sortedNodes.first { (node) -> Bool in
            let overallLikelihood = Float(node.incidence) / metadata.totalIncidence
            likelihood += overallLikelihood
            logger?.logLikelihoodState(overall: overallLikelihood,
                                       cumulative: likelihood,
                                       random: randomLikelihood)
            return randomLikelihood <= likelihood
        }
        
        if let winningNode = nodeForRandomValue {
            logger?.logSelectedWordState(metadataBlob: metadata.description,
                                         randomValue: randomLikelihood,
                                         winningLikelihood: likelihood,
                                         winningNode: winningNode)
            return winningNode
        }
        
        let defaultNode = metadata.sortedNodes.last
        logger?.logDefaultToLastNode(node: defaultNode)
        return defaultNode
    }
}

extension Array where Element==Int {
    var average: Int {
        return reduce(into: 0, +=) / count
    }
}

internal func mainthreadPrint(_ message: String) {
    if OperationQueue.current?.underlyingQueue == DispatchQueue.main {
        print(message)
    }
    else {
        DispatchQueue.main.sync {
            print(message)
        }
    }
}

private class ProbabilityLogger {
    
    public init() {}
    
    public func log(message: String) {
        mainthreadPrint(message)
    }
    
    public func logLikelihoodState(overall: Float, cumulative: Float, random: Float) {
        let overallNum = overall as NSNumber
        let cumulativeNum = cumulative as NSNumber
        mainthreadPrint("""
            Random requirement:  \(random)
            Overall likelihood:        \(overallNum.decimalValue)
            Cumulative likelihood: \(cumulativeNum.decimalValue)
            """)
    }
    
    public func logSelectedWordState(metadataBlob: String, randomValue: Float, winningLikelihood: Float, winningNode: WeightedNode) {
        let winningLikelihoodNumber = winningLikelihood as NSNumber
        mainthreadPrint("""
            |---------------------------->
            \(metadataBlob)
            RANDOM: \(randomValue)
            Winning Likelihood: \(winningLikelihoodNumber.decimalValue)
            Winning Node: \(winningNode.description)
            <----------------------------|
            """)
    }
    
    public func logDefaultToLastNode(node: WeightedNode?) {
        mainthreadPrint("Defaulting to last node: \(node?.description ?? "nil")")
    }
}

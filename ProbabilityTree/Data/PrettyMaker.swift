//  PrettyMaker.swift
//  Created by Jake Hawken on 8/6/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import Foundation

internal class PrettyMaker {
    class func prettyPrintToConsole(_ thing: Any) {
        let string = makePrettyIfPossible(thing)
        print(string)
    }
    
    class func makePrettyIfPossible(_ thing: Any) -> String {
        var prettyString: String
        
        if let arrayOfAny = thing as? [Any] {
            prettyString = arrayOfAny.prettyPrinted()
        }
        else if let encodableThing = thing as? Encodable {
            let asDictionary = encodableThing.asDictionary(forPrettyPrinting: true)
            prettyString = asDictionary?.prettyPrinted() ?? tryToMakeMysteriousThingPretty(thing)
        }
        else if let prettyPrintable = thing as? PrettyPrintable {
            prettyString = prettyPrintable.prettyPrinted()
        }
        else {
            prettyString = tryToMakeMysteriousThingPretty(thing)
        }
        
        return prettyString
    }
    
    fileprivate class func tryToMakeMysteriousThingPretty(_ thing: Any?) -> String {
        guard let thing = thing else {
            return "nil"
        }
        var valueString = "\(thing)"
        
        let components = valueString.components(separatedBy: "\n")
        if components.count == 1 {
            valueString = valueString.truncateIfNeeded(maxLength: Constants.maxLength, trailing: "...")
        }
        else {
            let truncatedComponents = components.map {
                $0.truncateIfNeeded(maxLength: Constants.maxLength, trailing: "...")
            }
            valueString = truncatedComponents.joined(separator: "\n")
        }
        
        return valueString.replacingOccurrences(of: " = ", with: " : ")
    }
}

internal protocol PrettyPrintable {
    func prettyPrinted() -> String
    func prettyPrintToConsole()
}

extension PrettyPrintable {
    func prettyPrintToConsole() {
        let pretty = prettyPrinted()
        print("\n\(pretty)\n")
    }
}

extension String: PrettyPrintable {
    func prettyPrinted() -> String {
        let truncated = self.truncateIfNeeded(maxLength: Constants.maxLength, trailing: "...")
        return "\"\(truncated)\""
    }
}

extension Array: PrettyPrintable {
    func prettyPrinted() -> String {
        var outputString = "["
        
        forEach {
            outputString += "\n"
            if let encodable = $0 as? Encodable {
                let asDictionary = encodable.asDictionary(forPrettyPrinting: true)
                outputString += asDictionary?.prettyPrinted() ?? PrettyMaker.tryToMakeMysteriousThingPretty($0)
            }
            else if let prettyPrintable = $0 as? PrettyPrintable {
                outputString += prettyPrintable.prettyPrinted()
            }
            else if let dict = $0 as? [String: Any] {
                outputString += dict.prettyPrinted()
            }
            else {
                outputString += PrettyMaker.tryToMakeMysteriousThingPretty($0)
            }
            outputString += ","
        }
        outputString -= ","
        outputString = outputString.replacingOccurrences(of: "\n", with: "\n  ")
        outputString += "\n]"
        return outputString
    }
}

extension Dictionary: PrettyPrintable where Key==String {
    func prettyPrinted() -> String {
        var outputString = "{"
        
        for key in keys {
            let value = self[key]
            
            var valueString: String
            if let prettyPrintable = value as? PrettyPrintable {
                valueString = prettyPrintable.prettyPrinted()
            }
            else if let arrayValue = value as? [Any] {
                valueString = arrayValue.prettyPrinted()
            }
            else if let stringVal = value as? String {
                valueString = stringVal.prettyPrinted()
            }
            else {
                valueString = PrettyMaker.tryToMakeMysteriousThingPretty(value)
            }
            outputString += "\n\"\(key)\" : \(valueString),"
        }
        outputString -= ","
        
        // This ensures that the correct indentation is added at all recursive levels.
        outputString = outputString.replacingOccurrences(of: "\n", with: "\n  ")
            .replacingOccurrences(of: " = ", with: " : ")
        
        outputString += "\n}"
        return outputString
    }
}

fileprivate extension Encodable {
    func asDictionary(forPrettyPrinting: Bool = false) -> [String: Any]? {
        let jsonEncoder = JSONEncoder()
        if forPrettyPrinting {
            jsonEncoder.outputFormatting = .prettyPrinted
        }
        guard let data = try? jsonEncoder.encode(self) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        
        return json as? [String: Any]
    }
}

private enum Constants {
    internal static let maxLength = 80
}

extension String {
    static func -=(lhs: inout String, rhs: String) {
        guard lhs.hasSuffix(rhs) else {
            return
        }
        guard let range = lhs.range(of: rhs, options: [.backwards], range: nil, locale: nil) else {
            return
        }
        lhs = lhs.replacingCharacters(in: range, with: "")
    }
    
    func truncateIfNeeded(maxLength: Int, trailing: String = "") -> String {
        if self.count > maxLength {
            return truncate(maxLength: maxLength)! + trailing
        } else {
            return self
        }
    }
    
    func truncate(maxLength: Int, encoding: String.Encoding? = nil) -> String? {
        guard maxLength >= 0 else { return nil }
        
        let encoding = encoding ?? self.smallestEncoding
        var bytes = [UInt8](repeating: 0, count: maxLength)
        var remaining = self.startIndex..<self.endIndex
        var usedLength = 0
        _ = self.getBytes(&bytes, maxLength: maxLength, usedLength: &usedLength, encoding: encoding, options: .externalRepresentation, range: self.startIndex..<self.endIndex, remaining: &remaining)
        
        return String(bytes: bytes, encoding: encoding)
    }
}

//
//  File.swift
//  
//
//  Created by ws on 2022/9/14.
//

import Foundation

public struct Obfuscate {

    static func obfuscate(sourcekitd: SourceKitD, response: SKDResponseDictionary) -> ([SyntaxReference], [String: String]) {
        var referenceArray = [SyntaxReference]()
        var obfuscationDictionary = [String: String]()
        
        response.recurse { dict in
            let kindId: SourceKitdUID  = dict[sourceKit.keys.kind]!
            guard kindId.referenceType() != nil || kindId.declarationType() != nil,
                  let rawName: String = dict[sourceKit.keys.name],
                  let usr: String = dict[sourceKit.keys.usr],
                  let line: Int = dict[sourceKit.keys.line],
                  let column: Int = dict[sourceKit.keys.column] else {
                return
            }

            let name = rawName.components(separatedBy: "(").first ?? rawName
            let size = 32
            let letters: [Character] = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
            let numbers: [Character] = Array("0123456789")
            let lettersAndNumbers = letters + numbers
            var obfuscatedName = ""
            for i in 0 ..< size {
                let characters: [Character] = i == 0 ? letters : lettersAndNumbers
                let rand = Int.random(in: 0 ..< characters.count)
                let nextChar = characters[rand]
                obfuscatedName.append(nextChar)
            }
            print("\(name) (USR: \(usr) at (\(line):\(column)) -> now \(obfuscatedName)")
            obfuscationDictionary[name] = obfuscatedName
            let reference = SyntaxReference(name: name, line: line, column: column)
            referenceArray.append(reference)
        }
        return (referenceArray, obfuscationDictionary)
    }
    
    public static func obfuscate(sourcekitd: SourceKitD, response: SKDResponseDictionary, fileContents: String) -> String {
        let results = obfuscate(sourcekitd: sourcekitd, response: response)
        let obfuscationDictionary = results.1
        let references = results.0
        let sortedReferences = references.sorted(by: <)

        var previousReference: SyntaxReference!
        var currentReferenceIndex = 0
        var line = 1
        var column = 1
        var currentCharIndex = 0

        var charArray: [String] = Array(fileContents).map(String.init)

        while currentCharIndex < charArray.count, currentReferenceIndex < sortedReferences.count {
            let reference = sortedReferences[currentReferenceIndex]
            if previousReference != nil,
                reference.line == previousReference.line,
                reference.column == previousReference.column {
                // Avoid duplicates.
                currentReferenceIndex += 1
            }
            let currentCharacter = charArray[currentCharIndex]
            if line == reference.line, column == reference.column {
                previousReference = reference
                let originalName = reference.name
                guard let obfuscatedName: String = obfuscationDictionary[originalName] else {
                    continue
                }
                let wasInternalKeyword = currentCharacter == "`"
                for i in 1 ..< (originalName.count + (wasInternalKeyword ? 2 : 0)) {
                    charArray[currentCharIndex + i] = ""
                }
                charArray[currentCharIndex] = obfuscatedName
                currentReferenceIndex += 1
                currentCharIndex += originalName.count
                column += originalName.utf8.count
                if wasInternalKeyword {
                    charArray[currentCharIndex] = ""
                }
            } else if currentCharacter == "\n" {
                line += 1
                column = 1
                currentCharIndex += 1
            } else {
                column += currentCharacter.utf8.count
                currentCharIndex += 1
            }
        }
        return charArray.joined()
    }

}




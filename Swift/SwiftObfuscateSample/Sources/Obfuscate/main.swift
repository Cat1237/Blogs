//
//  File.swift
//  
//
//  Created by ws on 2022/9/6.
//

import Foundation


let sourceKit = try load()
let keys = sourceKit.keys

let request = SKDRequestDictionary(sourcekitd: sourceKit)
let file = "/Users/ws/Desktop/SwiftObfuscateSample/Tests/Resources/foo.swift"
request[keys.request] = sourceKit.requests.index_source
request[keys.sourcefile] = file
request[keys.compilerargs] = ["-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk", file]

print(request)
let response = try sourceKit.sendSync(request)
print(response)

let file_content = try String(contentsOfFile: file, encoding: .utf8)
let new_content = Obfuscate.obfuscate(sourcekitd: sourceKit, response: response, fileContents: file_content)
print(new_content)


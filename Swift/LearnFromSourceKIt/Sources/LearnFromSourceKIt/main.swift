//
//  File.swift
//  
//
//  Created by ws on 2022/9/6.
//

import Foundation
import TSCBasic

print(searchPaths)
private func envBool(_ name: String) -> Bool {
    guard let value = ProcessInfo.processInfo.environment[name] else {
        return false
    }

    return ["1", "YES", "TRUE"].contains(value.uppercased())
}

#if SWIFT_PACKAGE
import SourceKit
#endif
#if os(Linux)
private let path = "libsourcekitdInProc.so"
#else
private let path: String = {
    if envBool("IN_PROCESS_SOURCEKIT") {
        return "sourcekitdInProc.framework/Versions/A/sourcekitdInProc"
    } else {
        return "sourcekitd.framework/Versions/A/sourcekitd"
    }
}()
#endif

func load(_ path: String) throws -> SourceKitD {
    let fullPaths = searchPaths.map { $0.appending(pathComponent: path) }.filter { $0.isFile }
    // try all fullPaths that contains target file,
    // then try loading with simple path that depends resolving to DYLD
    for fullPath in fullPaths + [path] {
         return try SourceKitDImpl.getOrCreate(dylibPath: AbsolutePath(fullPath))
    }
    fatalError("Loading \(path) failed")
}

let sourceKit = try load(path)
let keys = sourceKit.keys
let sourceKitRequests = sourceKit.requests

let request = SKDRequestDictionary(sourcekitd: sourceKit)
request[keys.request] = sourceKitRequests.editor_open
request[keys.name] = "Cat"
request[keys.compilerargs] = ["-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.3.sdk"]
//    req[keys.sourcefile] = file
request[keys.sourcetext] = "struct A { subscript(index: Int) -> () { return () } }"

print(request)
let response = try sourceKit.sendSync(request)
print(response)




//===------------------------ SourceKitdUID.swift -------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// This file provides SourceKitd UIDs.
//===----------------------------------------------------------------------===//

import Csourcekitd
#if canImport(Glibc)
import Glibc
#endif

extension SourceKitDImpl {
    enum DeclarationType {
        case object
        case `protocol`
        case property
        case method
        case `enum`
        case enumelement
    }
}

public struct SourceKitdUID: CustomStringConvertible {

    
    public let uid: sourcekitd_uid_t
    let sourcekitd: SourceKitD

    init(uid: sourcekitd_uid_t, sourcekitd: SourceKitD) {
        self.uid = uid
        self.sourcekitd = sourcekitd
    }
    
    public var description: String {
        return String(cString: sourcekitd.api.uid_get_string_ptr(uid)!)
    }
    
    public var asString: String {
        return String(cString: sourcekitd.api.uid_get_string_ptr(uid)!)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    func referenceType() -> SourceKitDImpl.DeclarationType? {
        declarationType(firstSuffix: ".ref.")
    }
    
    func declarationType() -> SourceKitDImpl.DeclarationType? {
        declarationType(firstSuffix: ".decl.")
    }
    
    func declarationType(firstSuffix: String) -> SourceKitDImpl.DeclarationType? {
        let kind = description
        let prefix = "source.lang.swift" + firstSuffix
        guard kind.hasPrefix(prefix) else {
            return nil
        }
        let prefixIndex = kind.index(kind.startIndex, offsetBy: prefix.count)
        let kindSuffix = String(kind[prefixIndex...])
        switch kindSuffix {
        case "class",
            "struct":
            return .object
        case "protocol":
            return .protocol
        case "var.instance",
            "var.static",
            "var.global",
            "var.class":
            return .property
        case "function.free",
            "function.method.instance",
            "function.method.static",
            "function.method.class":
            return .method
        case "enum":
            return .enum
        case "enumelement":
            return .enumelement
        default:
            return nil
        }
    }
}

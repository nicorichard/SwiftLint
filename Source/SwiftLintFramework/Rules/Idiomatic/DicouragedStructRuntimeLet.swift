import Foundation
import SourceKittenFramework

public struct DicouragedStructRuntimeLet: OptInRule, AutomaticTestableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)
    
    public init() {}
    
    public static let description = RuleDescription(
        identifier: "discouraged_struct_runtime_let",
        name: "Disouraged Struct Runtime Let Assignment",
        description: "Struct `let` property values should be known at compile time, and constant for all copies.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            struct Foo {
                let bar: Int = 5
            }
            """),
            Example("""
            struct Foo {
                var bar: Int
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct Foo {
                ↓let baz: Int
            }
            """)
        ]
    )
    
    private func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary,
                          parentDictionary: SourceKittenDictionary?) -> [StyleViolation] {
        guard
            kind == .varInstance,
            parentDictionary?.kind == SwiftDeclarationKind.struct.rawValue,
            dictionary.setterAccessibility == nil,
            dictionary.bodyLength == nil,
            let offset = dictionary.offset,
            let byteRange = dictionary.byteRange,
            file.stringView.substringWithByteRange(byteRange)?.contains("=") ?? true
        else {
            return []
        }
        
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
    
    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.structureDictionary.traverseWithParentDepthFirst { parent, subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict, parentDictionary: parent)
        }
    }
}

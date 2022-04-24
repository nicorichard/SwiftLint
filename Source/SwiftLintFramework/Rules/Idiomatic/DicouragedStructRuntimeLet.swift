import Foundation
import SourceKittenFramework

public struct DicouragedStructRuntimeLet: OptInRule, SubstitutionCorrectableRule, AutomaticTestableRule, ConfigurationProviderRule {
    
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
            Example("""
            class Foo {
                let bar: Int
            }
            """),
            Example("""
            struct Foo {
                private(set) var bar: Int
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct Foo {
                ↓let bar: Int
            }
            """)
        ],
        corrections: [
            Example("""
            struct Foo {
                ↓let bar: Int
            }
            """): Example("""
            struct Foo {
                var bar: Int
            }
            """)
        ]
    )
    
    private static let letString = "let"
    private static let varString = "var"
    private static let assignmentOperatorString = "="
    
    private func violationRanges(file: SwiftLintFile, kind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary,
                          parentDictionary: SourceKittenDictionary?) -> [NSRange] {
        guard
            kind == .varInstance,
            parentDictionary?.kind == SwiftDeclarationKind.struct.rawValue,
            dictionary.setterAccessibility == nil,
            dictionary.bodyLength == nil,
            let byteRange = dictionary.byteRange,
            let substring = file.stringView.substringWithByteRange(byteRange) as? NSString,
            !substring.contains(Self.assignmentOperatorString),
            let range = file.stringView.byteRangeToNSRange(byteRange)
        else {
            return []
        }
        
        let letRange = substring.range(of: Self.letString)
        guard letRange.length == Self.letString.count else {
            return []
        }
        
        return [
            NSRange(location: range.lowerBound + letRange.lowerBound, length: letRange.length)
        ]
    }
    
    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
    
    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file.structureDictionary.traverseWithParentDepthFirst { parent, subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return violationRanges(file: file, kind: kind, dictionary: subDict, parentDictionary: parent)
        }
    }
    
    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, Self.varString)
    }
}

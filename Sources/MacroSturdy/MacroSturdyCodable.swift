//
//  MacroSturdyCodable.swift
//  SwiftUI-Sturdy
//
//  Created by OmAr Kader on 12/06/2026.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct FilterCodableMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // 1. Guard: Ensure it's attached to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let diagnostic = Diagnostic(node: node, message: MacroDiagnostic.notAStruct)
            context.diagnose(diagnostic)
            return []
        }
        
        // 2. Guard: Ensure the struct explicitly conforms to Codable (or Decodable/Encodable)
        let hasCodableConformance = structDecl.inheritanceClause?.inheritedTypes.contains { inheritedType in
            let typeName = inheritedType.type.trimmedDescription
            return typeName == "Codable" || typeName == "Decodable" || typeName == "Encodable"
        } ?? false
        
        if !hasCodableConformance {
            let diagnostic = Diagnostic(node: node, message: MacroDiagnostic.noCodable)
            context.diagnose(diagnostic)
            return []
        }
        
        // --- Beyond this point, the type is guaranteed to be a valid Codable struct ---
        
        var regularFields: [(name: String, type: String)] = []
        var ignoredFieldBlocks: [String] = []
        
        var userHasCodingKeys = false
        var userHasInitFromDecoder = false
        var userHasEncodeToEncoder = false
        
        // 3. Scan members to read properties AND detect existing manual implementations
        for member in structDecl.memberBlock.members {
            
            // Look for existing 'enum CodingKeys'
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "CodingKeys" {
                userHasCodingKeys = true
                continue
            }
            
            // Look for existing 'init(from:)'
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                let parameters = initDecl.signature.parameterClause.parameters
                if let firstParam = parameters.first, firstParam.firstName.text == "from" {
                    userHasInitFromDecoder = true
                }
                continue
            }
            
            // Look for existing 'func encode(to:)'
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
               funcDecl.name.text == "encode" {
                let parameters = funcDecl.signature.parameterClause.parameters
                if let firstParam = parameters.first, firstParam.firstName.text == "to" {
                    userHasEncodeToEncoder = true
                }
                continue
            }
            
            // Parse properties for our generation logic
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  let binding = variable.bindings.first,
                  let fieldName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
            
            let ignoreAttr = variable.attributes.first(where: { attr in
                attr.as(AttributeSyntax.self)?
                    .attributeName.as(IdentifierTypeSyntax.self)?
                    .name.text == "CodableIgnore"
            })?.as(AttributeSyntax.self)
            
            if let ignoreAttr = ignoreAttr {
                if let argument = ignoreAttr.arguments?.as(LabeledExprListSyntax.self)?.first?.expression {
                    if let closure = argument.as(ClosureExprSyntax.self) {
                        let statements = closure.statements.map { $0.trimmedDescription }.joined(separator: "\n        ")
                        ignoredFieldBlocks.append(statements)
                    } else {
                        ignoredFieldBlocks.append("self.\(fieldName) = \(argument.trimmedDescription)")
                    }
                }
            } else {
                if let fieldType = binding.typeAnnotation?.type.trimmedDescription {
                    regularFields.append((name: fieldName, type: fieldType))
                }
            }
        }
        
        // 4. Conditionally generate members based on what was missing
        var generatedMembers: [DeclSyntax] = []
        
        if !userHasCodingKeys {
            let codingKeysCases = regularFields.map { "case \($0.name)" }.joined(separator: "\n    ")
            let codingKeysEnum = """
            enum CodingKeys: String, CodingKey {
                \(codingKeysCases)
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: codingKeysEnum))
        }
        
        if !userHasInitFromDecoder {
            let decodeStatements = regularFields.map {
                "self.\($0.name) = try container.decode(\($0.type).self, forKey: .\($0.name))"
            }.joined(separator: "\n        ")
            
            let customBlocks = ignoredFieldBlocks.joined(separator: "\n        ")
            
            let initializer = """
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(decodeStatements)
                \(customBlocks)
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: initializer))
        }
        
        if !userHasEncodeToEncoder {
            let encodeStatements = regularFields.map {
                "try container.encode(self.\($0.name), forKey: .\($0.name))"
            }.joined(separator: "\n        ")
            
            let encoderFunc = """
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                \(encodeStatements)
            }
            """
            generatedMembers.append(DeclSyntax(stringLiteral: encoderFunc))
        }
        
        return generatedMembers
    }
}


public struct CodableIgnoreMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro is just a marker attribute; it doesn't generate any code
        // The CopyableMacro checks for its presence and skips those properties
        return []
    }
}


// MARK: - Diagnostics
private enum MacroDiagnostic: String, DiagnosticMessage {
    case notAStruct
    case noCodable

    var message: String {
        switch self {
        case .notAStruct:
            return "@FilterCodable can only be applied to a struct"
        case .noCodable:
            return "@FilterCodable requires Codable"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "MacroSturdy", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct CopyableMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure the attribute is attached to a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: Syntax(attribute), message: MacroDiagnostic.notAStruct)
            )
            return []
        }

        // Collect stored properties from the struct (excluding @NoCopy properties)
        let properties = extractStoredProperties(from: structDecl)

        guard !properties.isEmpty else {
            context.diagnose(
                Diagnostic(node: Syntax(attribute), message: MacroDiagnostic.noStoredProperties)
            )
            return []
        }

        // Generate the copy function source and return as DeclSyntax
        let copyFunctionSource = generateCopyFunction(properties: properties)
        return [DeclSyntax(stringLiteral: copyFunctionSource)]
    }

    // MARK: - Property Extraction

    /// Returns (name, type) pairs for stored `var` properties that have a type annotation.
    /// Attempts to skip pure computed properties (has `get` but no willSet/didSet).
    /// Skips properties marked with @NoCopy.
    private static func extractStoredProperties(
        from structDecl: StructDeclSyntax
    ) -> [(name: String, type: String)] {
        var properties: [(name: String, type: String)] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // Check if the property has @NoCopy attribute
            if hasNoCopyAttribute(varDecl) {
                continue
            }

            // Only handle `var` bindings (skip `let`)
            if varDecl.bindingSpecifier.tokenKind != .keyword(.var) {
                continue
            }

            for binding in varDecl.bindings {
                // If there's an accessor block, only allow observer-only stored properties.
                if let accessorBlock = binding.accessorBlock {
                    // `var foo: T { ... }` is represented as `.getter` and is always computed.
                    if case .getter = accessorBlock.accessors {
                        continue
                    }

                    if case .accessors(let accessorList) = accessorBlock.accessors {
                        let isObserverOnly = accessorList.allSatisfy { accessor in
                            let kind = accessor.accessorSpecifier.tokenKind
                            return kind == .keyword(.willSet) || kind == .keyword(.didSet)
                        }

                        // Skip computed properties such as explicit get/set and read/modify variants.
                        if !isObserverOnly {
                            continue
                        }
                    } else {
                        // Future-proof fallback: unknown accessor forms are treated as computed.
                        continue
                    }
                }

                // Require an identifier and a type annotation (stored property)
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                let propertyName = pattern.identifier.text
                let rawType = typeAnnotation.type.description
                let propertyType = rawType.trimmingCharacters(in: .whitespacesAndNewlines)

                properties.append((name: propertyName, type: propertyType))
            }
        }

        return properties
    }

    /// Checks if a variable declaration has the @NoCopy attribute
    private static func hasNoCopyAttribute(_ varDecl: VariableDeclSyntax) -> Bool {
        // Check all attributes on the variable declaration
        for attribute in varDecl.attributes {
            // Handle AttributeSyntax (e.g., @NoCopy)
            if let attr = attribute.as(AttributeSyntax.self) {
                let attrName = attr.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if attrName == "NoCopy" {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Code Generation

    private static func generateCopyFunction(properties: [(name: String, type: String)]) -> String {
        // indentation helper: returns n * 4 spaces
        func indent(_ level: Int) -> String {
            String(repeating: "    ", count: max(0, level))
        }

        // parameter lines (one parameter per line), indent level 1 inside the parameter list
        let paramLines = properties.map { prop in
            "\(indent(1))\(prop.name): Update<\(prop.type)> = .keep"
        }
        let params = paramLines.joined(separator: ",\n")

        // body blocks: each property becomes a multiline `if` block,
        // top-level body lines are at indent level 1; inner assignment at level 2
        let bodyLines = properties.map { prop in
            """
            \(indent(1))if case .set(let value) = \(prop.name) {
            \(indent(2))self.\(prop.name) = value
            \(indent(1))}
            """
        }
        let body = bodyLines.joined(separator: "\n")

        // assemble whole function: ensure consistent indentation for params, body and return
        return """
        @MainActor
        mutating func copy(
        \(params)
        ) -> Self {
        \(body)
        \(indent(1))return self
        }
        """
    }
}

// MARK: - NoCopy Macro (Peer Macro - does nothing, just a marker)

public struct NoCopyMacro: PeerMacro {
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

enum MacroDiagnostic: String, DiagnosticMessage {
    case notAStruct
    case noStoredProperties

    var message: String {
        switch self {
        case .notAStruct:
            return "@SturdyCopy can only be applied to a struct"
        case .noStoredProperties:
            return "@SturdyCopy requires at least one stored property with a type annotation (properties marked with @NoCopy are excluded)"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "MacroSturdy", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Plugin registration

@main
struct MacroSturdyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyableMacro.self,
        NoCopyMacro.self
    ]
}

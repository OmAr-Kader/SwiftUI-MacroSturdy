//
//  LocalizationMacro.swift
//  SwiftUI-Sturdy
//
//  Created by OmAr Kader on 02/11/2026.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LocalizationMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        guard let argument = node.arguments.first?.expression else {
            throw LocalizationMacroError.missingArgument
        }

        return "String(localized: \(argument))"
    }
}

// MARK: - Errors

private enum LocalizationMacroError: Error, CustomStringConvertible {
    case missingArgument

    var description: String {
        switch self {
        case .missingArgument:
            return "#local requires a string argument."
        }
    }
}

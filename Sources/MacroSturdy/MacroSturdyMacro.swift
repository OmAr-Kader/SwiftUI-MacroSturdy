//
//  MacroSturdyMacro.swift
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

// MARK: - Plugin registration

@main
struct MacroSturdyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyableMacro.self,
        NoCopyMacro.self,
        FilterCodableMacro.self,
        CodableIgnoreMacro.self
    ]
}

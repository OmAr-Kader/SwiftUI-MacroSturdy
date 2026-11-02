//
//  MacroSturdy.swift
//  SwiftUISturdy
//
//  Created by OmAr Kader on 03/12/2025.
//

import Foundation

/// A macro that generates a `copy` function for structs with `Update<T>` parameters.
///
/// Apply `@Copyable` to a struct to auto-generate a mutating `copy` function
/// that allows selective property updates using the `Update<T>` enum.
///
/// ## Example
/// ```swift
/// @Copyable
/// struct HomeState {
///     private(set) var isLoading: Bool = false
///     private(set) var user: User? = nil
///
///     @NoCopy
///     var donot: Int = 0
/// }
/// ```
///
/// Generates:
/// ```swift
/// @MainActor
/// mutating func copy(
///     isLoading: Update<Bool> = .keep,
///     user: Update<User?> = .keep
/// ) -> Self {
///     if case .set(let value) = isLoading { self.isLoading = value }
///     if case .set(let value) = user { self.user = value }
///     return self
/// }
/// ```
@attached(member, names: named(copy))
public macro SturdyCopy() = #externalMacro(module: "MacroSturdy", type: "CopyableMacro")

/// Marks a property to be excluded from the generated `copy` function.
///
/// Apply this attribute to properties that should not be modifiable through the copy function.
@attached(peer)
public macro NoCopy() = #externalMacro(module: "MacroSturdy", type: "NoCopyMacro")

public enum Update<T> {
    case keep
    case set(T)
}


/// A macro that generates a localized string using the provided `String.LocalizationValue`.
///
/// Apply `#local("localizationKey")` to generate a localized string for the given key.
///
/// ## Example
/// ```swift
/// let greeting = #local("Hello, \(name)")
/// ```
///
/// NOTE: Make sure you enable `Use Compiler to Extract Swift Strings` in your project build settings.
@freestanding(expression)
public macro local(_ value: String.LocalizationValue) -> String =
    #externalMacro(
        module: "MacroSturdy",
        type: "LocalizationMacro"
    )

/// Same as `#local("localizationKey")` but with a shorter syntax using `#l("localizationKey")`.
///
/// ## Example
/// ```swift
/// let greeting = #l("Hello, \(name)")
/// ```
@freestanding(expression)
public macro l(_ value: String.LocalizationValue) -> String =
    #externalMacro(
        module: "MacroSturdy",
        type: "LocalizationMacro"
    )


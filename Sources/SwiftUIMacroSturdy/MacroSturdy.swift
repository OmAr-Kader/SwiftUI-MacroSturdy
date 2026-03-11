//
//  MacroSturdy.swift
//  SwiftUISturdy
//
//  Created by OmAr Kader on 03/12/2025.
//

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

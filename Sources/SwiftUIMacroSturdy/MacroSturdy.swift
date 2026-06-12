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


/// A macro that generates `CodingKeys`, `init(from:)`, and `encode(to:)` for structs, with optional property filtering.
///
/// Apply `@FilterCodable` to a struct to auto-generate the necessary conformance to `Codable`. By default, all properties are included in the generated code. However, you
/// can use the `@CodableIgnore` macro to specify properties that should be excluded from the generated `CodingKeys`, `init(from:)`, and `encode(to:)` implementations.
///
/// ## Example
/// ```swift
/// @FilterCodable
/// struct User: Codable {
///     var id: Int
///     var firstName: String
///     var lastName: String
///     @CodableIgnore { firstName + lastName }
///     var fullName: String
/// }
/// ```
/// In this example, the `fullName` property will be ignored in the generated `CodingKeys`, `init(from:)`, and `encode(to:)` implementations, while `id`, `firstName`, and `lastName` will be included as usual.
@attached(member, names: named(CodingKeys), named(init(from:)), named(encode(to:)))
public macro SturdyFilterCodable() = #externalMacro(module: "MacroSturdy", type: "FilterCodableMacro")

/// Marks a property to be excluded from the generated `CodingKeys`, `init(from:)`, and `encode(to:)` implementations when using `@FilterCodable`.
@attached(peer)
public macro CodableIgnore(_ block: () -> Void) = #externalMacro(module: "MacroSturdy", type: "CodableIgnoreMacro")

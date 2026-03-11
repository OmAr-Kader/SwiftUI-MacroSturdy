# SwiftUI-MacroSturdy

A Swift macro package that simplifies state management in SwiftUI by generating `copy` functions for structs.

## Features

- `@SturdyCopy`: Generates a mutating `copy` function for structs, allowing selective property updates using `Update<T>` enums.
- `@NoCopy`: Excludes properties from the generated `copy` function.

## Installation

Add the package to your Swift project:

```swift
dependencies: [
    .package(url: "https://github.com/OmAr-Kader/SwiftUI-MacroSturdy.git", from: "1.0.0")
]
```

## Usage

Apply `@SturdyCopy` to a struct to generate the `copy` function. Use `@NoCopy` on properties to exclude them.

### Example

```swift
import SwiftUIMacroSturdy

@SturdyCopy
struct HomeState {
    private(set) var isLoading: Bool = false
    private(set) var user: User? = nil

    @NoCopy
    var donot: Int = 0
}

// Usage
var state = HomeState()
state = state.copy(isLoading: .set(true), user: .set(someUser))
```

This generates a `copy` function that updates only the specified properties.

## License

Licensed under the Apache License 2.0. See `LICENSE` for details.

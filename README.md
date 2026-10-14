<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-light.svg" alt="Animation Masterclass: Physics-based motion, particles, change effects and transitions for SwiftUI on iOS and macOS."></picture></p>

<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a></p>

# MobileMotion has moved

**This project now lives in [SwiftUI-Animation-Masterclass](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass).**
This repository is archived and will not change again. Its last release here is
[v1.0.0](https://github.com/muhittincamdali/MobileMotion/releases/tag/v1.0.0).

## Where the code went

SwiftUI-Animation-Masterclass 2.0.0 rewrote the animation and gesture parts of this repository
on top of SwiftUI's own `Animation` and gesture types, with tests.

| Here                        | In SwiftUI-Animation-Masterclass                                                                                                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Spring physics              | [`DampedSpring`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/DampedSpring.swift), solved in closed form                                        |
| Friction for flicks         | [`Decay`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/Decay.swift), with the projected end point of a flick                                    |
| Gravity with a floor bounce | [`GravityBounce`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/GravityBounce.swift)                                                             |
| Gesture-driven animation    | [Gestures](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/tree/main/Sources/SwiftUIAnimationMasterclass/Gestures): `.elasticDrag()` and `.snapDrag()`, which carry the release velocity into the spring |

Not everything came along. The sensors (accelerometer, gyroscope, magnetometer), activity
recognition, shake and tilt detection, haptics, the Dart package, the CocoaPods podspec and the
`Enterprise` helpers (`CircuitBreaker`, `RetryPolicy`, `EventBus`) have nothing to do with
SwiftUI animation and were not carried over. See the
[2.0.0 changelog](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/CHANGELOG.md)
for the exact scope.

## Install the new package

```swift
.package(url: "https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass.git", from: "2.0.0")
```

Then add `.product(name: "SwiftUIAnimationMasterclass", package: "SwiftUI-Animation-Masterclass")` to
your target. It needs iOS 17 or macOS 14, and Swift 6.2. Full documentation:
[SwiftUI-Animation-Masterclass README](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass#readme).

## License

MIT, see [LICENSE](LICENSE).

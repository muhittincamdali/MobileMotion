<p align="center">
  <img src="Assets/logo.png" alt="MobileMotion" width="200"/>
</p>

<h1 align="center">MobileMotion</h1>

<p align="center">
  <strong>🎬 Cross-platform physics-based animation engine for iOS, Flutter & React Native</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift"/>
  <img src="https://img.shields.io/badge/Flutter-3.24-blue.svg" alt="Flutter"/>
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"/>
</p>

---

## Why MobileMotion?

Standard animations feel robotic. Physics-based animations feel natural. **MobileMotion** provides spring physics, gravity, friction, and collision detection across all mobile platforms.

```swift
// iOS
view.animate(.spring(damping: 0.7, stiffness: 300))
    .to(\.center, CGPoint(x: 200, y: 200))
```

```dart
// Flutter
MobileMotion.spring(
  damping: 0.7,
  stiffness: 300,
).animate(controller);
```

## Features

| Feature | Description |
|---------|-------------|
| 🎯 **Spring Physics** | Damping, stiffness, mass |
| 🌍 **Gravity** | Realistic falling animations |
| 🔄 **Momentum** | Velocity-based animations |
| 💥 **Collisions** | Bounce off boundaries |
| ⚡ **60fps** | GPU-accelerated |
| 📱 **Cross-Platform** | iOS, Flutter, React Native |


## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/MobileMotion.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'MobileMotion', '~> 1.0'
```

## Quick Start

### iOS (Swift)

```swift
import MobileMotion

// Spring animation
Motion.spring(view)
    .damping(0.7)
    .stiffness(300)
    .animate(to: targetPosition)

// Gravity
Motion.gravity(view)
    .acceleration(9.8)
    .bounce(0.6)
    .start()

// Drag with momentum
view.enableDrag { gesture in
    Motion.momentum(view)
        .velocity(gesture.velocity)
        .friction(0.95)
        .start()
}
```

### Flutter

```dart
import 'package:mobile_motion/mobile_motion.dart';

// Spring animation
SpringAnimation(
  damping: 0.7,
  stiffness: 300,
  child: MyWidget(),
).animateTo(Offset(200, 200));

// Physics-based scroll
PhysicsScrollView(
  physics: BouncingScrollPhysics(
    friction: 0.95,
    bounce: 0.3,
  ),
  child: content,
);
```

## Physics Parameters

| Parameter | Description | Range |
|-----------|-------------|-------|
| `damping` | Oscillation decay | 0.0 - 1.0 |
| `stiffness` | Spring strength | 100 - 1000 |
| `mass` | Object weight | 0.1 - 10.0 |
| `friction` | Movement decay | 0.9 - 1.0 |
| `bounce` | Collision elasticity | 0.0 - 1.0 |

## Presets

```swift
Motion.preset(.bouncy)  // High bounce
Motion.preset(.smooth)  // No bounce
Motion.preset(.snappy)  // Quick settle
Motion.preset(.gentle)  // Slow, soft
```

## Chained Animations

```swift
Motion.sequence([
    .spring(to: point1),
    .wait(0.5),
    .spring(to: point2),
    .gravity(to: floor)
])
```

## Interactive Gestures

```swift
view.enablePhysicsDrag { state in
    switch state {
    case .began:
        Motion.pause(view)
    case .changed(let translation):
        view.center += translation
    case .ended(let velocity):
        Motion.momentum(view)
            .velocity(velocity)
            .boundaries(screen.bounds)
            .start()
    }
}
```

## Performance

- 60fps on all devices
- GPU-accelerated
- Minimal CPU overhead
- Battery optimized

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License

---

## 📈 Star History

<a href="https://star-history.com/#muhittincamdali/MobileMotion&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/MobileMotion&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/MobileMotion&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/MobileMotion&type=Date" />
 </picture>
</a>

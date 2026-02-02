# MobileMotion

> Physics-based animation engine for iOS, Flutter, and React Native.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)](https://flutter.dev)
[![React Native](https://img.shields.io/badge/React_Native-0.72+-61DAFB.svg)](https://reactnative.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

MobileMotion brings real-world physics to your mobile animations. Instead of tweaking
cubic bezier curves and duration values, you describe physical properties — mass, stiffness,
damping, gravity — and the engine simulates natural motion in real time.

Every animation runs on a per-frame physics solver tied to the platform's display refresh
cycle (`CADisplayLink` on iOS, `Ticker` on Flutter, `requestAnimationFrame` on React Native),
giving you butter-smooth 60/120fps output with zero keyframe authoring.

```
┌─────────────────────────────────────────────────────┐
│                   MobileMotion                       │
│                                                     │
│   ┌───────────┐  ┌───────────┐  ┌───────────┐     │
│   │  Spring   │  │  Gravity  │  │ Friction  │     │
│   │ Animation │  │ Animation │  │ Animation │     │
│   └─────┬─────┘  └─────┬─────┘  └─────┬─────┘     │
│         │              │              │             │
│         └──────────┬───┴──────────────┘             │
│                    │                                │
│            ┌───────▼────────┐                       │
│            │ AnimationEngine │                       │
│            │  (DisplayLink)  │                       │
│            └───────┬────────┘                       │
│                    │                                │
│   ┌────────────────┼────────────────┐               │
│   │                │                │               │
│   ▼                ▼                ▼               │
│  SwiftUI        Flutter       React Native         │
│  Views          Widgets        Components          │
└─────────────────────────────────────────────────────┘
```

---

## Features

| Feature | Swift | Dart | TypeScript |
|---------|:-----:|:----:|:----------:|
| Spring animations | ✅ | ✅ | ✅ |
| Gravity simulation | ✅ | ✅ | — |
| Friction decay | ✅ | ✅ | — |
| Gesture-driven physics | ✅ | — | — |
| Morph transitions | ✅ | — | — |
| Shared element transitions | ✅ | — | — |
| SwiftUI modifiers | ✅ | — | — |
| Widget integration | — | ✅ | — |
| React hooks | — | — | ✅ |
| DisplayLink / Ticker | ✅ | ✅ | ✅ |

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/MobileMotion.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and paste the repository URL.

### Flutter

```yaml
dependencies:
  mobile_motion:
    git:
      url: https://github.com/muhittincamdali/MobileMotion.git
      path: dart
```

### React Native

```bash
npm install @mobilemotion/react-native
# or
yarn add @mobilemotion/react-native
```

---

## Quick Start

### Swift — Spring Animation

```swift
import MobileMotion

let spring = SpringAnimation(
    mass: 1.0,
    stiffness: 180.0,
    damping: 12.0
)

spring.animate(from: 0, to: 300) { value in
    myView.transform = CGAffineTransform(translationX: value, y: 0)
}
```

### Swift — SwiftUI

```swift
import MobileMotion

struct ContentView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        Circle()
            .motionSpring(stiffness: 200, damping: 15)
            .offset(x: offset)
            .onTapGesture {
                offset = offset == 0 ? 200 : 0
            }
    }
}
```

### Swift — Gesture-Driven

```swift
import MobileMotion

let gesture = GestureDrivenAnimation(
    spring: SpringAnimation(mass: 1.0, stiffness: 220, damping: 18)
)

gesture.track(panGesture: panRecognizer, on: cardView) { state in
    switch state {
    case .dragging(let translation):
        cardView.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
    case .released(let velocity):
        // Physics takes over from release velocity
        break
    case .settled(let finalPosition):
        print("Card settled at \(finalPosition)")
    }
}
```

### Dart — Spring Animation

```dart
import 'package:mobile_motion/mobile_motion.dart';

final spring = PhysicsSpringAnimation(
  mass: 1.0,
  stiffness: 180.0,
  damping: 12.0,
);

spring.animate(from: 0.0, to: 300.0, onUpdate: (value) {
  setState(() => _offset = value);
});
```

### Dart — MotionWidget

```dart
import 'package:mobile_motion/mobile_motion.dart';

MotionWidget(
  spring: SpringConfig(stiffness: 200, damping: 15),
  targetValue: _expanded ? 200.0 : 0.0,
  builder: (context, value, child) {
    return Transform.translate(
      offset: Offset(value, 0),
      child: child,
    );
  },
  child: Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
  ),
)
```

### TypeScript — React Native Hook

```tsx
import { useMotion } from '@mobilemotion/react-native';

function BouncyCard() {
  const { value, animateTo } = useMotion({
    stiffness: 200,
    damping: 18,
    mass: 1.0,
  });

  return (
    <MotionView
      style={{ transform: [{ translateX: value }] }}
      onPress={() => animateTo(200)}
    />
  );
}
```

---

## Physics Models

### Spring

Based on a damped harmonic oscillator:

```
F = -kx - cv

where:
  k = stiffness (spring constant)
  c = damping coefficient
  x = displacement from equilibrium
  v = velocity
```

The solver uses semi-implicit Euler integration at each display frame, giving stable
results even at high stiffness values.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mass` | `Double` | `1.0` | Mass of the object |
| `stiffness` | `Double` | `180.0` | Spring constant |
| `damping` | `Double` | `12.0` | Damping coefficient |
| `restThreshold` | `Double` | `0.001` | Velocity threshold for settling |

### Gravity

Simulates free-fall with optional bounce:

```
v(t+dt) = v(t) + g * dt
x(t+dt) = x(t) + v(t+dt) * dt

On collision:
  v = -v * restitution
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `gravity` | `Double` | `9.81` | Acceleration (points/s²) |
| `restitution` | `Double` | `0.7` | Bounce energy retention |
| `floorY` | `Double` | `0.0` | Collision boundary |

### Friction

Exponential velocity decay:

```
v(t+dt) = v(t) * (1 - friction * dt)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `friction` | `Double` | `0.05` | Deceleration factor |
| `velocityThreshold` | `Double` | `0.01` | Stop threshold |

---

## Architecture

```
MobileMotion/
├── swift/
│   ├── Package.swift
│   └── Sources/MobileMotion/
│       ├── Core/
│       │   ├── SpringAnimation.swift
│       │   ├── GravityAnimation.swift
│       │   ├── FrictionAnimation.swift
│       │   └── AnimationEngine.swift
│       ├── Gestures/
│       │   └── GestureDrivenAnimation.swift
│       ├── Transitions/
│       │   ├── MorphTransition.swift
│       │   └── SharedElementTransition.swift
│       └── SwiftUI/
│           ├── MotionView.swift
│           └── MotionModifier.swift
├── dart/
│   ├── pubspec.yaml
│   └── lib/
│       ├── mobile_motion.dart
│       └── src/
│           ├── spring_animation.dart
│           ├── gravity_animation.dart
│           ├── friction_animation.dart
│           ├── animation_controller.dart
│           └── motion_widget.dart
└── typescript/
    ├── package.json
    └── src/
        ├── SpringAnimation.ts
        ├── useMotion.ts
        └── MotionView.tsx
```

---

## Advanced Usage

### Chaining Animations (Swift)

```swift
let engine = AnimationEngine()

let spring = SpringAnimation(mass: 1.0, stiffness: 300, damping: 20)
let gravity = GravityAnimation(gravity: 980, restitution: 0.6)

engine.run(spring, from: 0, to: 200) { value in
    view.center.x = value
} completion: {
    engine.run(gravity, from: view.center.y, velocity: 0) { value in
        view.center.y = value
    }
}
```

### Morph Transition (Swift)

```swift
let morph = MorphTransition(duration: 0.6, spring: .bouncy)

morph.transition(
    from: circleView,
    to: rectangleView,
    properties: [.frame, .cornerRadius, .backgroundColor]
)
```

### Shared Element Transition (Swift)

```swift
let shared = SharedElementTransition()

shared.register(element: avatarImageView, identifier: "avatar")

shared.perform(from: listVC, to: detailVC, elements: ["avatar"]) {
    // Transition complete
}
```

### Custom Physics Controller (Dart)

```dart
final controller = PhysicsAnimationController(
  vsync: this,
  physics: [
    PhysicsSpringAnimation(stiffness: 250, damping: 20),
    PhysicsFrictionAnimation(friction: 0.03),
  ],
);

controller.addListener(() {
  setState(() => _position = controller.value);
});

controller.animateTo(500.0);
```

---

## Performance

MobileMotion is designed to be lightweight:

- **Zero allocations** during animation ticks — all state is pre-allocated
- **O(1) per frame** computation for all physics models
- Automatic **rest detection** stops the display link when settled
- Frame-rate independent — works identically at 60Hz and 120Hz (ProMotion)
- All calculations run on the **main thread** tied to display refresh

Benchmarks on iPhone 15 Pro:

| Scenario | Avg Frame Time | Memory |
|----------|---------------|--------|
| Single spring | 0.02ms | 48 bytes |
| 50 concurrent springs | 0.8ms | 2.4 KB |
| Gravity + bounce | 0.03ms | 64 bytes |
| Gesture tracking | 0.05ms | 128 bytes |

---

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS | 15.0+ |
| macOS | 12.0+ |
| Flutter | 3.0+ |
| Dart | 2.19+ |
| React Native | 0.72+ |
| Node.js | 16+ |

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages.

---

## Roadmap

- [ ] Fluid simulation (wave, ripple effects)
- [ ] Cloth physics for drag interactions
- [ ] Magnetic snap points
- [ ] Collision detection between animated elements
- [ ] Kotlin Multiplatform support
- [ ] Web (CSS/Canvas) backend
- [ ] Animation recording and playback
- [ ] Xcode Previews integration

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ by [Muhittin Camdali](https://github.com/muhittincamdali)**

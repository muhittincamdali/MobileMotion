<h1 align="center">MobileMotion</h1>

<p align="center">
  <strong>📱 Unified motion sensors, gesture detection & physics animations for iOS</strong>
</p>

<p align="center">
  <a href="https://github.com/muhittincamdali/MobileMotion/actions/workflows/ci.yml">
    <img src="https://github.com/muhittincamdali/MobileMotion/actions/workflows/ci.yml/badge.svg" alt="CI"/>
  </a>
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/iOS-15.0+-blue.svg" alt="iOS 15.0+"/>
  <img src="https://img.shields.io/badge/watchOS-8.0+-green.svg" alt="watchOS 8.0+"/>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="License"/>
  </a>
</p>

---

## What is MobileMotion?

MobileMotion wraps CoreMotion into a clean, modern Swift API. Accelerometer, gyroscope, magnetometer, device motion, activity recognition, gesture detection, and physics-based animations — all in one package with SwiftUI bindings out of the box.

```swift
import MobileMotion

// One-liner accelerometer access
let accel = Accelerometer()
accel.start { data in
    print("Acceleration: \(data.magnitude)G")
}

// Detect shakes, tilts, impacts
let detector = GestureDetector()
detector.onGesture = { gesture in
    print("\(gesture.type) detected!")
}
detector.start()
```

## Features

| Category | Feature | Description |
|----------|---------|-------------|
| 📡 **Sensors** | Accelerometer | 3-axis acceleration with buffering & stats |
| | Gyroscope | Rotation rate with history tracking |
| | Magnetometer | Magnetic field + compass heading |
| | Device Motion | Fused attitude, gravity, user acceleration |
| 🏃 **Activity** | Recognition | Walking, running, cycling, automotive, stationary |
| | Step counting | Pedometer integration |
| | Historical query | Activity history for any date range |
| 🖐️ **Gestures** | Shake detection | Configurable threshold and sensitivity |
| | Tilt detection | Forward, backward, left, right |
| | Face orientation | Face-up / face-down detection |
| | Twist / Impact | Wrist flick and sudden impact events |
| | Pickup | Detects device picked up from rest |
| 🎬 **Animation** | Spring physics | Damped harmonic oscillator with presets |
| | Gravity | Free fall with floor bounce and restitution |
| | Friction | Velocity decay for fling/flick gestures |
| | Animation engine | Batched display-link driven animations |
| 🎨 **SwiftUI** | Sensor bindings | `@StateObject` wrappers for all sensors |
| | View modifiers | `.withAccelerometer()`, `.motionSpring()` |
| | Effects | Shake, pulse, glow, flip, typewriter |
| 🧲 **Physics** | Spring system | Multi-spring management with RK4 solver |
| | Gravity system | N-body simulation with collision detection |
| | Collision | AABB detection + impulse resolution |

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/MobileMotion.git", from: "2.0.0")
]
```

### CocoaPods

```ruby
pod 'MobileMotion', '~> 2.0'
```

## Quick Start

### Sensor Access

```swift
import MobileMotion

let manager = MotionManager()

// Accelerometer
manager.startAccelerometer(interval: 0.02) { data in
    print("X: \(data.acceleration.x)")
}

// Gyroscope
manager.startGyroscope(interval: 0.02) { data in
    print("Rotation: \(data.rotationRate.x) rad/s")
}

// Magnetometer
manager.startMagnetometer(interval: 0.02) { data in
    print("Field: \(data.magneticField.x) µT")
}

// Fused device motion (recommended)
manager.startDeviceMotion { data in
    print("Pitch: \(data.attitude.pitch)")
    print("User acceleration: \(data.userAcceleration)")
}
```

### High-Level Wrappers

```swift
// Accelerometer with buffer and statistics
let accel = Accelerometer()
accel.start { data in
    print("Magnitude: \(data.magnitude)G")
}
print("Average: \(accel.average)")
print("Peak: \(accel.peakMagnitude)G")

// Magnetometer with compass heading
let mag = Magnetometer()
mag.start { _ in }
print("Heading: \(mag.estimatedHeading)°")
```

### Activity Recognition

```swift
let recognizer = ActivityRecognizer()

// Live updates
recognizer.startUpdates { snapshot in
    print("Activity: \(snapshot.activity)")  // walking, running, cycling...
    print("Confidence: \(snapshot.confidence)")
}

// Historical query
recognizer.queryActivities(
    from: Date().addingTimeInterval(-3600),
    to: Date()
) { activities in
    for activity in activities {
        print("\(activity.date): \(activity.activity)")
    }
}

// Step counting
recognizer.querySteps(from: startOfDay, to: Date()) { steps in
    print("Steps today: \(steps ?? 0)")
}
```

### Gesture Detection

```swift
let detector = GestureDetector(config: .default)

// Listen for specific gestures
detector.enabledGestures = [.shake, .faceDown, .impact]

detector.onGesture = { gesture in
    switch gesture.type {
    case .shake:
        print("Shake! Intensity: \(gesture.intensity)")
    case .faceDown:
        print("Device placed face down")
    case .impact:
        print("Impact detected!")
    default:
        break
    }
}

detector.start()
```

### SwiftUI Integration

```swift
import MobileMotion
import SwiftUI

struct SensorDashboard: View {
    @StateObject private var accel = AccelerometerObservable()
    @StateObject private var motion = DeviceMotionObservable()
    @StateObject private var activity = ActivityObservable()

    var body: some View {
        VStack(spacing: 20) {
            // Accelerometer
            Section("Accelerometer") {
                HStack {
                    Text("X: \(accel.data.x, specifier: "%.3f")")
                    Text("Y: \(accel.data.y, specifier: "%.3f")")
                    Text("Z: \(accel.data.z, specifier: "%.3f")")
                }
            }

            // Attitude
            Section("Device Attitude") {
                Text("Pitch: \(motion.data.attitude.pitch, specifier: "%.2f")")
                Text("Roll: \(motion.data.attitude.roll, specifier: "%.2f")")
                Text("Yaw: \(motion.data.attitude.yaw, specifier: "%.2f")")
            }

            // Activity
            if let current = activity.current {
                Label(current.activity.description,
                      systemImage: current.activity.symbolName)
            }
        }
        .withAccelerometer(accel)
        .withDeviceMotion(motion)
        .onAppear { activity.start() }
    }
}
```

### Spring Animations

```swift
import MobileMotion

// Quick spring presets
let spring = SpringAnimation.bouncy
spring.animate(from: 0, to: 300) { value in
    myView.center.x = CGFloat(value)
}

// Animation engine (batched display link)
let engine = AnimationEngine()

let anim = SpringAnimation(stiffness: 200, damping: 15)
engine.run(anim, from: 0, to: 1) { progress in
    myView.alpha = CGFloat(progress)
}

// Gravity with bounce
let gravity = GravityAnimation(gravity: 980, restitution: 0.6, floorY: 600)
engine.run(gravity, from: 0) { position in
    myView.center.y = CGFloat(position)
}
```

### SwiftUI Animation Modifiers

```swift
// Physics spring
Text("Hello")
    .motionSpring(stiffness: 200, damping: 15)

// Presets
Circle()
    .motionBouncy()   // High bounce
    .motionSnappy()   // Quick settle
    .motionGentle()   // Slow, soft
    .motionSmooth()   // Critically damped
```

## Architecture

```
MobileMotion/
├── Sensors/          ← CoreMotion wrappers
│   ├── MotionManager     (unified CMMotionManager)
│   ├── Accelerometer     (3-axis + buffer + stats)
│   ├── Gyroscope         (rotation rate)
│   ├── Magnetometer      (magnetic field + heading)
│   └── DeviceMotion      (fused sensor data)
├── Activity/         ← Activity recognition
│   ├── ActivityRecognizer (walking/running/cycling)
│   └── ActivityType       (type + snapshot)
├── Gestures/         ← Motion gesture detection
│   ├── GestureDetector    (shake/tilt/twist/impact)
│   ├── GestureAnimator    (UIKit gesture → animation)
│   └── GestureDrivenAnimation (physics-driven)
├── Core/             ← Animation primitives
│   ├── AnimationEngine    (batched display link)
│   ├── SpringAnimation    (damped harmonic oscillator)
│   ├── GravityAnimation   (free fall + bounce)
│   └── FrictionAnimation  (velocity decay)
├── Physics/          ← Simulation systems
│   ├── SpringSystem       (multi-spring + RK4)
│   └── GravitySystem      (N-body + collisions)
├── SwiftUI/          ← Declarative bindings
│   ├── SensorBindings     (observable wrappers)
│   ├── MotionModifier     (spring modifiers)
│   └── MotionView         (animation views)
├── Particles/        ← Particle effects
│   ├── ConfettiSystem     (celebration effects)
│   └── SnowSystem         (weather effects)
└── Transitions/      ← View transitions
    ├── SharedElementTransition
    ├── MorphTransition
    └── PageCurlTransition
```

## Configuration

### Gesture Sensitivity

```swift
// Default thresholds
let detector = GestureDetector(config: .default)

// More sensitive (easier to trigger)
let sensitive = GestureDetector(config: .sensitive)

// Custom
let custom = GestureDetector(config: GestureDetectorConfig(
    shakeThreshold: 1.2,
    tiltThreshold: 0.3,
    impactThreshold: 2.5
))
```

### Spring Presets

| Preset | Stiffness | Damping | Use Case |
|--------|-----------|---------|----------|
| `.gentle` | 120 | 14 | Slow, soft transitions |
| `.snappy` | 300 | 20 | Quick, responsive UI |
| `.bouncy` | 250 | 8 | Playful, overshooting |
| `.smooth` | 200 | ~28 | No overshoot |

## Requirements

- iOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15+

## Info.plist Keys

Add these if you use motion or activity features:

```xml
<key>NSMotionUsageDescription</key>
<string>Used for motion-based features and gesture detection.</string>
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

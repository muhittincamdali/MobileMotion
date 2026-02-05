# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-07-22

### Added
- **Sensor Wrappers**: `MotionManager`, `Accelerometer`, `Gyroscope`, `Magnetometer`, `DeviceMotionSensor` with buffering and statistics
- **Activity Recognition**: `ActivityRecognizer` with live updates, historical queries, and step counting
- **Gesture Detection**: `GestureDetector` supporting shake, tilt, face orientation, twist, impact, and pickup gestures
- **SwiftUI Bindings**: Observable wrappers (`AccelerometerObservable`, `GyroscopeObservable`, etc.) and view modifiers
- **Configurable thresholds**: `GestureDetectorConfig` with default and sensitive presets
- **Data types**: `AccelerationData`, `RotationRateData`, `MagneticFieldData`, `DeviceMotionData` with Sendable conformance

### Changed
- **Package.swift**: Fixed source path resolution — all sources now consolidated under `Sources/MobileMotion/`
- **Architecture**: Reorganized into Sensors, Activity, Gestures, Core, Physics, SwiftUI, Particles, and Transitions modules
- **Access control**: Animation properties changed from `private(set)` to `internal(set)` for proper engine integration

### Fixed
- Package.swift pointing to wrong source directory
- ConfettiSystem duplicate property compilation error
- SpringAnimation/GravityAnimation/FrictionAnimation access control preventing AnimationEngine from setting state

## [1.0.0] - 2025-01-15

### Added
- Spring, gravity, and friction animation primitives
- Physics simulation with collision detection
- Gesture-driven animations with snap points
- Particle effects (confetti, snow)
- View transitions (morph, page curl, shared element)
- SwiftUI modifiers for spring animations

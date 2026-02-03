# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Web (CSS/Canvas) backend
- Fluid simulation effects

## [1.0.0] - 2025-01-15

### Added
- SpringAnimation with damped harmonic oscillator
- GravityAnimation with bounce support
- FrictionAnimation with exponential decay
- AnimationEngine with DisplayLink integration
- GestureDrivenAnimation for touch interactions
- MorphTransition for shape morphing
- SharedElementTransition for navigation
- SwiftUI MotionView and modifiers
- Dart PhysicsSpringAnimation
- Dart MotionWidget
- React Native useMotion hook
- React Native MotionView component
- Zero allocations during animation ticks
- Frame-rate independent calculations
- Automatic rest detection

### Changed
- Optimized physics solver for 120Hz displays

### Fixed
- Gesture velocity calculation edge cases

[Unreleased]: https://github.com/muhittincamdali/MobileMotion/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/muhittincamdali/MobileMotion/releases/tag/v1.0.0

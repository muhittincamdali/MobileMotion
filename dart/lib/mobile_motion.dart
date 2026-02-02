/// MobileMotion - Physics-based animation engine for Flutter.
///
/// Provides spring, gravity, and friction animations driven by
/// real physics simulation rather than predefined timing curves.
///
/// ## Quick Start
///
/// ```dart
/// final spring = PhysicsSpringAnimation(
///   mass: 1.0,
///   stiffness: 180.0,
///   damping: 12.0,
/// );
///
/// spring.animate(from: 0.0, to: 300.0, onUpdate: (value) {
///   setState(() => _offset = value);
/// });
/// ```
library mobile_motion;

export 'src/spring_animation.dart';
export 'src/gravity_animation.dart';
export 'src/friction_animation.dart';
export 'src/animation_controller.dart';
export 'src/motion_widget.dart';

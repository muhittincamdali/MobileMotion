import SwiftUI

/// A view modifier that applies physics-based spring animation to a value.
///
/// ```swift
/// Circle()
///     .motionSpring(stiffness: 200, damping: 15)
///     .offset(x: offset)
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct MotionModifier: ViewModifier {

    let stiffness: Double
    let damping: Double
    let mass: Double

    public func body(content: Content) -> some View {
        content
            .animation(
                .interpolatingSpring(
                    mass: mass,
                    stiffness: stiffness,
                    damping: damping,
                    initialVelocity: 0
                ),
                value: UUID()
            )
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {

    /// Applies a physics-based spring animation modifier.
    ///
    /// - Parameters:
    ///   - stiffness: Spring constant. Default `200.0`.
    ///   - damping: Damping coefficient. Default `15.0`.
    ///   - mass: Object mass. Default `1.0`.
    /// - Returns: The modified view.
    public func motionSpring(
        stiffness: Double = 200.0,
        damping: Double = 15.0,
        mass: Double = 1.0
    ) -> some View {
        self.modifier(MotionModifier(
            stiffness: stiffness,
            damping: damping,
            mass: mass
        ))
    }

    /// Applies a bouncy spring preset.
    public func motionBouncy() -> some View {
        motionSpring(stiffness: 250.0, damping: 8.0, mass: 1.0)
    }

    /// Applies a snappy spring preset.
    public func motionSnappy() -> some View {
        motionSpring(stiffness: 300.0, damping: 20.0, mass: 1.0)
    }

    /// Applies a gentle spring preset.
    public func motionGentle() -> some View {
        motionSpring(stiffness: 120.0, damping: 14.0, mass: 1.0)
    }

    /// Applies a smooth (critically damped) spring preset.
    public func motionSmooth() -> some View {
        let stiffness = 200.0
        let criticalDamping = 2.0 * sqrt(stiffness * 1.0)
        return motionSpring(stiffness: stiffness, damping: criticalDamping, mass: 1.0)
    }
}

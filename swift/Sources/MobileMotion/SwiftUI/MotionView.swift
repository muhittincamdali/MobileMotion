import SwiftUI

/// A SwiftUI view that wraps content with physics-based animation capabilities.
///
/// MotionView provides a declarative way to apply spring, gravity, or friction
/// animations to any SwiftUI content.
///
/// ```swift
/// MotionView(value: $offset, spring: .bouncy) { animatedValue in
///     Circle()
///         .frame(width: 50, height: 50)
///         .offset(x: animatedValue)
/// }
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct MotionView<Content: View>: View {

    // MARK: - Properties

    @Binding private var targetValue: Double
    @StateObject private var animator = MotionAnimator()

    private let spring: SpringAnimation
    private let content: (Double) -> Content

    // MARK: - Initialization

    /// Creates a MotionView with a spring animation.
    ///
    /// - Parameters:
    ///   - value: Binding to the target value. Changes trigger animation.
    ///   - spring: Spring configuration. Default is `.snappy`.
    ///   - content: View builder receiving the current animated value.
    public init(
        value: Binding<Double>,
        spring: SpringAnimation = .snappy,
        @ViewBuilder content: @escaping (Double) -> Content
    ) {
        self._targetValue = value
        self.spring = spring
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        content(animator.currentValue)
            .onChange(of: targetValue) { newValue in
                animator.animateTo(
                    newValue,
                    stiffness: spring.stiffness,
                    damping: spring.damping,
                    mass: spring.mass
                )
            }
            .onAppear {
                animator.currentValue = targetValue
            }
    }
}

/// Observable object that drives the animation state for MotionView.
@available(iOS 15.0, macOS 12.0, *)
final class MotionAnimator: ObservableObject {

    @Published var currentValue: Double = 0.0

    private var velocity: Double = 0.0
    private var target: Double = 0.0
    private var stiffness: Double = 300.0
    private var damping: Double = 20.0
    private var mass: Double = 1.0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0.0

    private let restThreshold: Double = 0.001

    func animateTo(
        _ target: Double,
        stiffness: Double,
        damping: Double,
        mass: Double
    ) {
        self.target = target
        self.stiffness = stiffness
        self.damping = damping
        self.mass = mass

        startDisplayLink()
    }

    private func startDisplayLink() {
        stopDisplayLink()
        lastTimestamp = 0.0

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let dt = min(link.timestamp - lastTimestamp, 1.0 / 30.0)
        lastTimestamp = link.timestamp

        let displacement = currentValue - target
        let springForce = -stiffness * displacement
        let dampingForce = -damping * velocity
        let acceleration = (springForce + dampingForce) / mass

        velocity += acceleration * dt
        currentValue += velocity * dt

        if abs(currentValue - target) < restThreshold && abs(velocity) < restThreshold {
            currentValue = target
            velocity = 0.0
            stopDisplayLink()
        }
    }

    deinit {
        stopDisplayLink()
    }
}

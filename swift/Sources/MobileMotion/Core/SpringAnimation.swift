import Foundation
import QuartzCore

/// A damped harmonic oscillator animation.
///
/// Uses semi-implicit Euler integration to solve:
/// ```
/// F = -kx - cv
/// a = F / m
/// v' = v + a * dt
/// x' = x + v' * dt
/// ```
///
/// This produces natural spring-like motion that feels organic
/// and responsive, without needing keyframes or timing curves.
public final class SpringAnimation {

    // MARK: - Configuration

    /// Mass of the simulated object. Higher mass means slower acceleration.
    public var mass: Double

    /// Spring constant. Higher values produce stiffer, snappier springs.
    public var stiffness: Double

    /// Damping coefficient. Controls how quickly oscillation dies out.
    public var damping: Double

    /// When both velocity and displacement fall below this threshold,
    /// the animation is considered settled and stops.
    public var restThreshold: Double

    /// Maximum number of seconds per integration step.
    /// Clamping prevents instability from large frame drops.
    public var maxStepSize: Double

    // MARK: - State

    /// Current position value of the animation.
    public private(set) var currentValue: Double = 0.0

    /// Current velocity in units per second.
    public private(set) var velocity: Double = 0.0

    /// Target position the spring is pulling toward.
    public private(set) var targetValue: Double = 0.0

    /// Start position the animation began from.
    public private(set) var fromValue: Double = 0.0

    /// Whether the animation is currently running.
    public private(set) var isAnimating: Bool = false

    // MARK: - Callbacks

    /// Called on each frame with the current interpolated value.
    public var onUpdate: ((Double) -> Void)?

    /// Called once when the animation settles at the target value.
    public var onCompletion: (() -> Void)?

    // MARK: - Private

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0.0

    // MARK: - Initialization

    /// Creates a new spring animation with the given physical properties.
    ///
    /// - Parameters:
    ///   - mass: Object mass. Default `1.0`.
    ///   - stiffness: Spring constant. Default `180.0`.
    ///   - damping: Damping coefficient. Default `12.0`.
    ///   - restThreshold: Settling threshold. Default `0.001`.
    public init(
        mass: Double = 1.0,
        stiffness: Double = 180.0,
        damping: Double = 12.0,
        restThreshold: Double = 0.001
    ) {
        self.mass = mass
        self.stiffness = stiffness
        self.damping = damping
        self.restThreshold = restThreshold
        self.maxStepSize = 1.0 / 30.0
    }

    // MARK: - Public API

    /// Starts the spring animation from one value to another.
    ///
    /// - Parameters:
    ///   - from: Starting position.
    ///   - to: Target position.
    ///   - initialVelocity: Optional starting velocity (e.g., from a gesture).
    ///   - update: Called each frame with the current value.
    ///   - completion: Called when the spring settles.
    public func animate(
        from: Double,
        to: Double,
        initialVelocity: Double = 0.0,
        update: ((Double) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        stop()

        fromValue = from
        targetValue = to
        currentValue = from
        velocity = initialVelocity
        isAnimating = true

        if let update = update { onUpdate = update }
        if let completion = completion { onCompletion = completion }

        lastTimestamp = 0.0
        startDisplayLink()
    }

    /// Immediately stops the animation at its current value.
    public func stop() {
        isAnimating = false
        stopDisplayLink()
    }

    /// Updates the target while preserving current velocity.
    /// Useful for interactive animations where the destination changes.
    ///
    /// - Parameter newTarget: The new target position.
    public func retarget(to newTarget: Double) {
        targetValue = newTarget
        if !isAnimating {
            animate(from: currentValue, to: newTarget, initialVelocity: velocity)
        }
    }

    /// Advances the simulation by a given time step.
    /// Exposed for testing and custom render loops.
    ///
    /// - Parameter dt: Time delta in seconds.
    /// - Returns: The new position after integration.
    @discardableResult
    public func step(dt: Double) -> Double {
        let clampedDt = min(dt, maxStepSize)

        let displacement = currentValue - targetValue

        // F = -kx - cv
        let springForce = -stiffness * displacement
        let dampingForce = -damping * velocity
        let totalForce = springForce + dampingForce

        // a = F / m
        let acceleration = totalForce / mass

        // Semi-implicit Euler: update velocity first, then position
        velocity += acceleration * clampedDt
        currentValue += velocity * clampedDt

        return currentValue
    }

    /// Checks whether the spring has come to rest.
    ///
    /// - Returns: `true` if both velocity and displacement are below the threshold.
    public func isAtRest() -> Bool {
        let displacement = abs(currentValue - targetValue)
        let speed = abs(velocity)
        return displacement < restThreshold && speed < restThreshold
    }

    // MARK: - Presets

    /// A gentle, slow spring with heavy damping.
    public static var gentle: SpringAnimation {
        SpringAnimation(mass: 1.0, stiffness: 120.0, damping: 14.0)
    }

    /// A snappy, responsive spring with moderate damping.
    public static var snappy: SpringAnimation {
        SpringAnimation(mass: 1.0, stiffness: 300.0, damping: 20.0)
    }

    /// A bouncy spring with low damping that overshoots the target.
    public static var bouncy: SpringAnimation {
        SpringAnimation(mass: 1.0, stiffness: 250.0, damping: 8.0)
    }

    /// A critically damped spring that reaches the target with minimal overshoot.
    public static var smooth: SpringAnimation {
        let stiffness = 200.0
        let criticalDamping = 2.0 * sqrt(stiffness * 1.0)
        return SpringAnimation(mass: 1.0, stiffness: stiffness, damping: criticalDamping)
    }

    // MARK: - DisplayLink

    private func startDisplayLink() {
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

        let dt = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp

        step(dt: dt)
        onUpdate?(currentValue)

        if isAtRest() {
            currentValue = targetValue
            velocity = 0.0
            isAnimating = false
            stopDisplayLink()
            onUpdate?(currentValue)
            onCompletion?()
        }
    }
}

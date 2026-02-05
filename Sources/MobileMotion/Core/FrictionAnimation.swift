import Foundation
import QuartzCore

/// Simulates friction-based deceleration.
///
/// Applies exponential velocity decay each frame:
/// ```
/// v(t+dt) = v(t) * (1 - friction * dt)
/// x(t+dt) = x(t) + v(t+dt) * dt
/// ```
///
/// Commonly used for flick/fling gestures where the object should
/// glide to a stop based on release velocity.
public final class FrictionAnimation {

    // MARK: - Configuration

    /// Friction coefficient. Higher values cause faster deceleration.
    /// Typical range: `0.01` (ice-like) to `0.15` (heavy drag).
    public var friction: Double

    /// Velocity magnitude below which the animation stops.
    public var velocityThreshold: Double

    // MARK: - State

    /// Current position value.
    public internal(set) var currentValue: Double = 0.0

    /// Current velocity in units per second.
    public internal(set) var velocity: Double = 0.0

    /// Whether the animation is active.
    public internal(set) var isAnimating: Bool = false

    // MARK: - Callbacks

    /// Called each frame with the current position.
    public var onUpdate: ((Double) -> Void)?

    /// Called when the object decelerates to rest.
    public var onCompletion: (() -> Void)?

    // MARK: - Private

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0.0

    // MARK: - Initialization

    /// Creates a friction animation.
    ///
    /// - Parameters:
    ///   - friction: Deceleration factor. Default `0.05`.
    ///   - velocityThreshold: Minimum velocity to keep animating. Default `0.5`.
    public init(friction: Double = 0.05, velocityThreshold: Double = 0.5) {
        self.friction = friction
        self.velocityThreshold = velocityThreshold
    }

    // MARK: - Public API

    /// Begins decelerating from a starting position and velocity.
    ///
    /// - Parameters:
    ///   - from: Starting position.
    ///   - velocity: Initial velocity (from gesture release, etc.).
    ///   - update: Frame callback.
    ///   - completion: Called when velocity drops below threshold.
    public func animate(
        from: Double,
        velocity: Double,
        update: ((Double) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        stop()

        currentValue = from
        self.velocity = velocity
        isAnimating = true

        if let update = update { onUpdate = update }
        if let completion = completion { onCompletion = completion }

        lastTimestamp = 0.0
        startDisplayLink()
    }

    /// Stops the animation immediately.
    public func stop() {
        isAnimating = false
        stopDisplayLink()
    }

    /// Advances the simulation by the given time step.
    @discardableResult
    public func step(dt: Double) -> Double {
        let clampedDt = min(dt, 1.0 / 30.0)

        // Exponential decay
        velocity *= (1.0 - friction * clampedDt * 60.0)
        currentValue += velocity * clampedDt

        return currentValue
    }

    /// Whether the object has effectively stopped.
    public func isAtRest() -> Bool {
        return abs(velocity) < velocityThreshold
    }

    /// Predicts the final resting position given current state.
    public func predictedRestPosition() -> Double {
        var pos = currentValue
        var vel = velocity
        let dt = 1.0 / 60.0
        let decayPerFrame = 1.0 - friction * 60.0 * dt

        while abs(vel) >= velocityThreshold {
            vel *= decayPerFrame
            pos += vel * dt
        }

        return pos
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
            velocity = 0.0
            isAnimating = false
            stopDisplayLink()
            onUpdate?(currentValue)
            onCompletion?()
        }
    }
}

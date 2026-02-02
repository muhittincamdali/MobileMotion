import Foundation
import QuartzCore

/// Simulates gravity with optional floor bounce.
///
/// Objects accelerate downward at the configured gravity rate and
/// bounce off a floor boundary with energy loss controlled by restitution.
public final class GravityAnimation {

    // MARK: - Configuration

    /// Gravitational acceleration in points per second squared.
    public var gravity: Double

    /// Energy retention on bounce (0 = no bounce, 1 = perfect elastic).
    public var restitution: Double

    /// Y-coordinate of the collision boundary.
    public var floorY: Double

    /// Minimum velocity to keep bouncing. Below this, the object settles.
    public var restThreshold: Double

    /// Maximum bounces before forced settlement.
    public var maxBounces: Int

    // MARK: - State

    /// Current vertical position.
    public private(set) var currentValue: Double = 0.0

    /// Current vertical velocity in points per second.
    public private(set) var velocity: Double = 0.0

    /// Whether the simulation is running.
    public private(set) var isAnimating: Bool = false

    /// Number of bounces that have occurred.
    public private(set) var bounceCount: Int = 0

    // MARK: - Callbacks

    /// Called each frame with current position.
    public var onUpdate: ((Double) -> Void)?

    /// Called when a bounce occurs, with the bounce velocity magnitude.
    public var onBounce: ((Double) -> Void)?

    /// Called when the object comes to rest on the floor.
    public var onCompletion: (() -> Void)?

    // MARK: - Private

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0.0

    // MARK: - Initialization

    /// Creates a gravity animation.
    ///
    /// - Parameters:
    ///   - gravity: Acceleration in points/s². Default `980.0` (screen-scaled g).
    ///   - restitution: Bounce coefficient. Default `0.7`.
    ///   - floorY: Collision boundary Y. Default `600.0`.
    ///   - restThreshold: Minimum bounce velocity. Default `5.0`.
    ///   - maxBounces: Maximum allowed bounces. Default `20`.
    public init(
        gravity: Double = 980.0,
        restitution: Double = 0.7,
        floorY: Double = 600.0,
        restThreshold: Double = 5.0,
        maxBounces: Int = 20
    ) {
        self.gravity = gravity
        self.restitution = restitution
        self.floorY = floorY
        self.restThreshold = restThreshold
        self.maxBounces = maxBounces
    }

    // MARK: - Public API

    /// Starts the gravity simulation from a position with optional initial velocity.
    ///
    /// - Parameters:
    ///   - from: Starting Y position.
    ///   - initialVelocity: Starting velocity (positive = downward). Default `0.0`.
    ///   - update: Frame callback with current position.
    ///   - completion: Called when the object settles.
    public func animate(
        from: Double,
        initialVelocity: Double = 0.0,
        update: ((Double) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        stop()

        currentValue = from
        velocity = initialVelocity
        bounceCount = 0
        isAnimating = true

        if let update = update { onUpdate = update }
        if let completion = completion { onCompletion = completion }

        lastTimestamp = 0.0
        startDisplayLink()
    }

    /// Stops the simulation at its current position.
    public func stop() {
        isAnimating = false
        stopDisplayLink()
    }

    /// Advances the simulation by the given time step.
    ///
    /// - Parameter dt: Time delta in seconds.
    /// - Returns: Updated position.
    @discardableResult
    public func step(dt: Double) -> Double {
        let clampedDt = min(dt, 1.0 / 30.0)

        // Apply gravity: v = v + g * dt
        velocity += gravity * clampedDt

        // Update position: x = x + v * dt
        currentValue += velocity * clampedDt

        // Floor collision check
        if currentValue >= floorY {
            currentValue = floorY
            velocity = -velocity * restitution
            bounceCount += 1
            onBounce?(abs(velocity))

            // Check if we should settle
            if abs(velocity) < restThreshold || bounceCount >= maxBounces {
                currentValue = floorY
                velocity = 0.0
                return currentValue
            }
        }

        return currentValue
    }

    /// Whether the object has settled on the floor.
    public func isAtRest() -> Bool {
        return currentValue >= floorY - 0.1 && abs(velocity) < restThreshold
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
            currentValue = floorY
            velocity = 0.0
            isAnimating = false
            stopDisplayLink()
            onUpdate?(currentValue)
            onCompletion?()
        }
    }
}

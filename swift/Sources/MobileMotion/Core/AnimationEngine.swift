import Foundation
import QuartzCore

/// Protocol that all physics animations conform to.
public protocol PhysicsAnimatable: AnyObject {
    var currentValue: Double { get }
    var velocity: Double { get }
    var isAnimating: Bool { get }

    func step(dt: Double) -> Double
    func isAtRest() -> Bool
    func stop()
}

extension SpringAnimation: PhysicsAnimatable {}
extension GravityAnimation: PhysicsAnimatable {}
extension FrictionAnimation: PhysicsAnimatable {}

/// Tracks a single running animation and its callbacks.
public struct AnimationEntry {
    let id: String
    let animation: PhysicsAnimatable
    let onUpdate: (Double) -> Void
    let onCompletion: (() -> Void)?

    public init(
        id: String,
        animation: PhysicsAnimatable,
        onUpdate: @escaping (Double) -> Void,
        onCompletion: (() -> Void)? = nil
    ) {
        self.id = id
        self.animation = animation
        self.onUpdate = onUpdate
        self.onCompletion = onCompletion
    }
}

/// Central engine that drives multiple physics animations from a single `CADisplayLink`.
///
/// Instead of each animation creating its own display link (which is wasteful),
/// the engine batches all active animations into one tick loop. This reduces
/// overhead and keeps all animations perfectly synchronized.
///
/// ```swift
/// let engine = AnimationEngine()
///
/// let spring = SpringAnimation(stiffness: 200, damping: 15)
/// engine.run(spring, from: 0, to: 300) { value in
///     myView.center.x = value
/// }
/// ```
public final class AnimationEngine {

    // MARK: - Properties

    /// All currently active animation entries.
    private var entries: [AnimationEntry] = []

    /// The shared display link driving all animations.
    private var displayLink: CADisplayLink?

    /// Timestamp of the previous frame.
    private var lastTimestamp: CFTimeInterval = 0.0

    /// Whether the engine is currently ticking.
    public private(set) var isRunning: Bool = false

    /// Number of active animations.
    public var activeCount: Int { entries.count }

    /// Maximum time step to prevent instability after frame drops.
    public var maxDeltaTime: Double = 1.0 / 30.0

    /// Called whenever the engine starts or stops.
    public var onRunningStateChanged: ((Bool) -> Void)?

    /// Auto-generated ID counter.
    private var nextId: Int = 0

    // MARK: - Initialization

    public init() {}

    deinit {
        stopAll()
    }

    // MARK: - Running Springs

    /// Runs a spring animation from one value to another.
    ///
    /// - Parameters:
    ///   - spring: The spring configuration to use.
    ///   - from: Starting value.
    ///   - to: Target value.
    ///   - initialVelocity: Starting velocity. Default `0`.
    ///   - update: Called each frame with the interpolated value.
    ///   - completion: Called when the spring settles.
    /// - Returns: An animation ID you can use to cancel it later.
    @discardableResult
    public func run(
        _ spring: SpringAnimation,
        from: Double,
        to: Double,
        initialVelocity: Double = 0.0,
        update: @escaping (Double) -> Void,
        completion: (() -> Void)? = nil
    ) -> String {
        // Configure the spring directly without its own display link
        spring.stop()
        spring.currentValue = from
        spring.velocity = initialVelocity
        spring.targetValue = to
        spring.fromValue = from
        spring.isAnimating = true

        let id = generateId()
        let entry = AnimationEntry(
            id: id,
            animation: spring,
            onUpdate: update,
            onCompletion: completion
        )

        entries.append(entry)
        ensureRunning()

        return id
    }

    /// Runs a gravity animation from a starting position.
    @discardableResult
    public func run(
        _ gravity: GravityAnimation,
        from: Double,
        velocity: Double = 0.0,
        update: @escaping (Double) -> Void,
        completion: (() -> Void)? = nil
    ) -> String {
        gravity.stop()
        gravity.currentValue = from
        gravity.velocity = velocity
        gravity.bounceCount = 0
        gravity.isAnimating = true

        let id = generateId()
        let entry = AnimationEntry(
            id: id,
            animation: gravity,
            onUpdate: update,
            onCompletion: completion
        )

        entries.append(entry)
        ensureRunning()

        return id
    }

    /// Runs a friction animation from a starting position and velocity.
    @discardableResult
    public func run(
        _ friction: FrictionAnimation,
        from: Double,
        velocity: Double,
        update: @escaping (Double) -> Void,
        completion: (() -> Void)? = nil
    ) -> String {
        friction.stop()
        friction.currentValue = from
        friction.velocity = velocity
        friction.isAnimating = true

        let id = generateId()
        let entry = AnimationEntry(
            id: id,
            animation: friction,
            onUpdate: update,
            onCompletion: completion
        )

        entries.append(entry)
        ensureRunning()

        return id
    }

    // MARK: - Control

    /// Cancels a specific animation by its ID.
    public func cancel(id: String) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].animation.stop()
            entries.remove(at: index)
        }
        stopIfEmpty()
    }

    /// Stops all running animations.
    public func stopAll() {
        for entry in entries {
            entry.animation.stop()
        }
        entries.removeAll()
        stopDisplayLink()
    }

    // MARK: - Private

    private func generateId() -> String {
        nextId += 1
        return "motion_\(nextId)"
    }

    private func ensureRunning() {
        guard !isRunning else { return }
        isRunning = true
        lastTimestamp = 0.0

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link

        onRunningStateChanged?(true)
    }

    private func stopIfEmpty() {
        if entries.isEmpty {
            stopDisplayLink()
        }
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        onRunningStateChanged?(false)
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let dt = min(link.timestamp - lastTimestamp, maxDeltaTime)
        lastTimestamp = link.timestamp

        var completedIndices: [Int] = []

        for (index, entry) in entries.enumerated() {
            let value = entry.animation.step(dt: dt)
            entry.onUpdate(value)

            if entry.animation.isAtRest() {
                completedIndices.append(index)
            }
        }

        // Remove completed in reverse to preserve indices
        for index in completedIndices.reversed() {
            let entry = entries[index]
            entry.animation.stop()
            entry.onUpdate(entry.animation.currentValue)
            entry.onCompletion?()
            entries.remove(at: index)
        }

        stopIfEmpty()
    }
}

// MARK: - Internal property access for engine

extension SpringAnimation {
    var currentValue_: Double {
        get { currentValue }
        set { /* accessible via engine */ }
    }
}

// MARK: - Convenience extensions

extension AnimationEngine {

    /// Runs a spring with a preset configuration.
    @discardableResult
    public func springTo(
        _ target: Double,
        from: Double,
        preset: SpringAnimation = .snappy,
        update: @escaping (Double) -> Void,
        completion: (() -> Void)? = nil
    ) -> String {
        return run(preset, from: from, to: target, update: update, completion: completion)
    }
}

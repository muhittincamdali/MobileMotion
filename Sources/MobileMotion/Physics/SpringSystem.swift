//
//  SpringSystem.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - Spring Value Type

/// A type that can be animated with spring physics
public protocol SpringAnimatable {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: CGFloat) -> Self
    static func / (lhs: Self, rhs: CGFloat) -> Self
    
    /// Calculate the magnitude/length of the value
    var magnitude: CGFloat { get }
    
    /// Zero value
    static var zero: Self { get }
}

// MARK: - SpringAnimatable Conformances

extension CGFloat: SpringAnimatable {
    public var magnitude: CGFloat { abs(self) }
}

extension CGPoint: SpringAnimatable {
    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    public static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    public var magnitude: CGFloat {
        sqrt(x * x + y * y)
    }
}

extension CGSize: SpringAnimatable {
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
    
    public var magnitude: CGFloat {
        sqrt(width * width + height * height)
    }
}

extension CGRect: SpringAnimatable {
    public static func + (lhs: CGRect, rhs: CGRect) -> CGRect {
        CGRect(
            x: lhs.origin.x + rhs.origin.x,
            y: lhs.origin.y + rhs.origin.y,
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
    
    public static func - (lhs: CGRect, rhs: CGRect) -> CGRect {
        CGRect(
            x: lhs.origin.x - rhs.origin.x,
            y: lhs.origin.y - rhs.origin.y,
            width: lhs.width - rhs.width,
            height: lhs.height - rhs.height
        )
    }
    
    public static func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
        CGRect(
            x: lhs.origin.x * rhs,
            y: lhs.origin.y * rhs,
            width: lhs.width * rhs,
            height: lhs.height * rhs
        )
    }
    
    public static func / (lhs: CGRect, rhs: CGFloat) -> CGRect {
        CGRect(
            x: lhs.origin.x / rhs,
            y: lhs.origin.y / rhs,
            width: lhs.width / rhs,
            height: lhs.height / rhs
        )
    }
    
    public var magnitude: CGFloat {
        sqrt(origin.x * origin.x + origin.y * origin.y + width * width + height * height)
    }
}

// MARK: - Spring Parameters

/// Parameters that define spring behavior
public struct SpringParameters: Sendable {
    /// Stiffness coefficient (k) - how "tight" the spring is
    public var stiffness: CGFloat
    
    /// Damping coefficient (c) - how quickly oscillations decay
    public var damping: CGFloat
    
    /// Mass (m) - affects oscillation frequency
    public var mass: CGFloat
    
    /// Velocity threshold below which animation stops
    public var restVelocityThreshold: CGFloat
    
    /// Displacement threshold below which animation stops
    public var restDisplacementThreshold: CGFloat
    
    /// Calculate damping ratio (ζ)
    public var dampingRatio: CGFloat {
        damping / (2 * sqrt(stiffness * mass))
    }
    
    /// Calculate natural frequency (ω₀)
    public var naturalFrequency: CGFloat {
        sqrt(stiffness / mass)
    }
    
    /// Calculate damped frequency (ωd)
    public var dampedFrequency: CGFloat {
        let ratio = dampingRatio
        if ratio >= 1 { return 0 } // Overdamped or critically damped
        return naturalFrequency * sqrt(1 - ratio * ratio)
    }
    
    /// Whether the spring is underdamped (will oscillate)
    public var isUnderdamped: Bool { dampingRatio < 1 }
    
    /// Whether the spring is critically damped
    public var isCriticallyDamped: Bool { abs(dampingRatio - 1) < 0.001 }
    
    /// Whether the spring is overdamped
    public var isOverdamped: Bool { dampingRatio > 1 }
    
    /// Default spring parameters
    public static let `default` = SpringParameters(
        stiffness: 300,
        damping: 20,
        mass: 1,
        restVelocityThreshold: 0.001,
        restDisplacementThreshold: 0.001
    )
    
    /// Bouncy spring
    public static let bouncy = SpringParameters(
        stiffness: 400,
        damping: 10,
        mass: 1,
        restVelocityThreshold: 0.001,
        restDisplacementThreshold: 0.001
    )
    
    /// Smooth spring (critically damped)
    public static let smooth = SpringParameters(
        stiffness: 300,
        damping: 34.64, // 2 * sqrt(300 * 1)
        mass: 1,
        restVelocityThreshold: 0.001,
        restDisplacementThreshold: 0.001
    )
    
    /// Stiff spring
    public static let stiff = SpringParameters(
        stiffness: 600,
        damping: 30,
        mass: 1,
        restVelocityThreshold: 0.001,
        restDisplacementThreshold: 0.001
    )
    
    /// Slow spring
    public static let slow = SpringParameters(
        stiffness: 100,
        damping: 15,
        mass: 1,
        restVelocityThreshold: 0.001,
        restDisplacementThreshold: 0.001
    )
    
    /// Create spring with response and damping ratio
    public static func withResponse(_ response: CGFloat, dampingRatio: CGFloat) -> SpringParameters {
        let stiffness = pow(2 * .pi / response, 2)
        let damping = 4 * .pi * dampingRatio / response
        return SpringParameters(
            stiffness: stiffness,
            damping: damping,
            mass: 1,
            restVelocityThreshold: 0.001,
            restDisplacementThreshold: 0.001
        )
    }
    
    public init(
        stiffness: CGFloat = 300,
        damping: CGFloat = 20,
        mass: CGFloat = 1,
        restVelocityThreshold: CGFloat = 0.001,
        restDisplacementThreshold: CGFloat = 0.001
    ) {
        self.stiffness = max(0.01, stiffness)
        self.damping = max(0, damping)
        self.mass = max(0.01, mass)
        self.restVelocityThreshold = restVelocityThreshold
        self.restDisplacementThreshold = restDisplacementThreshold
    }
}

// MARK: - Spring State

/// Represents the current state of a spring
public struct SpringState<Value: SpringAnimatable>: Sendable where Value: Sendable {
    /// Current value
    public var value: Value
    
    /// Current velocity
    public var velocity: Value
    
    /// Target value
    public var target: Value
    
    /// Whether the spring is at rest
    public var isAtRest: Bool
    
    public init(value: Value, velocity: Value = .zero, target: Value, isAtRest: Bool = false) {
        self.value = value
        self.velocity = velocity
        self.target = target
        self.isAtRest = isAtRest
    }
}

// MARK: - Spring Solver

/// Solves spring differential equations
public final class SpringSolver<Value: SpringAnimatable> {
    
    // MARK: - Properties
    
    private let parameters: SpringParameters
    
    // MARK: - Initialization
    
    public init(parameters: SpringParameters) {
        self.parameters = parameters
    }
    
    // MARK: - Solving
    
    /// Advance the spring by a time step using RK4 integration
    public func solve(
        current: Value,
        velocity: Value,
        target: Value,
        deltaTime: CGFloat
    ) -> (value: Value, velocity: Value) {
        // Use Runge-Kutta 4th order integration for accuracy
        let k1v = velocity
        let k1a = acceleration(position: current, velocity: velocity, target: target)
        
        let k2v = velocity + k1a * (deltaTime / 2)
        let k2a = acceleration(
            position: current + k1v * (deltaTime / 2),
            velocity: k2v,
            target: target
        )
        
        let k3v = velocity + k2a * (deltaTime / 2)
        let k3a = acceleration(
            position: current + k2v * (deltaTime / 2),
            velocity: k3v,
            target: target
        )
        
        let k4v = velocity + k3a * deltaTime
        let k4a = acceleration(
            position: current + k3v * deltaTime,
            velocity: k4v,
            target: target
        )
        
        let newValue = current + (k1v + k2v * 2 + k3v * 2 + k4v) * (deltaTime / 6)
        let newVelocity = velocity + (k1a + k2a * 2 + k3a * 2 + k4a) * (deltaTime / 6)
        
        return (newValue, newVelocity)
    }
    
    /// Calculate acceleration for given position and velocity
    private func acceleration(position: Value, velocity: Value, target: Value) -> Value {
        let displacement = position - target
        
        // F = -kx - cv (spring force + damping force)
        // a = F/m
        let springForce = displacement * (-parameters.stiffness)
        let dampingForce = velocity * (-parameters.damping)
        let totalForce = springForce + dampingForce
        
        return totalForce / parameters.mass
    }
    
    /// Check if the spring is at rest
    public func isAtRest(value: Value, velocity: Value, target: Value) -> Bool {
        let displacement = value - target
        return displacement.magnitude < parameters.restDisplacementThreshold &&
               velocity.magnitude < parameters.restVelocityThreshold
    }
    
    /// Estimate settling time
    public func estimatedSettlingTime(from current: Value, to target: Value) -> TimeInterval {
        let displacement = (current - target).magnitude
        if displacement < parameters.restDisplacementThreshold {
            return 0
        }
        
        let dampingRatio = parameters.dampingRatio
        let naturalFrequency = parameters.naturalFrequency
        
        if dampingRatio >= 1 {
            // Overdamped or critically damped - approximate
            return TimeInterval(4 / (dampingRatio * naturalFrequency))
        } else {
            // Underdamped - use envelope decay
            let decayRate = dampingRatio * naturalFrequency
            let settleRatio = parameters.restDisplacementThreshold / displacement
            return TimeInterval(-log(settleRatio) / decayRate)
        }
    }
}

// MARK: - Spring Animation

/// A single spring animation
public final class Spring<Value: SpringAnimatable> where Value: Sendable {
    
    // MARK: - Properties
    
    private let solver: SpringSolver<Value>
    private var state: SpringState<Value>
    private let parameters: SpringParameters
    
    /// Current value
    public var value: Value { state.value }
    
    /// Current velocity
    public var velocity: Value { state.velocity }
    
    /// Target value
    public var target: Value {
        get { state.target }
        set {
            state.target = newValue
            state.isAtRest = false
        }
    }
    
    /// Whether the spring is at rest
    public var isAtRest: Bool { state.isAtRest }
    
    /// Value change callback
    public var onChange: ((Value) -> Void)?
    
    /// Rest callback
    public var onRest: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        initialValue: Value,
        target: Value? = nil,
        parameters: SpringParameters = .default
    ) {
        self.parameters = parameters
        self.solver = SpringSolver(parameters: parameters)
        self.state = SpringState(
            value: initialValue,
            velocity: .zero,
            target: target ?? initialValue,
            isAtRest: target == nil
        )
    }
    
    // MARK: - Control
    
    /// Update the spring with elapsed time
    public func update(deltaTime: TimeInterval) {
        guard !state.isAtRest else { return }
        
        let dt = CGFloat(deltaTime)
        let result = solver.solve(
            current: state.value,
            velocity: state.velocity,
            target: state.target,
            deltaTime: dt
        )
        
        state.value = result.value
        state.velocity = result.velocity
        
        onChange?(state.value)
        
        if solver.isAtRest(value: state.value, velocity: state.velocity, target: state.target) {
            state.value = state.target
            state.velocity = .zero
            state.isAtRest = true
            onRest?()
        }
    }
    
    /// Set value immediately (stops animation)
    public func setValue(_ newValue: Value) {
        state.value = newValue
        state.velocity = .zero
        state.isAtRest = true
        onChange?(newValue)
    }
    
    /// Add velocity impulse
    public func addVelocity(_ impulse: Value) {
        state.velocity = state.velocity + impulse
        state.isAtRest = false
    }
    
    /// Reset to initial state
    public func reset(to value: Value) {
        state.value = value
        state.velocity = .zero
        state.target = value
        state.isAtRest = true
    }
    
    /// Estimated time to settle
    public var estimatedSettlingTime: TimeInterval {
        solver.estimatedSettlingTime(from: state.value, to: state.target)
    }
}

// MARK: - Spring System

/// Manages multiple spring animations
public final class SpringSystem {
    
    // MARK: - Properties
    
    private var springs: [String: Any] = [:]
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false
    
    /// Callback when any spring updates
    public var onUpdate: (() -> Void)?
    
    /// Whether the system has active springs
    public var hasActiveSprings: Bool {
        !springs.isEmpty
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Spring Management
    
    /// Add a spring to the system
    public func addSpring<Value: SpringAnimatable>(
        _ spring: Spring<Value>,
        forKey key: String
    ) where Value: Sendable {
        springs[key] = spring
        startIfNeeded()
    }
    
    /// Get a spring by key
    public func spring<Value: SpringAnimatable>(forKey key: String) -> Spring<Value>? {
        return springs[key] as? Spring<Value>
    }
    
    /// Remove a spring
    public func removeSpring(forKey key: String) {
        springs.removeValue(forKey: key)
        stopIfEmpty()
    }
    
    /// Remove all springs
    public func removeAllSprings() {
        springs.removeAll()
        stop()
    }
    
    // MARK: - Control
    
    /// Start the system
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        lastUpdateTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Stop the system
    public func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// Pause the system
    public func pause() {
        displayLink?.isPaused = true
    }
    
    /// Resume the system
    public func resume() {
        lastUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    // MARK: - Private
    
    private func startIfNeeded() {
        if !isRunning && !springs.isEmpty {
            start()
        }
    }
    
    private func stopIfEmpty() {
        if springs.isEmpty {
            stop()
        }
    }
    
    @objc private func update(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update all springs
        var keysToRemove: [String] = []
        
        for (key, springAny) in springs {
            if let spring = springAny as? Spring<CGFloat> {
                spring.update(deltaTime: deltaTime)
                if spring.isAtRest { keysToRemove.append(key) }
            } else if let spring = springAny as? Spring<CGPoint> {
                spring.update(deltaTime: deltaTime)
                if spring.isAtRest { keysToRemove.append(key) }
            } else if let spring = springAny as? Spring<CGSize> {
                spring.update(deltaTime: deltaTime)
                if spring.isAtRest { keysToRemove.append(key) }
            } else if let spring = springAny as? Spring<CGRect> {
                spring.update(deltaTime: deltaTime)
                if spring.isAtRest { keysToRemove.append(key) }
            }
        }
        
        // Remove completed springs
        for key in keysToRemove {
            springs.removeValue(forKey: key)
        }
        
        onUpdate?()
        
        // Stop if no active springs
        if springs.isEmpty {
            stop()
        }
    }
}

// MARK: - Spring Chain

/// Chains multiple values with spring physics
public final class SpringChain<Value: SpringAnimatable> where Value: Sendable {
    
    // MARK: - Properties
    
    private var springs: [Spring<Value>]
    private let coupling: CGFloat
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false
    
    /// Current values
    public var values: [Value] {
        springs.map { $0.value }
    }
    
    /// First spring's target
    public var target: Value {
        get { springs.first?.target ?? .zero }
        set { springs.first?.target = newValue }
    }
    
    /// Value update callback
    public var onChange: (([Value]) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        count: Int,
        initialValue: Value,
        parameters: SpringParameters = .default,
        coupling: CGFloat = 0.8
    ) {
        self.coupling = coupling
        self.springs = (0..<count).map { _ in
            Spring(initialValue: initialValue, parameters: parameters)
        }
        
        // Setup chain coupling
        for i in 1..<springs.count {
            let previousSpring = springs[i - 1]
            let currentSpring = springs[i]
            
            previousSpring.onChange = { [weak currentSpring, coupling] newValue in
                guard let current = currentSpring else { return }
                // Follower spring targets slightly behind leader
                let targetValue = newValue * coupling + current.value * (1 - coupling)
                current.target = targetValue
            }
        }
    }
    
    // MARK: - Control
    
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        lastUpdateTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    public func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        for spring in springs {
            spring.update(deltaTime: deltaTime)
        }
        
        onChange?(values)
        
        // Check if all at rest
        if springs.allSatisfy({ $0.isAtRest }) {
            stop()
        }
    }
}

// MARK: - Spring View Animator

/// Animates view properties with spring physics
public final class SpringViewAnimator {
    
    // MARK: - Properties
    
    private weak var view: UIView?
    private let system = SpringSystem()
    private var positionSpring: Spring<CGPoint>?
    private var scaleSpring: Spring<CGFloat>?
    private var rotationSpring: Spring<CGFloat>?
    private var alphaSpring: Spring<CGFloat>?
    
    // MARK: - Initialization
    
    public init(view: UIView) {
        self.view = view
        
        system.onUpdate = { [weak self] in
            self?.applyValues()
        }
    }
    
    // MARK: - Animation Methods
    
    /// Animate position with spring
    public func animatePosition(
        to target: CGPoint,
        parameters: SpringParameters = .default
    ) {
        guard let view = view else { return }
        
        let spring = Spring(
            initialValue: view.center,
            target: target,
            parameters: parameters
        )
        positionSpring = spring
        system.addSpring(spring, forKey: "position")
    }
    
    /// Animate scale with spring
    public func animateScale(
        to target: CGFloat,
        parameters: SpringParameters = .default
    ) {
        guard let view = view else { return }
        
        let currentScale = view.transform.a
        let spring = Spring(
            initialValue: currentScale,
            target: target,
            parameters: parameters
        )
        scaleSpring = spring
        system.addSpring(spring, forKey: "scale")
    }
    
    /// Animate rotation with spring
    public func animateRotation(
        to target: CGFloat,
        parameters: SpringParameters = .default
    ) {
        guard let view = view else { return }
        
        let currentRotation = atan2(view.transform.b, view.transform.a)
        let spring = Spring(
            initialValue: currentRotation,
            target: target,
            parameters: parameters
        )
        rotationSpring = spring
        system.addSpring(spring, forKey: "rotation")
    }
    
    /// Animate alpha with spring
    public func animateAlpha(
        to target: CGFloat,
        parameters: SpringParameters = .default
    ) {
        guard let view = view else { return }
        
        let spring = Spring(
            initialValue: view.alpha,
            target: target,
            parameters: parameters
        )
        alphaSpring = spring
        system.addSpring(spring, forKey: "alpha")
    }
    
    /// Add velocity impulse to position
    public func addVelocityImpulse(_ velocity: CGPoint) {
        positionSpring?.addVelocity(velocity)
    }
    
    /// Stop all animations
    public func stopAll() {
        system.removeAllSprings()
        positionSpring = nil
        scaleSpring = nil
        rotationSpring = nil
        alphaSpring = nil
    }
    
    // MARK: - Private
    
    private func applyValues() {
        guard let view = view else { return }
        
        if let spring = positionSpring {
            view.center = spring.value
        }
        
        var transform = CGAffineTransform.identity
        
        if let spring = scaleSpring {
            transform = transform.scaledBy(x: spring.value, y: spring.value)
        }
        
        if let spring = rotationSpring {
            transform = transform.rotated(by: spring.value)
        }
        
        if scaleSpring != nil || rotationSpring != nil {
            view.transform = transform
        }
        
        if let spring = alphaSpring {
            view.alpha = spring.value
        }
    }
}

// MARK: - UIView Extension

public extension UIView {
    
    /// Animate to position with spring
    func springTo(
        position: CGPoint,
        parameters: SpringParameters = .default,
        completion: (() -> Void)? = nil
    ) {
        let animator = SpringViewAnimator(view: self)
        animator.animatePosition(to: position, parameters: parameters)
    }
    
    /// Bounce with spring effect
    func springBounce(
        scale: CGFloat = 1.2,
        parameters: SpringParameters = .bouncy,
        completion: (() -> Void)? = nil
    ) {
        let animator = SpringViewAnimator(view: self)
        animator.animateScale(to: scale, parameters: parameters)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animator.animateScale(to: 1.0, parameters: parameters)
        }
    }
    
    /// Shake with spring effect
    func springShake(intensity: CGFloat = 20, parameters: SpringParameters = .stiff) {
        let animator = SpringViewAnimator(view: self)
        animator.addVelocityImpulse(CGPoint(x: intensity * 50, y: 0))
        animator.animatePosition(to: center, parameters: parameters)
    }
}

//
//  GravitySystem.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import QuartzCore
import CoreMotion

// MARK: - Gravity Direction

/// Predefined gravity directions
public enum GravityDirection: CaseIterable, Sendable {
    case down
    case up
    case left
    case right
    case custom(CGVector)
    
    /// The gravity vector
    public var vector: CGVector {
        switch self {
        case .down: return CGVector(dx: 0, dy: 980)
        case .up: return CGVector(dx: 0, dy: -980)
        case .left: return CGVector(dx: -980, dy: 0)
        case .right: return CGVector(dx: 980, dy: 0)
        case .custom(let v): return v
        }
    }
    
    public static var allCases: [GravityDirection] {
        [.down, .up, .left, .right]
    }
}

// MARK: - Physics Body

/// Represents a physics-enabled body in the system
public final class PhysicsBody: Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    
    /// Current position (center point)
    public var position: CGPoint
    
    /// Current velocity
    public var velocity: CGVector
    
    /// Body bounds
    public var bounds: CGRect
    
    /// Mass of the body (affects gravity response)
    public var mass: CGFloat
    
    /// Elasticity for collisions (0 = no bounce, 1 = perfect bounce)
    public var elasticity: CGFloat
    
    /// Friction coefficient (0 = no friction, 1 = maximum)
    public var friction: CGFloat
    
    /// Whether the body is affected by gravity
    public var affectedByGravity: Bool
    
    /// Whether the body is static (doesn't move)
    public var isStatic: Bool
    
    /// Angular velocity (radians per second)
    public var angularVelocity: CGFloat
    
    /// Current rotation angle
    public var rotation: CGFloat
    
    /// Air resistance (drag)
    public var drag: CGFloat
    
    /// Associated view (weak reference)
    public weak var view: UIView?
    
    /// Custom user data
    public var userData: [String: Any] = [:]
    
    // MARK: - Initialization
    
    public init(
        position: CGPoint,
        bounds: CGRect,
        mass: CGFloat = 1.0,
        elasticity: CGFloat = 0.5,
        friction: CGFloat = 0.3,
        affectedByGravity: Bool = true,
        isStatic: Bool = false
    ) {
        self.id = UUID()
        self.position = position
        self.velocity = .zero
        self.bounds = bounds
        self.mass = max(0.01, mass)
        self.elasticity = max(0, min(1, elasticity))
        self.friction = max(0, min(1, friction))
        self.affectedByGravity = affectedByGravity
        self.isStatic = isStatic
        self.angularVelocity = 0
        self.rotation = 0
        self.drag = 0.01
    }
    
    /// Convenience initializer from view
    public convenience init(view: UIView, mass: CGFloat = 1.0) {
        self.init(
            position: view.center,
            bounds: view.bounds,
            mass: mass
        )
        self.view = view
    }
    
    // MARK: - Physics
    
    /// Apply a force to the body
    public func applyForce(_ force: CGVector) {
        guard !isStatic else { return }
        
        // F = ma, so a = F/m
        let acceleration = CGVector(
            dx: force.dx / mass,
            dy: force.dy / mass
        )
        
        velocity.dx += acceleration.dx
        velocity.dy += acceleration.dy
    }
    
    /// Apply an impulse (instant velocity change)
    public func applyImpulse(_ impulse: CGVector) {
        guard !isStatic else { return }
        
        velocity.dx += impulse.dx / mass
        velocity.dy += impulse.dy / mass
    }
    
    /// Apply torque (rotational force)
    public func applyTorque(_ torque: CGFloat) {
        guard !isStatic else { return }
        angularVelocity += torque / mass
    }
    
    /// Get the frame in world coordinates
    public var frame: CGRect {
        CGRect(
            x: position.x - bounds.width / 2,
            y: position.y - bounds.height / 2,
            width: bounds.width,
            height: bounds.height
        )
    }
    
    /// Kinetic energy
    public var kineticEnergy: CGFloat {
        let linearKE = 0.5 * mass * (velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        let angularKE = 0.5 * mass * bounds.width * bounds.width / 12 * angularVelocity * angularVelocity
        return linearKE + angularKE
    }
    
    /// Speed (magnitude of velocity)
    public var speed: CGFloat {
        sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
    }
}

// MARK: - Collision Info

/// Information about a collision between two bodies
public struct CollisionInfo {
    /// First body involved
    public let bodyA: PhysicsBody
    
    /// Second body involved
    public let bodyB: PhysicsBody
    
    /// Contact point
    public let contactPoint: CGPoint
    
    /// Normal vector (from A to B)
    public let normal: CGVector
    
    /// Penetration depth
    public let penetration: CGFloat
    
    /// Relative velocity at contact
    public let relativeVelocity: CGVector
}

// MARK: - Boundary

/// Represents a boundary in the physics world
public struct PhysicsBoundary {
    /// Boundary type
    public enum BoundaryType {
        case rect(CGRect)
        case circle(center: CGPoint, radius: CGFloat)
        case line(from: CGPoint, to: CGPoint)
    }
    
    public let type: BoundaryType
    public let elasticity: CGFloat
    public let friction: CGFloat
    
    public init(type: BoundaryType, elasticity: CGFloat = 0.5, friction: CGFloat = 0.3) {
        self.type = type
        self.elasticity = elasticity
        self.friction = friction
    }
    
    /// Create a boundary from view bounds (inside)
    public static func inside(_ rect: CGRect, elasticity: CGFloat = 0.5, friction: CGFloat = 0.3) -> PhysicsBoundary {
        PhysicsBoundary(type: .rect(rect), elasticity: elasticity, friction: friction)
    }
}

// MARK: - Gravity Configuration

/// Configuration for the gravity system
public struct GravityConfiguration {
    /// Gravity direction and strength
    public var gravity: GravityDirection
    
    /// Global damping applied to all bodies
    public var globalDamping: CGFloat
    
    /// Maximum velocity (to prevent instability)
    public var maxVelocity: CGFloat
    
    /// Time step for physics simulation
    public var timeStep: CGFloat
    
    /// Use device motion for gravity direction
    public var useDeviceMotion: Bool
    
    /// Device motion sensitivity
    public var deviceMotionSensitivity: CGFloat
    
    /// Enable collision detection
    public var enableCollisions: Bool
    
    /// Default configuration
    public static let `default` = GravityConfiguration(
        gravity: .down,
        globalDamping: 0.99,
        maxVelocity: 2000,
        timeStep: 1/60,
        useDeviceMotion: false,
        deviceMotionSensitivity: 1.0,
        enableCollisions: true
    )
    
    /// Zero gravity (space-like)
    public static let zeroGravity = GravityConfiguration(
        gravity: .custom(.zero),
        globalDamping: 0.995,
        maxVelocity: 1000,
        timeStep: 1/60,
        useDeviceMotion: false,
        deviceMotionSensitivity: 1.0,
        enableCollisions: true
    )
    
    /// Device motion controlled
    public static let deviceControlled = GravityConfiguration(
        gravity: .down,
        globalDamping: 0.98,
        maxVelocity: 1500,
        timeStep: 1/60,
        useDeviceMotion: true,
        deviceMotionSensitivity: 1.5,
        enableCollisions: true
    )
    
    public init(
        gravity: GravityDirection = .down,
        globalDamping: CGFloat = 0.99,
        maxVelocity: CGFloat = 2000,
        timeStep: CGFloat = 1/60,
        useDeviceMotion: Bool = false,
        deviceMotionSensitivity: CGFloat = 1.0,
        enableCollisions: Bool = true
    ) {
        self.gravity = gravity
        self.globalDamping = globalDamping
        self.maxVelocity = maxVelocity
        self.timeStep = timeStep
        self.useDeviceMotion = useDeviceMotion
        self.deviceMotionSensitivity = deviceMotionSensitivity
        self.enableCollisions = enableCollisions
    }
}

// MARK: - Collision Detector

/// Handles collision detection between bodies
public final class CollisionDetector {
    
    /// Detect collision between two bodies
    public func detectCollision(bodyA: PhysicsBody, bodyB: PhysicsBody) -> CollisionInfo? {
        let frameA = bodyA.frame
        let frameB = bodyB.frame
        
        // Simple AABB collision
        guard frameA.intersects(frameB) else { return nil }
        
        // Calculate overlap
        let overlapX = min(frameA.maxX - frameB.minX, frameB.maxX - frameA.minX)
        let overlapY = min(frameA.maxY - frameB.minY, frameB.maxY - frameA.minY)
        
        let normal: CGVector
        let penetration: CGFloat
        
        if overlapX < overlapY {
            penetration = overlapX
            normal = bodyA.position.x < bodyB.position.x
                ? CGVector(dx: -1, dy: 0)
                : CGVector(dx: 1, dy: 0)
        } else {
            penetration = overlapY
            normal = bodyA.position.y < bodyB.position.y
                ? CGVector(dx: 0, dy: -1)
                : CGVector(dx: 0, dy: 1)
        }
        
        let contactPoint = CGPoint(
            x: (frameA.midX + frameB.midX) / 2,
            y: (frameA.midY + frameB.midY) / 2
        )
        
        let relativeVelocity = CGVector(
            dx: bodyB.velocity.dx - bodyA.velocity.dx,
            dy: bodyB.velocity.dy - bodyA.velocity.dy
        )
        
        return CollisionInfo(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            normal: normal,
            penetration: penetration,
            relativeVelocity: relativeVelocity
        )
    }
    
    /// Detect collision with boundary
    public func detectBoundaryCollision(body: PhysicsBody, boundary: PhysicsBoundary) -> (normal: CGVector, penetration: CGFloat)? {
        let frame = body.frame
        
        switch boundary.type {
        case .rect(let rect):
            return detectRectBoundaryCollision(frame: frame, boundary: rect)
            
        case .circle(let center, let radius):
            return detectCircleBoundaryCollision(body: body, center: center, radius: radius)
            
        case .line(let from, let to):
            return detectLineBoundaryCollision(body: body, from: from, to: to)
        }
    }
    
    private func detectRectBoundaryCollision(frame: CGRect, boundary: CGRect) -> (normal: CGVector, penetration: CGFloat)? {
        var normal: CGVector?
        var penetration: CGFloat = 0
        
        // Check all four walls
        if frame.minX < boundary.minX {
            normal = CGVector(dx: 1, dy: 0)
            penetration = boundary.minX - frame.minX
        } else if frame.maxX > boundary.maxX {
            normal = CGVector(dx: -1, dy: 0)
            penetration = frame.maxX - boundary.maxX
        }
        
        if frame.minY < boundary.minY {
            if penetration == 0 || boundary.minY - frame.minY > penetration {
                normal = CGVector(dx: 0, dy: 1)
                penetration = boundary.minY - frame.minY
            }
        } else if frame.maxY > boundary.maxY {
            if penetration == 0 || frame.maxY - boundary.maxY > penetration {
                normal = CGVector(dx: 0, dy: -1)
                penetration = frame.maxY - boundary.maxY
            }
        }
        
        if let n = normal {
            return (n, penetration)
        }
        return nil
    }
    
    private func detectCircleBoundaryCollision(body: PhysicsBody, center: CGPoint, radius: CGFloat) -> (normal: CGVector, penetration: CGFloat)? {
        let dx = body.position.x - center.x
        let dy = body.position.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let bodyRadius = max(body.bounds.width, body.bounds.height) / 2
        
        if distance + bodyRadius > radius {
            let normal = CGVector(dx: -dx / distance, dy: -dy / distance)
            let penetration = distance + bodyRadius - radius
            return (normal, penetration)
        }
        return nil
    }
    
    private func detectLineBoundaryCollision(body: PhysicsBody, from: CGPoint, to: CGPoint) -> (normal: CGVector, penetration: CGFloat)? {
        // Line collision - simplified for horizontal/vertical lines
        let lineVector = CGVector(dx: to.x - from.x, dy: to.y - from.y)
        let lineLength = sqrt(lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy)
        
        // Normal perpendicular to line
        let normal = CGVector(dx: -lineVector.dy / lineLength, dy: lineVector.dx / lineLength)
        
        // Distance from body to line
        let toBody = CGVector(dx: body.position.x - from.x, dy: body.position.y - from.y)
        let distance = toBody.dx * normal.dx + toBody.dy * normal.dy
        
        let bodyRadius = max(body.bounds.width, body.bounds.height) / 2
        
        if abs(distance) < bodyRadius {
            return (normal, bodyRadius - abs(distance))
        }
        return nil
    }
}

// MARK: - Collision Resolver

/// Resolves collisions by applying impulses
public final class CollisionResolver {
    
    /// Resolve collision between two bodies
    public func resolve(_ collision: CollisionInfo) {
        let bodyA = collision.bodyA
        let bodyB = collision.bodyB
        
        // Skip if both are static
        if bodyA.isStatic && bodyB.isStatic { return }
        
        // Calculate relative velocity along normal
        let relVelNormal = collision.relativeVelocity.dx * collision.normal.dx +
                          collision.relativeVelocity.dy * collision.normal.dy
        
        // Don't resolve if separating
        if relVelNormal > 0 { return }
        
        // Calculate restitution (bounciness)
        let restitution = min(bodyA.elasticity, bodyB.elasticity)
        
        // Calculate impulse magnitude
        let invMassA = bodyA.isStatic ? 0 : 1 / bodyA.mass
        let invMassB = bodyB.isStatic ? 0 : 1 / bodyB.mass
        
        var impulseMagnitude = -(1 + restitution) * relVelNormal
        impulseMagnitude /= invMassA + invMassB
        
        // Apply impulse
        let impulse = CGVector(
            dx: impulseMagnitude * collision.normal.dx,
            dy: impulseMagnitude * collision.normal.dy
        )
        
        if !bodyA.isStatic {
            bodyA.velocity.dx -= impulse.dx * invMassA
            bodyA.velocity.dy -= impulse.dy * invMassA
        }
        
        if !bodyB.isStatic {
            bodyB.velocity.dx += impulse.dx * invMassB
            bodyB.velocity.dy += impulse.dy * invMassB
        }
        
        // Positional correction to prevent sinking
        let percent: CGFloat = 0.8
        let slop: CGFloat = 0.01
        let correction = max(collision.penetration - slop, 0) / (invMassA + invMassB) * percent
        
        if !bodyA.isStatic {
            bodyA.position.x -= correction * invMassA * collision.normal.dx
            bodyA.position.y -= correction * invMassA * collision.normal.dy
        }
        
        if !bodyB.isStatic {
            bodyB.position.x += correction * invMassB * collision.normal.dx
            bodyB.position.y += correction * invMassB * collision.normal.dy
        }
        
        // Apply friction
        let friction = sqrt(bodyA.friction * bodyB.friction)
        let tangent = CGVector(
            dx: collision.relativeVelocity.dx - relVelNormal * collision.normal.dx,
            dy: collision.relativeVelocity.dy - relVelNormal * collision.normal.dy
        )
        let tangentLength = sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy)
        
        if tangentLength > 0.001 {
            let frictionImpulse = impulseMagnitude * friction
            let normalizedTangent = CGVector(dx: tangent.dx / tangentLength, dy: tangent.dy / tangentLength)
            
            if !bodyA.isStatic {
                bodyA.velocity.dx += frictionImpulse * normalizedTangent.dx * invMassA
                bodyA.velocity.dy += frictionImpulse * normalizedTangent.dy * invMassA
            }
            
            if !bodyB.isStatic {
                bodyB.velocity.dx -= frictionImpulse * normalizedTangent.dx * invMassB
                bodyB.velocity.dy -= frictionImpulse * normalizedTangent.dy * invMassB
            }
        }
    }
    
    /// Resolve boundary collision
    public func resolveBoundary(body: PhysicsBody, normal: CGVector, penetration: CGFloat, boundary: PhysicsBoundary) {
        guard !body.isStatic else { return }
        
        // Position correction
        body.position.x += normal.dx * penetration
        body.position.y += normal.dy * penetration
        
        // Velocity reflection
        let velNormal = body.velocity.dx * normal.dx + body.velocity.dy * normal.dy
        
        if velNormal < 0 { // Moving into wall
            let restitution = min(body.elasticity, boundary.elasticity)
            
            body.velocity.dx -= (1 + restitution) * velNormal * normal.dx
            body.velocity.dy -= (1 + restitution) * velNormal * normal.dy
            
            // Apply friction
            let friction = sqrt(body.friction * boundary.friction)
            let tangentVel = CGVector(
                dx: body.velocity.dx - velNormal * normal.dx,
                dy: body.velocity.dy - velNormal * normal.dy
            )
            
            body.velocity.dx -= tangentVel.dx * friction
            body.velocity.dy -= tangentVel.dy * friction
        }
    }
}

// MARK: - Gravity System

/// Main gravity physics system
public final class GravitySystem {
    
    // MARK: - Properties
    
    private var bodies: [PhysicsBody] = []
    private var boundaries: [PhysicsBoundary] = []
    private var configuration: GravityConfiguration
    private let collisionDetector = CollisionDetector()
    private let collisionResolver = CollisionResolver()
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false
    
    private var motionManager: CMMotionManager?
    private var currentGravity: CGVector
    
    /// Collision callback
    public var onCollision: ((CollisionInfo) -> Void)?
    
    /// Update callback (called each frame)
    public var onUpdate: (() -> Void)?
    
    /// Body count
    public var bodyCount: Int { bodies.count }
    
    /// Whether the system is running
    public var isActive: Bool { isRunning }
    
    /// Current gravity vector
    public var gravity: CGVector {
        get { currentGravity }
        set { currentGravity = newValue }
    }
    
    // MARK: - Initialization
    
    public init(configuration: GravityConfiguration = .default) {
        self.configuration = configuration
        self.currentGravity = configuration.gravity.vector
        
        if configuration.useDeviceMotion {
            setupDeviceMotion()
        }
    }
    
    deinit {
        stop()
        motionManager?.stopDeviceMotionUpdates()
    }
    
    // MARK: - Device Motion
    
    private func setupDeviceMotion() {
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1/60
        
        if motionManager?.isDeviceMotionAvailable == true {
            motionManager?.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let motion = motion, let self = self else { return }
                
                let sensitivity = self.configuration.deviceMotionSensitivity
                let baseGravity: CGFloat = 980
                
                self.currentGravity = CGVector(
                    dx: CGFloat(motion.gravity.x) * baseGravity * sensitivity,
                    dy: CGFloat(-motion.gravity.y) * baseGravity * sensitivity
                )
            }
        }
    }
    
    // MARK: - Body Management
    
    /// Add a body to the system
    public func addBody(_ body: PhysicsBody) {
        bodies.append(body)
    }
    
    /// Remove a body from the system
    public func removeBody(_ body: PhysicsBody) {
        bodies.removeAll { $0.id == body.id }
    }
    
    /// Remove all bodies
    public func removeAllBodies() {
        bodies.removeAll()
    }
    
    /// Get all bodies
    public func getAllBodies() -> [PhysicsBody] {
        return bodies
    }
    
    // MARK: - Boundary Management
    
    /// Add a boundary
    public func addBoundary(_ boundary: PhysicsBoundary) {
        boundaries.append(boundary)
    }
    
    /// Remove all boundaries
    public func removeAllBoundaries() {
        boundaries.removeAll()
    }
    
    /// Set bounds as boundary
    public func setBounds(_ rect: CGRect, elasticity: CGFloat = 0.5, friction: CGFloat = 0.3) {
        boundaries.removeAll()
        boundaries.append(.inside(rect, elasticity: elasticity, friction: friction))
    }
    
    // MARK: - Control
    
    /// Start the physics simulation
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        lastUpdateTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Stop the physics simulation
    public func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// Pause simulation
    public func pause() {
        displayLink?.isPaused = true
    }
    
    /// Resume simulation
    public func resume() {
        lastUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    // MARK: - Update
    
    @objc private func update(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        var deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Cap delta time to prevent instability
        deltaTime = min(deltaTime, 1/30)
        
        // Fixed time step integration
        var accumulator = deltaTime
        let fixedStep = TimeInterval(configuration.timeStep)
        
        while accumulator >= fixedStep {
            step(dt: CGFloat(fixedStep))
            accumulator -= fixedStep
        }
        
        // Update views
        syncViews()
        
        onUpdate?()
    }
    
    private func step(dt: CGFloat) {
        // Apply gravity and update velocities
        for body in bodies where !body.isStatic && body.affectedByGravity {
            body.velocity.dx += currentGravity.dx * dt
            body.velocity.dy += currentGravity.dy * dt
        }
        
        // Apply damping
        for body in bodies where !body.isStatic {
            body.velocity.dx *= configuration.globalDamping
            body.velocity.dy *= configuration.globalDamping
            
            // Apply drag
            let speed = body.speed
            if speed > 0 {
                let dragForce = body.drag * speed * speed
                let dragAccel = dragForce / body.mass
                let ratio = max(0, 1 - dragAccel * dt / speed)
                body.velocity.dx *= ratio
                body.velocity.dy *= ratio
            }
            
            // Clamp velocity
            let currentSpeed = body.speed
            if currentSpeed > configuration.maxVelocity {
                let scale = configuration.maxVelocity / currentSpeed
                body.velocity.dx *= scale
                body.velocity.dy *= scale
            }
        }
        
        // Update positions
        for body in bodies where !body.isStatic {
            body.position.x += body.velocity.dx * dt
            body.position.y += body.velocity.dy * dt
            
            body.rotation += body.angularVelocity * dt
            body.angularVelocity *= configuration.globalDamping
        }
        
        // Collision detection and resolution
        if configuration.enableCollisions {
            detectAndResolveCollisions()
        }
        
        // Boundary collisions
        for body in bodies where !body.isStatic {
            for boundary in boundaries {
                if let result = collisionDetector.detectBoundaryCollision(body: body, boundary: boundary) {
                    collisionResolver.resolveBoundary(
                        body: body,
                        normal: result.normal,
                        penetration: result.penetration,
                        boundary: boundary
                    )
                }
            }
        }
    }
    
    private func detectAndResolveCollisions() {
        for i in 0..<bodies.count {
            for j in (i + 1)..<bodies.count {
                if let collision = collisionDetector.detectCollision(bodyA: bodies[i], bodyB: bodies[j]) {
                    collisionResolver.resolve(collision)
                    onCollision?(collision)
                }
            }
        }
    }
    
    private func syncViews() {
        for body in bodies {
            guard let view = body.view else { continue }
            
            view.center = body.position
            view.transform = CGAffineTransform(rotationAngle: body.rotation)
        }
    }
}

// MARK: - Gravity View

/// A view with gravity physics
public final class GravityView: UIView {
    
    private var gravitySystem: GravitySystem?
    private var configuration: GravityConfiguration
    
    public init(frame: CGRect, configuration: GravityConfiguration = .default) {
        self.configuration = configuration
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
    }
    
    /// Setup gravity system
    public func setupGravity() {
        gravitySystem = GravitySystem(configuration: configuration)
        gravitySystem?.setBounds(bounds)
    }
    
    /// Add a view with physics
    public func addPhysicsView(_ view: UIView, mass: CGFloat = 1.0, elasticity: CGFloat = 0.5) {
        addSubview(view)
        
        let body = PhysicsBody(view: view, mass: mass)
        body.elasticity = elasticity
        gravitySystem?.addBody(body)
    }
    
    /// Start simulation
    public func startSimulation() {
        gravitySystem?.start()
    }
    
    /// Stop simulation
    public func stopSimulation() {
        gravitySystem?.stop()
    }
}

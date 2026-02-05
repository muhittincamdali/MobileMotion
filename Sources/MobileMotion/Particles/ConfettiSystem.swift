//
//  ConfettiSystem.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - Confetti Shape

/// Available shapes for confetti particles
public enum ConfettiShape: CaseIterable, Sendable {
    case rectangle
    case circle
    case triangle
    case star
    case diamond
    case heart
    case custom
    
    /// Generate a path for the shape at given size
    func path(size: CGSize) -> UIBezierPath {
        switch self {
        case .rectangle:
            return UIBezierPath(rect: CGRect(origin: .zero, size: size))
            
        case .circle:
            return UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            
        case .triangle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.close()
            return path
            
        case .star:
            return createStarPath(size: size, points: 5)
            
        case .diamond:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height / 2))
            path.close()
            return path
            
        case .heart:
            return createHeartPath(size: size)
            
        case .custom:
            return UIBezierPath(rect: CGRect(origin: .zero, size: size))
        }
    }
    
    private func createStarPath(size: CGSize, points: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * 0.4
        
        var angle: CGFloat = -.pi / 2
        let angleIncrement = .pi / CGFloat(points)
        
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            angle += angleIncrement
        }
        
        path.close()
        return path
    }
    
    private func createHeartPath(size: CGSize) -> UIBezierPath {
        let path = UIBezierPath()
        let width = size.width
        let height = size.height
        
        path.move(to: CGPoint(x: width / 2, y: height))
        
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            controlPoint1: CGPoint(x: width / 2 - width / 4, y: height * 3 / 4),
            controlPoint2: CGPoint(x: 0, y: height / 2)
        )
        
        path.addArc(
            withCenter: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addArc(
            withCenter: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            controlPoint1: CGPoint(x: width, y: height / 2),
            controlPoint2: CGPoint(x: width / 2 + width / 4, y: height * 3 / 4)
        )
        
        path.close()
        return path
    }
}

// MARK: - Confetti Particle

/// Represents a single confetti particle with physics properties
public struct ConfettiParticle {
    /// Unique identifier
    public let id: UUID
    
    /// Current position
    public var position: CGPoint
    
    /// Current velocity
    public var velocity: CGPoint
    
    /// Rotation angle in radians
    public var rotation: CGFloat
    
    /// Rotation velocity
    public var rotationVelocity: CGFloat
    
    /// Particle color
    public let color: UIColor
    
    /// Particle shape
    public let shape: ConfettiShape
    
    /// Particle size
    public let size: CGSize
    
    /// Opacity
    public var opacity: CGFloat
    
    /// Scale
    public var scale: CGFloat
    
    /// Time since creation
    public var lifetime: TimeInterval
    
    /// Maximum lifetime
    public let maxLifetime: TimeInterval
    
    /// Air resistance factor
    public let airResistance: CGFloat
    
    /// Wobble amplitude
    public let wobbleAmplitude: CGFloat
    
    /// Wobble frequency
    public let wobbleFrequency: CGFloat
    
    /// Phase offset for wobble
    public let wobblePhase: CGFloat
    
    public init(
        position: CGPoint,
        velocity: CGPoint,
        color: UIColor,
        shape: ConfettiShape,
        size: CGSize,
        maxLifetime: TimeInterval = 5.0
    ) {
        self.id = UUID()
        self.position = position
        self.velocity = velocity
        self.rotation = CGFloat.random(in: 0...(.pi * 2))
        self.rotationVelocity = CGFloat.random(in: -5...5)
        self.color = color
        self.shape = shape
        self.size = size
        self.opacity = 1.0
        self.scale = 1.0
        self.lifetime = 0
        self.maxLifetime = maxLifetime
        self.airResistance = CGFloat.random(in: 0.01...0.03)
        self.wobbleAmplitude = CGFloat.random(in: 20...60)
        self.wobbleFrequency = CGFloat.random(in: 2...5)
        self.wobblePhase = CGFloat.random(in: 0...(.pi * 2))
    }
    
    /// Check if particle is still alive
    public var isAlive: Bool {
        return lifetime < maxLifetime && opacity > 0.01
    }
    
    /// Update particle physics for delta time
    public mutating func update(deltaTime: TimeInterval, gravity: CGFloat) {
        lifetime += deltaTime
        
        // Apply gravity
        velocity.y += gravity * CGFloat(deltaTime)
        
        // Apply air resistance
        velocity.x *= (1 - airResistance)
        velocity.y *= (1 - airResistance * 0.5)
        
        // Add wobble motion
        let wobbleOffset = sin(CGFloat(lifetime) * wobbleFrequency + wobblePhase) * wobbleAmplitude * CGFloat(deltaTime)
        
        // Update position
        position.x += velocity.x * CGFloat(deltaTime) + wobbleOffset
        position.y += velocity.y * CGFloat(deltaTime)
        
        // Update rotation
        rotation += rotationVelocity * CGFloat(deltaTime)
        
        // Fade out near end of lifetime
        let lifetimeRatio = lifetime / maxLifetime
        if lifetimeRatio > 0.7 {
            opacity = CGFloat(1 - (lifetimeRatio - 0.7) / 0.3)
        }
    }
}

// MARK: - Confetti Configuration

/// Configuration options for the confetti system
public struct ConfettiConfiguration: Sendable {
    /// Number of particles to emit
    public var particleCount: Int
    
    /// Emission duration (0 for burst)
    public var emissionDuration: TimeInterval
    
    /// Available colors for particles
    public var colors: [UIColor]
    
    /// Available shapes for particles
    public var shapes: [ConfettiShape]
    
    /// Minimum particle size
    public var minSize: CGSize
    
    /// Maximum particle size
    public var maxSize: CGSize
    
    /// Initial velocity range
    public var velocityRange: ClosedRange<CGFloat>
    
    /// Emission angle range (in radians)
    public var angleRange: ClosedRange<CGFloat>
    
    /// Gravity strength
    public var gravity: CGFloat
    
    /// Particle lifetime
    public var lifetime: TimeInterval
    
    /// Whether particles should fade out
    public var fadeOut: Bool
    
    /// Spread angle from center (in radians)
    public var spreadAngle: CGFloat
    
    /// Emission origin type
    public var origin: ConfettiOrigin
    
    /// Default celebration configuration
    public static let celebration = ConfettiConfiguration(
        particleCount: 100,
        emissionDuration: 0.5,
        colors: [.red, .orange, .yellow, .green, .blue, .purple, .systemPink],
        shapes: [.rectangle, .circle, .star],
        minSize: CGSize(width: 6, height: 4),
        maxSize: CGSize(width: 14, height: 10),
        velocityRange: 300...600,
        angleRange: (-.pi * 0.75)...(-.pi * 0.25),
        gravity: 400,
        lifetime: 4.0,
        fadeOut: true,
        spreadAngle: .pi / 4,
        origin: .bottom
    )
    
    /// Subtle confetti configuration
    public static let subtle = ConfettiConfiguration(
        particleCount: 30,
        emissionDuration: 0.3,
        colors: [.systemBlue, .systemTeal, .systemCyan],
        shapes: [.circle],
        minSize: CGSize(width: 4, height: 4),
        maxSize: CGSize(width: 8, height: 8),
        velocityRange: 200...400,
        angleRange: (-.pi * 0.8)...(-.pi * 0.2),
        gravity: 300,
        lifetime: 3.0,
        fadeOut: true,
        spreadAngle: .pi / 6,
        origin: .center
    )
    
    /// Explosion configuration
    public static let explosion = ConfettiConfiguration(
        particleCount: 200,
        emissionDuration: 0,
        colors: [.red, .orange, .yellow],
        shapes: [.star, .diamond, .triangle],
        minSize: CGSize(width: 8, height: 6),
        maxSize: CGSize(width: 16, height: 12),
        velocityRange: 400...800,
        angleRange: 0...(.pi * 2),
        gravity: 500,
        lifetime: 3.0,
        fadeOut: true,
        spreadAngle: .pi * 2,
        origin: .center
    )
    
    /// Hearts configuration
    public static let hearts = ConfettiConfiguration(
        particleCount: 50,
        emissionDuration: 1.0,
        colors: [.systemRed, .systemPink, .red],
        shapes: [.heart],
        minSize: CGSize(width: 12, height: 12),
        maxSize: CGSize(width: 24, height: 24),
        velocityRange: 200...400,
        angleRange: (-.pi * 0.75)...(-.pi * 0.25),
        gravity: 200,
        lifetime: 5.0,
        fadeOut: true,
        spreadAngle: .pi / 3,
        origin: .bottom
    )
    
    public init(
        particleCount: Int = 100,
        emissionDuration: TimeInterval = 0.5,
        colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple],
        shapes: [ConfettiShape] = ConfettiShape.allCases.filter { $0 != .custom },
        minSize: CGSize = CGSize(width: 6, height: 4),
        maxSize: CGSize = CGSize(width: 14, height: 10),
        velocityRange: ClosedRange<CGFloat> = 300...600,
        angleRange: ClosedRange<CGFloat> = (-.pi * 0.75)...(-.pi * 0.25),
        gravity: CGFloat = 400,
        lifetime: TimeInterval = 4.0,
        fadeOut: Bool = true,
        spreadAngle: CGFloat = .pi / 4,
        origin: ConfettiOrigin = .bottom
    ) {
        self.particleCount = particleCount
        self.emissionDuration = emissionDuration
        self.colors = colors
        self.shapes = shapes
        self.minSize = minSize
        self.maxSize = maxSize
        self.velocityRange = velocityRange
        self.angleRange = angleRange
        self.gravity = gravity
        self.lifetime = lifetime
        self.fadeOut = fadeOut
        self.spreadAngle = spreadAngle
        self.origin = origin
    }
}

// MARK: - Confetti Origin

/// Defines where confetti particles originate from
public enum ConfettiOrigin: Sendable {
    case top
    case bottom
    case left
    case right
    case center
    case point(CGPoint)
    case randomEdge
    
    func getPosition(in bounds: CGRect) -> CGPoint {
        switch self {
        case .top:
            return CGPoint(x: bounds.midX, y: bounds.minY)
        case .bottom:
            return CGPoint(x: bounds.midX, y: bounds.maxY)
        case .left:
            return CGPoint(x: bounds.minX, y: bounds.midY)
        case .right:
            return CGPoint(x: bounds.maxX, y: bounds.midY)
        case .center:
            return CGPoint(x: bounds.midX, y: bounds.midY)
        case .point(let point):
            return point
        case .randomEdge:
            let edge = Int.random(in: 0...3)
            switch edge {
            case 0: return CGPoint(x: CGFloat.random(in: bounds.minX...bounds.maxX), y: bounds.minY)
            case 1: return CGPoint(x: CGFloat.random(in: bounds.minX...bounds.maxX), y: bounds.maxY)
            case 2: return CGPoint(x: bounds.minX, y: CGFloat.random(in: bounds.minY...bounds.maxY))
            default: return CGPoint(x: bounds.maxX, y: CGFloat.random(in: bounds.minY...bounds.maxY))
            }
        }
    }
}

// MARK: - Confetti Emitter

/// Handles particle emission logic
public final class ConfettiEmitter {
    
    // MARK: - Properties
    
    private let configuration: ConfettiConfiguration
    private var emittedCount = 0
    private var emissionStartTime: TimeInterval = 0
    var isEmitting = false
    
    // MARK: - Initialization
    
    public init(configuration: ConfettiConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Emission
    
    public func startEmission() {
        emittedCount = 0
        emissionStartTime = CACurrentMediaTime()
        isEmitting = true
    }
    
    public func stopEmission() {
        isEmitting = false
    }
    
    public func emit(in bounds: CGRect, deltaTime: TimeInterval) -> [ConfettiParticle] {
        guard isEmitting else { return [] }
        
        let currentTime = CACurrentMediaTime() - emissionStartTime
        
        // Check if emission period is over
        if configuration.emissionDuration > 0 && currentTime > configuration.emissionDuration {
            isEmitting = false
            return []
        }
        
        // Calculate how many particles to emit this frame
        let particlesToEmit: Int
        if configuration.emissionDuration == 0 {
            // Burst mode - emit all at once
            particlesToEmit = configuration.particleCount - emittedCount
            isEmitting = false
        } else {
            // Continuous emission
            let emissionRate = Double(configuration.particleCount) / configuration.emissionDuration
            let targetCount = Int(currentTime * emissionRate)
            particlesToEmit = min(targetCount - emittedCount, configuration.particleCount - emittedCount)
        }
        
        guard particlesToEmit > 0 else { return [] }
        
        var particles: [ConfettiParticle] = []
        let origin = configuration.origin.getPosition(in: bounds)
        
        for _ in 0..<particlesToEmit {
            let particle = createParticle(at: origin, in: bounds)
            particles.append(particle)
            emittedCount += 1
        }
        
        return particles
    }
    
    private func createParticle(at origin: CGPoint, in bounds: CGRect) -> ConfettiParticle {
        // Random color and shape
        let color = configuration.colors.randomElement() ?? .red
        let shape = configuration.shapes.randomElement() ?? .rectangle
        
        // Random size within range
        let width = CGFloat.random(in: configuration.minSize.width...configuration.maxSize.width)
        let height = CGFloat.random(in: configuration.minSize.height...configuration.maxSize.height)
        let size = CGSize(width: width, height: height)
        
        // Random velocity and angle
        let speed = CGFloat.random(in: configuration.velocityRange)
        let angle = CGFloat.random(in: configuration.angleRange)
        
        // Add some random offset to origin
        let spreadX = CGFloat.random(in: -50...50)
        let spreadY = CGFloat.random(in: -20...20)
        let position = CGPoint(x: origin.x + spreadX, y: origin.y + spreadY)
        
        let velocity = CGPoint(
            x: cos(angle) * speed,
            y: sin(angle) * speed
        )
        
        return ConfettiParticle(
            position: position,
            velocity: velocity,
            color: color,
            shape: shape,
            size: size,
            maxLifetime: configuration.lifetime
        )
    }
}

// MARK: - Confetti Renderer

/// Renders confetti particles using Core Animation
public final class ConfettiRenderer {
    
    // MARK: - Properties
    
    weak var containerLayer: CALayer?
    private var particleLayers: [UUID: CAShapeLayer] = [:]
    private let reusePool = ParticleLayerPool()
    
    // MARK: - Initialization
    
    public init(containerLayer: CALayer) {
        self.containerLayer = containerLayer
    }
    
    // MARK: - Rendering
    
    public func render(particles: [ConfettiParticle]) {
        guard let container = containerLayer else { return }
        
        // Track which particles are still active
        var activeIds = Set<UUID>()
        
        for particle in particles {
            activeIds.insert(particle.id)
            
            if let layer = particleLayers[particle.id] {
                // Update existing layer
                updateLayer(layer, with: particle)
            } else {
                // Create new layer
                let layer = reusePool.obtain()
                configureLayer(layer, with: particle)
                container.addSublayer(layer)
                particleLayers[particle.id] = layer
            }
        }
        
        // Remove dead particle layers
        let deadIds = Set(particleLayers.keys).subtracting(activeIds)
        for id in deadIds {
            if let layer = particleLayers.removeValue(forKey: id) {
                layer.removeFromSuperlayer()
                reusePool.recycle(layer)
            }
        }
    }
    
    public func clear() {
        for (_, layer) in particleLayers {
            layer.removeFromSuperlayer()
            reusePool.recycle(layer)
        }
        particleLayers.removeAll()
    }
    
    private func configureLayer(_ layer: CAShapeLayer, with particle: ConfettiParticle) {
        let path = particle.shape.path(size: particle.size)
        layer.path = path.cgPath
        layer.fillColor = particle.color.cgColor
        layer.bounds = CGRect(origin: .zero, size: particle.size)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        updateLayer(layer, with: particle)
    }
    
    private func updateLayer(_ layer: CAShapeLayer, with particle: ConfettiParticle) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        layer.position = particle.position
        layer.opacity = Float(particle.opacity)
        layer.transform = CATransform3DMakeRotation(particle.rotation, 0, 0, 1)
        
        CATransaction.commit()
    }
}

// MARK: - Particle Layer Pool

/// Reuses CAShapeLayer instances for better performance
private final class ParticleLayerPool {
    private var pool: [CAShapeLayer] = []
    private let maxPoolSize = 200
    
    func obtain() -> CAShapeLayer {
        if let layer = pool.popLast() {
            return layer
        }
        return CAShapeLayer()
    }
    
    func recycle(_ layer: CAShapeLayer) {
        guard pool.count < maxPoolSize else { return }
        layer.removeAllAnimations()
        pool.append(layer)
    }
}

// MARK: - Confetti System

/// Main confetti particle system that coordinates emission and rendering
public final class ConfettiSystem {
    
    // MARK: - Properties
    
    private var particles: [ConfettiParticle] = []
    private let emitter: ConfettiEmitter
    private let renderer: ConfettiRenderer
    private let configuration: ConfettiConfiguration
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false
    
    /// Callback when all particles have finished
    public var onComplete: (() -> Void)?
    
    /// Current particle count
    public var particleCount: Int { particles.count }
    
    /// Whether the system is currently running
    public var isActive: Bool { isRunning }
    
    // MARK: - Initialization
    
    public init(configuration: ConfettiConfiguration, containerLayer: CALayer) {
        self.configuration = configuration
        self.emitter = ConfettiEmitter(configuration: configuration)
        self.renderer = ConfettiRenderer(containerLayer: containerLayer)
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start the confetti system
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        particles.removeAll()
        emitter.startEmission()
        lastUpdateTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Stop the confetti system
    public func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
        emitter.stopEmission()
        renderer.clear()
        particles.removeAll()
    }
    
    /// Pause the confetti system
    public func pause() {
        displayLink?.isPaused = true
    }
    
    /// Resume the confetti system
    public func resume() {
        lastUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    /// Add particles manually
    public func addParticles(_ newParticles: [ConfettiParticle]) {
        particles.append(contentsOf: newParticles)
    }
    
    /// Emit a burst at a specific point
    public func burst(at point: CGPoint, count: Int = 50) {
        var burstConfig = configuration
        burstConfig.origin = .point(point)
        burstConfig.particleCount = count
        burstConfig.emissionDuration = 0
        
        let burstEmitter = ConfettiEmitter(configuration: burstConfig)
        burstEmitter.startEmission()
        
        let newParticles = burstEmitter.emit(
            in: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)),
            deltaTime: 0
        )
        particles.append(contentsOf: newParticles)
    }
    
    // MARK: - Update Loop
    
    @objc private func update(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Emit new particles
        let containerBounds = renderer.containerLayer?.bounds ?? .zero
        let newParticles = emitter.emit(in: containerBounds, deltaTime: deltaTime)
        particles.append(contentsOf: newParticles)
        
        // Update existing particles
        for i in particles.indices.reversed() {
            particles[i].update(deltaTime: deltaTime, gravity: configuration.gravity)
            
            // Remove dead particles
            if !particles[i].isAlive || isOutOfBounds(particles[i], in: containerBounds) {
                particles.remove(at: i)
            }
        }
        
        // Render
        renderer.render(particles: particles)
        
        // Check completion
        if particles.isEmpty {
            stop()
            onComplete?()
        }
    }
    
    private func isOutOfBounds(_ particle: ConfettiParticle, in bounds: CGRect) -> Bool {
        let margin: CGFloat = 100
        let expandedBounds = bounds.insetBy(dx: -margin, dy: -margin)
        return !expandedBounds.contains(particle.position)
    }
}

// MARK: - Confetti View

/// A UIView that displays confetti effects
public final class ConfettiView: UIView {
    
    // MARK: - Properties
    
    private var confettiSystem: ConfettiSystem?
    private var configuration: ConfettiConfiguration
    
    /// Callback when confetti animation completes
    public var onComplete: (() -> Void)?
    
    /// Whether confetti is currently active
    public var isActive: Bool {
        confettiSystem?.isActive ?? false
    }
    
    // MARK: - Initialization
    
    public init(frame: CGRect, configuration: ConfettiConfiguration = .celebration) {
        self.configuration = configuration
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .celebration
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    // MARK: - Public Methods
    
    /// Start the confetti celebration
    public func celebrate() {
        stopConfetti()
        
        let system = ConfettiSystem(configuration: configuration, containerLayer: layer)
        system.onComplete = { [weak self] in
            self?.onComplete?()
        }
        confettiSystem = system
        system.start()
    }
    
    /// Start with custom configuration
    public func celebrate(with customConfig: ConfettiConfiguration) {
        configuration = customConfig
        celebrate()
    }
    
    /// Emit a burst at touch point
    public func burst(at point: CGPoint) {
        if confettiSystem == nil {
            let system = ConfettiSystem(configuration: configuration, containerLayer: layer)
            confettiSystem = system
            system.start()
        }
        confettiSystem?.burst(at: point)
    }
    
    /// Stop the confetti
    public func stopConfetti() {
        confettiSystem?.stop()
        confettiSystem = nil
    }
    
    /// Update configuration
    public func updateConfiguration(_ newConfig: ConfettiConfiguration) {
        configuration = newConfig
    }
}

// MARK: - UIView Extension

public extension UIView {
    
    /// Show a confetti celebration on this view
    func showConfetti(
        configuration: ConfettiConfiguration = .celebration,
        completion: (() -> Void)? = nil
    ) {
        let confettiView = ConfettiView(frame: bounds, configuration: configuration)
        confettiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        confettiView.onComplete = { [weak confettiView] in
            confettiView?.removeFromSuperview()
            completion?()
        }
        addSubview(confettiView)
        confettiView.celebrate()
    }
    
    /// Show a confetti burst at a specific point
    func showConfettiBurst(
        at point: CGPoint,
        configuration: ConfettiConfiguration = .explosion
    ) {
        var config = configuration
        config.origin = .point(point)
        config.emissionDuration = 0
        
        let confettiView = ConfettiView(frame: bounds, configuration: config)
        confettiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        confettiView.onComplete = { [weak confettiView] in
            confettiView?.removeFromSuperview()
        }
        addSubview(confettiView)
        confettiView.celebrate()
    }
}

// MARK: - Preset Confetti Effects

public enum ConfettiPreset {
    case celebration
    case subtle
    case explosion
    case hearts
    case custom(ConfettiConfiguration)
    
    var configuration: ConfettiConfiguration {
        switch self {
        case .celebration: return .celebration
        case .subtle: return .subtle
        case .explosion: return .explosion
        case .hearts: return .hearts
        case .custom(let config): return config
        }
    }
}

// MARK: - Confetti Trigger

/// Convenience class for triggering confetti effects
public final class ConfettiTrigger {
    
    private weak var targetView: UIView?
    private var confettiView: ConfettiView?
    
    public init(targetView: UIView) {
        self.targetView = targetView
    }
    
    /// Fire confetti with a preset
    public func fire(preset: ConfettiPreset = .celebration, completion: (() -> Void)? = nil) {
        guard let view = targetView else { return }
        
        cleanup()
        
        let confetti = ConfettiView(frame: view.bounds, configuration: preset.configuration)
        confetti.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        confetti.onComplete = { [weak self] in
            self?.cleanup()
            completion?()
        }
        
        view.addSubview(confetti)
        confettiView = confetti
        confetti.celebrate()
    }
    
    /// Stop and cleanup
    public func cleanup() {
        confettiView?.stopConfetti()
        confettiView?.removeFromSuperview()
        confettiView = nil
    }
}

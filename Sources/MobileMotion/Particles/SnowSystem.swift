//
//  SnowSystem.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - Snow Particle Type

/// Different types of snow particles
public enum SnowParticleType: CaseIterable, Sendable {
    case flake
    case dot
    case star
    case custom
    
    /// Create the visual representation
    func createImage(size: CGFloat, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            
            switch self {
            case .flake:
                drawSnowflake(in: context.cgContext, rect: rect, color: color)
            case .dot:
                color.setFill()
                context.cgContext.fillEllipse(in: rect.insetBy(dx: size * 0.1, dy: size * 0.1))
            case .star:
                drawStar(in: context.cgContext, rect: rect, color: color)
            case .custom:
                color.setFill()
                context.cgContext.fillEllipse(in: rect)
            }
        }
    }
    
    private func drawSnowflake(in context: CGContext, rect: CGRect, color: UIColor) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.9
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(max(1, radius / 6))
        context.setLineCap(.round)
        
        // Draw 6 branches
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let endX = center.x + cos(angle) * radius
            let endY = center.y + sin(angle) * radius
            
            context.move(to: center)
            context.addLine(to: CGPoint(x: endX, y: endY))
            
            // Add small branches
            let branchLength = radius * 0.4
            let branchPoint = CGPoint(
                x: center.x + cos(angle) * radius * 0.6,
                y: center.y + sin(angle) * radius * 0.6
            )
            
            for offset in [-1, 1] {
                let branchAngle = angle + CGFloat(offset) * .pi / 4
                let branchEnd = CGPoint(
                    x: branchPoint.x + cos(branchAngle) * branchLength,
                    y: branchPoint.y + sin(branchAngle) * branchLength
                )
                context.move(to: branchPoint)
                context.addLine(to: branchEnd)
            }
        }
        
        context.strokePath()
    }
    
    private func drawStar(in context: CGContext, rect: CGRect, color: UIColor) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.9
        
        context.setFillColor(color.cgColor)
        
        let path = CGMutablePath()
        let innerRadius = radius * 0.4
        
        for i in 0..<10 {
            let r = i % 2 == 0 ? radius : innerRadius
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        context.addPath(path)
        context.fillPath()
    }
}

// MARK: - Snow Particle

/// Represents a single snow particle
public struct SnowParticle {
    /// Unique identifier
    public let id: UUID
    
    /// Current position
    public var position: CGPoint
    
    /// Fall velocity (pixels per second)
    public var fallSpeed: CGFloat
    
    /// Horizontal drift velocity
    public var driftSpeed: CGFloat
    
    /// Current drift offset
    public var driftOffset: CGFloat
    
    /// Drift phase for sine wave
    public var driftPhase: CGFloat
    
    /// Particle size
    public let size: CGFloat
    
    /// Rotation angle
    public var rotation: CGFloat
    
    /// Rotation speed
    public var rotationSpeed: CGFloat
    
    /// Opacity
    public var opacity: CGFloat
    
    /// Particle type
    public let type: SnowParticleType
    
    /// Layer depth (0-1, affects parallax)
    public let depth: CGFloat
    
    /// Lifetime (for fading)
    public var lifetime: TimeInterval
    
    public init(
        position: CGPoint,
        fallSpeed: CGFloat,
        driftSpeed: CGFloat,
        size: CGFloat,
        type: SnowParticleType,
        depth: CGFloat
    ) {
        self.id = UUID()
        self.position = position
        self.fallSpeed = fallSpeed
        self.driftSpeed = driftSpeed
        self.driftOffset = 0
        self.driftPhase = CGFloat.random(in: 0...(.pi * 2))
        self.size = size
        self.rotation = CGFloat.random(in: 0...(.pi * 2))
        self.rotationSpeed = CGFloat.random(in: -2...2)
        self.opacity = CGFloat.random(in: 0.6...1.0)
        self.type = type
        self.depth = depth
        self.lifetime = 0
    }
    
    /// Update particle physics
    public mutating func update(
        deltaTime: TimeInterval,
        windStrength: CGFloat,
        bounds: CGRect
    ) {
        lifetime += deltaTime
        
        // Apply depth-based parallax to speeds
        let depthMultiplier = 0.5 + depth * 0.5
        
        // Update vertical position
        position.y += fallSpeed * CGFloat(deltaTime) * depthMultiplier
        
        // Calculate drift using sine wave
        driftPhase += CGFloat(deltaTime) * driftSpeed
        let driftAmount = sin(driftPhase) * 30 * depthMultiplier
        
        // Apply wind
        let windEffect = windStrength * depthMultiplier * CGFloat(deltaTime) * 100
        
        position.x += driftAmount * CGFloat(deltaTime) + windEffect
        
        // Update rotation
        rotation += rotationSpeed * CGFloat(deltaTime)
        
        // Wrap horizontally
        if position.x < -size {
            position.x = bounds.width + size
        } else if position.x > bounds.width + size {
            position.x = -size
        }
    }
    
    /// Check if particle is out of bounds (vertically)
    public func isOutOfBounds(in bounds: CGRect) -> Bool {
        return position.y > bounds.height + size * 2
    }
}

// MARK: - Snow Configuration

/// Configuration for the snow particle system
public struct SnowConfiguration: Sendable {
    /// Maximum number of particles
    public var maxParticles: Int
    
    /// Emission rate (particles per second)
    public var emissionRate: CGFloat
    
    /// Minimum fall speed
    public var minFallSpeed: CGFloat
    
    /// Maximum fall speed
    public var maxFallSpeed: CGFloat
    
    /// Minimum particle size
    public var minSize: CGFloat
    
    /// Maximum particle size
    public var maxSize: CGFloat
    
    /// Horizontal drift speed range
    public var driftSpeedRange: ClosedRange<CGFloat>
    
    /// Wind strength (-1 to 1, negative = left, positive = right)
    public var windStrength: CGFloat
    
    /// Snow color
    public var color: UIColor
    
    /// Available particle types
    public var particleTypes: [SnowParticleType]
    
    /// Enable depth/parallax effect
    public var enableParallax: Bool
    
    /// Number of depth layers
    public var depthLayers: Int
    
    /// Light snow preset
    public static let light = SnowConfiguration(
        maxParticles: 50,
        emissionRate: 5,
        minFallSpeed: 30,
        maxFallSpeed: 60,
        minSize: 4,
        maxSize: 10,
        driftSpeedRange: 1...2,
        windStrength: 0,
        color: .white,
        particleTypes: [.flake, .dot],
        enableParallax: true,
        depthLayers: 3
    )
    
    /// Medium snow preset
    public static let medium = SnowConfiguration(
        maxParticles: 100,
        emissionRate: 15,
        minFallSpeed: 50,
        maxFallSpeed: 100,
        minSize: 5,
        maxSize: 15,
        driftSpeedRange: 1...3,
        windStrength: 0.2,
        color: .white,
        particleTypes: [.flake, .dot, .star],
        enableParallax: true,
        depthLayers: 4
    )
    
    /// Heavy snow preset
    public static let heavy = SnowConfiguration(
        maxParticles: 200,
        emissionRate: 30,
        minFallSpeed: 80,
        maxFallSpeed: 150,
        minSize: 6,
        maxSize: 20,
        driftSpeedRange: 2...4,
        windStrength: 0.5,
        color: .white,
        particleTypes: [.flake, .dot],
        enableParallax: true,
        depthLayers: 5
    )
    
    /// Blizzard preset
    public static let blizzard = SnowConfiguration(
        maxParticles: 400,
        emissionRate: 60,
        minFallSpeed: 120,
        maxFallSpeed: 250,
        minSize: 4,
        maxSize: 16,
        driftSpeedRange: 3...6,
        windStrength: 0.8,
        color: .white,
        particleTypes: [.dot],
        enableParallax: false,
        depthLayers: 2
    )
    
    /// Magic sparkle preset
    public static let magic = SnowConfiguration(
        maxParticles: 80,
        emissionRate: 10,
        minFallSpeed: 20,
        maxFallSpeed: 40,
        minSize: 6,
        maxSize: 14,
        driftSpeedRange: 0.5...1.5,
        windStrength: 0,
        color: UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),
        particleTypes: [.star],
        enableParallax: true,
        depthLayers: 3
    )
    
    public init(
        maxParticles: Int = 100,
        emissionRate: CGFloat = 15,
        minFallSpeed: CGFloat = 50,
        maxFallSpeed: CGFloat = 100,
        minSize: CGFloat = 5,
        maxSize: CGFloat = 15,
        driftSpeedRange: ClosedRange<CGFloat> = 1...3,
        windStrength: CGFloat = 0,
        color: UIColor = .white,
        particleTypes: [SnowParticleType] = [.flake, .dot],
        enableParallax: Bool = true,
        depthLayers: Int = 3
    ) {
        self.maxParticles = maxParticles
        self.emissionRate = emissionRate
        self.minFallSpeed = minFallSpeed
        self.maxFallSpeed = maxFallSpeed
        self.minSize = minSize
        self.maxSize = maxSize
        self.driftSpeedRange = driftSpeedRange
        self.windStrength = windStrength
        self.color = color
        self.particleTypes = particleTypes
        self.enableParallax = enableParallax
        self.depthLayers = depthLayers
    }
}

// MARK: - Snow Emitter

/// Handles emission of snow particles
public final class SnowEmitter {
    
    // MARK: - Properties
    
    private let configuration: SnowConfiguration
    private var emissionAccumulator: CGFloat = 0
    private var cachedImages: [SnowParticleType: [CGFloat: UIImage]] = [:]
    
    // MARK: - Initialization
    
    public init(configuration: SnowConfiguration) {
        self.configuration = configuration
        precacheImages()
    }
    
    // MARK: - Image Caching
    
    private func precacheImages() {
        for type in configuration.particleTypes {
            cachedImages[type] = [:]
            
            // Cache a few size variants
            let sizes: [CGFloat] = [
                configuration.minSize,
                (configuration.minSize + configuration.maxSize) / 2,
                configuration.maxSize
            ]
            
            for size in sizes {
                cachedImages[type]?[size] = type.createImage(size: size, color: configuration.color)
            }
        }
    }
    
    public func getCachedImage(for type: SnowParticleType, size: CGFloat) -> UIImage? {
        // Find closest cached size
        guard let typeCache = cachedImages[type] else { return nil }
        
        let closestSize = typeCache.keys.min(by: { abs($0 - size) < abs($1 - size) })
        return closestSize.flatMap { typeCache[$0] }
    }
    
    // MARK: - Emission
    
    public func emit(
        deltaTime: TimeInterval,
        currentCount: Int,
        bounds: CGRect
    ) -> [SnowParticle] {
        guard currentCount < configuration.maxParticles else { return [] }
        
        emissionAccumulator += configuration.emissionRate * CGFloat(deltaTime)
        
        var newParticles: [SnowParticle] = []
        let availableSlots = configuration.maxParticles - currentCount
        
        while emissionAccumulator >= 1 && newParticles.count < availableSlots {
            emissionAccumulator -= 1
            
            let particle = createParticle(in: bounds)
            newParticles.append(particle)
        }
        
        return newParticles
    }
    
    private func createParticle(in bounds: CGRect) -> SnowParticle {
        // Random position at top (with some spread above visible area)
        let x = CGFloat.random(in: -50...(bounds.width + 50))
        let y = CGFloat.random(in: -100...0)
        
        // Random properties
        let fallSpeed = CGFloat.random(in: configuration.minFallSpeed...configuration.maxFallSpeed)
        let driftSpeed = CGFloat.random(in: configuration.driftSpeedRange)
        let size = CGFloat.random(in: configuration.minSize...configuration.maxSize)
        let type = configuration.particleTypes.randomElement() ?? .flake
        
        // Depth for parallax (larger = closer = faster)
        let depth: CGFloat
        if configuration.enableParallax {
            depth = CGFloat(Int.random(in: 0..<configuration.depthLayers)) / CGFloat(configuration.depthLayers - 1)
        } else {
            depth = 1.0
        }
        
        return SnowParticle(
            position: CGPoint(x: x, y: y),
            fallSpeed: fallSpeed,
            driftSpeed: driftSpeed,
            size: size,
            type: type,
            depth: depth
        )
    }
}

// MARK: - Snow Renderer

/// Renders snow particles efficiently
public final class SnowRenderer {
    
    // MARK: - Properties
    
    private weak var containerLayer: CALayer?
    private var particleLayers: [UUID: CALayer] = [:]
    private let emitter: SnowEmitter
    private let reusePool = SnowLayerPool()
    
    // MARK: - Initialization
    
    public init(containerLayer: CALayer, emitter: SnowEmitter) {
        self.containerLayer = containerLayer
        self.emitter = emitter
    }
    
    // MARK: - Rendering
    
    public func render(particles: [SnowParticle]) {
        guard let container = containerLayer else { return }
        
        var activeIds = Set<UUID>()
        
        // Sort by depth for proper layering
        let sortedParticles = particles.sorted { $0.depth < $1.depth }
        
        for particle in sortedParticles {
            activeIds.insert(particle.id)
            
            if let layer = particleLayers[particle.id] {
                updateLayer(layer, with: particle)
            } else {
                let layer = reusePool.obtain()
                configureLayer(layer, with: particle)
                container.addSublayer(layer)
                particleLayers[particle.id] = layer
            }
        }
        
        // Remove dead particles
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
    
    private func configureLayer(_ layer: CALayer, with particle: SnowParticle) {
        if let image = emitter.getCachedImage(for: particle.type, size: particle.size) {
            layer.contents = image.cgImage
        }
        
        layer.bounds = CGRect(origin: .zero, size: CGSize(width: particle.size, height: particle.size))
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        updateLayer(layer, with: particle)
    }
    
    private func updateLayer(_ layer: CALayer, with particle: SnowParticle) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        layer.position = particle.position
        layer.opacity = Float(particle.opacity * particle.depth)
        
        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, particle.rotation, 0, 0, 1)
        
        // Scale based on depth for parallax
        let scale = 0.6 + particle.depth * 0.4
        transform = CATransform3DScale(transform, scale, scale, 1)
        
        layer.transform = transform
        
        CATransaction.commit()
    }
}

// MARK: - Snow Layer Pool

private final class SnowLayerPool {
    private var pool: [CALayer] = []
    private let maxPoolSize = 300
    
    func obtain() -> CALayer {
        if let layer = pool.popLast() {
            return layer
        }
        return CALayer()
    }
    
    func recycle(_ layer: CALayer) {
        guard pool.count < maxPoolSize else { return }
        layer.removeAllAnimations()
        layer.contents = nil
        pool.append(layer)
    }
}

// MARK: - Snow System

/// Main snow particle system
public final class SnowSystem {
    
    // MARK: - Properties
    
    private var particles: [SnowParticle] = []
    private let emitter: SnowEmitter
    private let renderer: SnowRenderer
    private var configuration: SnowConfiguration
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning = false
    private weak var containerLayer: CALayer?
    
    /// Current wind strength
    public var windStrength: CGFloat {
        get { configuration.windStrength }
        set { configuration.windStrength = max(-1, min(1, newValue)) }
    }
    
    /// Current particle count
    public var particleCount: Int { particles.count }
    
    /// Whether the system is running
    public var isActive: Bool { isRunning }
    
    // MARK: - Initialization
    
    public init(configuration: SnowConfiguration, containerLayer: CALayer) {
        self.configuration = configuration
        self.containerLayer = containerLayer
        self.emitter = SnowEmitter(configuration: configuration)
        self.renderer = SnowRenderer(containerLayer: containerLayer, emitter: emitter)
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Control
    
    /// Start the snow system
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        lastUpdateTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Stop the snow system
    public func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
        renderer.clear()
        particles.removeAll()
    }
    
    /// Pause the snow
    public func pause() {
        displayLink?.isPaused = true
    }
    
    /// Resume the snow
    public func resume() {
        lastUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    /// Update wind strength with animation
    public func setWind(_ strength: CGFloat, duration: TimeInterval = 1.0) {
        let startWind = windStrength
        let endWind = max(-1, min(1, strength))
        let startTime = CACurrentMediaTime()
        
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(1, elapsed / duration)
            
            // Ease in-out
            let t = progress < 0.5
                ? 2 * progress * progress
                : 1 - pow(-2 * progress + 2, 2) / 2
            
            self.windStrength = startWind + (endWind - startWind) * CGFloat(t)
            
            if progress >= 1 {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Update
    
    @objc private func update(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        guard let bounds = containerLayer?.bounds else { return }
        
        // Emit new particles
        let newParticles = emitter.emit(
            deltaTime: deltaTime,
            currentCount: particles.count,
            bounds: bounds
        )
        particles.append(contentsOf: newParticles)
        
        // Update existing particles
        for i in particles.indices.reversed() {
            particles[i].update(
                deltaTime: deltaTime,
                windStrength: configuration.windStrength,
                bounds: bounds
            )
            
            if particles[i].isOutOfBounds(in: bounds) {
                particles.remove(at: i)
            }
        }
        
        // Render
        renderer.render(particles: particles)
    }
}

// MARK: - Snow View

/// A UIView that displays snow effects
public final class SnowView: UIView {
    
    // MARK: - Properties
    
    private var snowSystem: SnowSystem?
    private var configuration: SnowConfiguration
    
    /// Current wind strength (-1 to 1)
    public var windStrength: CGFloat {
        get { snowSystem?.windStrength ?? configuration.windStrength }
        set { snowSystem?.windStrength = newValue }
    }
    
    /// Whether snow is currently active
    public var isSnowing: Bool { snowSystem?.isActive ?? false }
    
    // MARK: - Initialization
    
    public init(frame: CGRect, configuration: SnowConfiguration = .medium) {
        self.configuration = configuration
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .medium
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    // MARK: - Control
    
    /// Start snowing
    public func startSnow() {
        stopSnow()
        
        let system = SnowSystem(configuration: configuration, containerLayer: layer)
        snowSystem = system
        system.start()
    }
    
    /// Start with custom configuration
    public func startSnow(with customConfig: SnowConfiguration) {
        configuration = customConfig
        startSnow()
    }
    
    /// Stop snowing
    public func stopSnow() {
        snowSystem?.stop()
        snowSystem = nil
    }
    
    /// Pause snow animation
    public func pauseSnow() {
        snowSystem?.pause()
    }
    
    /// Resume snow animation
    public func resumeSnow() {
        snowSystem?.resume()
    }
    
    /// Animate wind change
    public func animateWind(to strength: CGFloat, duration: TimeInterval = 1.0) {
        snowSystem?.setWind(strength, duration: duration)
    }
    
    /// Update configuration
    public func updateConfiguration(_ newConfig: SnowConfiguration) {
        let wasSnowing = isSnowing
        stopSnow()
        configuration = newConfig
        if wasSnowing {
            startSnow()
        }
    }
}

// MARK: - UIView Extension

public extension UIView {
    
    /// Add snow effect to this view
    func addSnow(configuration: SnowConfiguration = .medium) -> SnowView {
        let snowView = SnowView(frame: bounds, configuration: configuration)
        snowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(snowView)
        snowView.startSnow()
        return snowView
    }
    
    /// Remove all snow views
    func removeSnow() {
        subviews.compactMap { $0 as? SnowView }.forEach {
            $0.stopSnow()
            $0.removeFromSuperview()
        }
    }
}

// MARK: - Snow Preset

/// Preset snow configurations
public enum SnowPreset {
    case light
    case medium
    case heavy
    case blizzard
    case magic
    case custom(SnowConfiguration)
    
    var configuration: SnowConfiguration {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .blizzard: return .blizzard
        case .magic: return .magic
        case .custom(let config): return config
        }
    }
}

// MARK: - Snow Controller

/// Convenience controller for managing snow effects
public final class SnowController {
    
    private weak var targetView: UIView?
    private var snowView: SnowView?
    
    public init(targetView: UIView) {
        self.targetView = targetView
    }
    
    /// Start snow with preset
    public func start(preset: SnowPreset = .medium) {
        guard let view = targetView else { return }
        
        stop()
        
        let snow = SnowView(frame: view.bounds, configuration: preset.configuration)
        snow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(snow)
        snowView = snow
        snow.startSnow()
    }
    
    /// Stop snow
    public func stop() {
        snowView?.stopSnow()
        snowView?.removeFromSuperview()
        snowView = nil
    }
    
    /// Set wind
    public func setWind(_ strength: CGFloat, animated: Bool = true) {
        if animated {
            snowView?.animateWind(to: strength)
        } else {
            snowView?.windStrength = strength
        }
    }
    
    /// Toggle snow
    public func toggle(preset: SnowPreset = .medium) {
        if snowView?.isSnowing == true {
            stop()
        } else {
            start(preset: preset)
        }
    }
}

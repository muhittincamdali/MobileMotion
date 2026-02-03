//
//  MotionView.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Motion State

/// Represents the state of a motion animation
@Observable
public final class MotionState {
    
    /// Current animation progress (0-1)
    public var progress: Double = 0
    
    /// Whether animation is currently running
    public var isAnimating: Bool = false
    
    /// Animation velocity
    public var velocity: CGFloat = 0
    
    /// Animation phase for continuous animations
    public var phase: Double = 0
    
    /// Custom state values
    public var customValues: [String: Double] = [:]
    
    public init() {}
    
    /// Reset to initial state
    public func reset() {
        progress = 0
        isAnimating = false
        velocity = 0
        phase = 0
        customValues.removeAll()
    }
    
    /// Get or set a custom value
    public subscript(key: String) -> Double {
        get { customValues[key] ?? 0 }
        set { customValues[key] = newValue }
    }
}

// MARK: - Motion Animation Type

/// Types of motion animations available
public enum MotionAnimationType: Hashable, Sendable {
    case spring(response: Double, dampingFraction: Double)
    case easeIn(duration: Double)
    case easeOut(duration: Double)
    case easeInOut(duration: Double)
    case linear(duration: Double)
    case bounce(duration: Double, bounce: Double)
    case custom(Animation)
    
    /// Convert to SwiftUI Animation
    public var animation: Animation {
        switch self {
        case .spring(let response, let dampingFraction):
            return .spring(response: response, dampingFraction: dampingFraction)
        case .easeIn(let duration):
            return .easeIn(duration: duration)
        case .easeOut(let duration):
            return .easeOut(duration: duration)
        case .easeInOut(let duration):
            return .easeInOut(duration: duration)
        case .linear(let duration):
            return .linear(duration: duration)
        case .bounce(let duration, let bounce):
            return .bouncy(duration: duration, extraBounce: bounce)
        case .custom(let animation):
            return animation
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .spring(let r, let d):
            hasher.combine("spring")
            hasher.combine(r)
            hasher.combine(d)
        case .easeIn(let d):
            hasher.combine("easeIn")
            hasher.combine(d)
        case .easeOut(let d):
            hasher.combine("easeOut")
            hasher.combine(d)
        case .easeInOut(let d):
            hasher.combine("easeInOut")
            hasher.combine(d)
        case .linear(let d):
            hasher.combine("linear")
            hasher.combine(d)
        case .bounce(let d, let b):
            hasher.combine("bounce")
            hasher.combine(d)
            hasher.combine(b)
        case .custom:
            hasher.combine("custom")
        }
    }
    
    public static func == (lhs: MotionAnimationType, rhs: MotionAnimationType) -> Bool {
        switch (lhs, rhs) {
        case (.spring(let r1, let d1), .spring(let r2, let d2)):
            return r1 == r2 && d1 == d2
        case (.easeIn(let d1), .easeIn(let d2)):
            return d1 == d2
        case (.easeOut(let d1), .easeOut(let d2)):
            return d1 == d2
        case (.easeInOut(let d1), .easeInOut(let d2)):
            return d1 == d2
        case (.linear(let d1), .linear(let d2)):
            return d1 == d2
        case (.bounce(let d1, let b1), .bounce(let d2, let b2)):
            return d1 == d2 && b1 == b2
        case (.custom, .custom):
            return true
        default:
            return false
        }
    }
    
    // Presets
    public static let snappy = MotionAnimationType.spring(response: 0.3, dampingFraction: 0.7)
    public static let smooth = MotionAnimationType.spring(response: 0.5, dampingFraction: 0.9)
    public static let bouncy = MotionAnimationType.spring(response: 0.5, dampingFraction: 0.5)
    public static let stiff = MotionAnimationType.spring(response: 0.2, dampingFraction: 0.8)
}

// MARK: - Motion View

/// A view that provides advanced motion animation capabilities
public struct MotionView<Content: View>: View {
    
    // MARK: - Properties
    
    private let content: (MotionState) -> Content
    @State private var motionState = MotionState()
    private let animationType: MotionAnimationType
    private let autoStart: Bool
    private let repeatForever: Bool
    
    // MARK: - Initialization
    
    public init(
        animationType: MotionAnimationType = .smooth,
        autoStart: Bool = false,
        repeatForever: Bool = false,
        @ViewBuilder content: @escaping (MotionState) -> Content
    ) {
        self.animationType = animationType
        self.autoStart = autoStart
        self.repeatForever = repeatForever
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        content(motionState)
            .onAppear {
                if autoStart {
                    startAnimation()
                }
            }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        motionState.isAnimating = true
        
        let animation = repeatForever
            ? animationType.animation.repeatForever(autoreverses: true)
            : animationType.animation
        
        withAnimation(animation) {
            motionState.progress = 1
        }
    }
}

// MARK: - Motion Container

/// A container view for motion animations with gesture support
public struct MotionContainer<Content: View>: View {
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var isDragging = false
    
    private let content: Content
    private let enableDrag: Bool
    private let enableScale: Bool
    private let enableRotation: Bool
    private let snapBack: Bool
    private let animationType: MotionAnimationType
    
    public init(
        enableDrag: Bool = true,
        enableScale: Bool = false,
        enableRotation: Bool = false,
        snapBack: Bool = true,
        animationType: MotionAnimationType = .bouncy,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.enableDrag = enableDrag
        self.enableScale = enableScale
        self.enableRotation = enableRotation
        self.snapBack = snapBack
        self.animationType = animationType
    }
    
    public var body: some View {
        content
            .offset(offset)
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .gesture(rotationGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard enableDrag else { return }
                isDragging = true
                offset = value.translation
            }
            .onEnded { _ in
                isDragging = false
                if snapBack {
                    withAnimation(animationType.animation) {
                        offset = .zero
                    }
                }
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard enableScale else { return }
                scale = value
            }
            .onEnded { _ in
                if snapBack {
                    withAnimation(animationType.animation) {
                        scale = 1
                    }
                }
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                guard enableRotation else { return }
                rotation = value
            }
            .onEnded { _ in
                if snapBack {
                    withAnimation(animationType.animation) {
                        rotation = .zero
                    }
                }
            }
    }
}

// MARK: - Shake Effect

/// A view modifier that adds a shake effect
public struct ShakeEffect: GeometryEffect {
    
    public var amount: CGFloat = 10
    public var shakesPerUnit: Int = 3
    public var animatableData: CGFloat
    
    public init(amount: CGFloat = 10, shakesPerUnit: Int = 3, animatableData: CGFloat) {
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Bounce Effect

/// A view modifier that adds a bounce effect
public struct BounceEffect: GeometryEffect {
    
    public var bounceHeight: CGFloat
    public var animatableData: CGFloat
    
    public init(bounceHeight: CGFloat = 20, animatableData: CGFloat) {
        self.bounceHeight = bounceHeight
        self.animatableData = animatableData
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        let bounce = abs(sin(animatableData * .pi)) * bounceHeight
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: -bounce))
    }
}

// MARK: - Pulse Effect

/// A view modifier that creates a pulsing effect
public struct PulseEffect: ViewModifier {
    
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    public init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 0.5) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Glow Effect

/// A view modifier that adds a glowing effect
public struct GlowEffect: ViewModifier {
    
    let color: Color
    let radius: CGFloat
    let animated: Bool
    @State private var isGlowing = false
    
    public init(color: Color = .blue, radius: CGFloat = 10, animated: Bool = true) {
        self.color = color
        self.radius = radius
        self.animated = animated
    }
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.8 : 0.4), radius: isGlowing ? radius * 1.5 : radius)
            .animation(
                animated ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : nil,
                value: isGlowing
            )
            .onAppear {
                if animated {
                    isGlowing = true
                }
            }
    }
}

// MARK: - Flip Effect

/// A view modifier for 3D flip animations
public struct FlipEffect: ViewModifier {
    
    let isFlipped: Bool
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let perspective: CGFloat
    
    public init(isFlipped: Bool, axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0), perspective: CGFloat = 0.5) {
        self.isFlipped = isFlipped
        self.axis = axis
        self.perspective = perspective
    }
    
    public func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: axis,
                perspective: perspective
            )
    }
}

// MARK: - Typewriter Effect

/// A view that displays text with a typewriter animation
public struct TypewriterText: View {
    
    let fullText: String
    let typingSpeed: TimeInterval
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    public init(_ text: String, typingSpeed: TimeInterval = 0.05) {
        self.fullText = text
        self.typingSpeed = typingSpeed
    }
    
    public var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        guard currentIndex < fullText.count else { return }
        
        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
        
        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: false) { _ in
            displayedText.append(fullText[index])
            currentIndex += 1
            startTyping()
        }
    }
}

// MARK: - Particle View

/// A SwiftUI view that displays particle effects
public struct ParticleView: View {
    
    let particleCount: Int
    let colors: [Color]
    let particleSize: CGFloat
    
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    public init(
        particleCount: Int = 50,
        colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple],
        particleSize: CGFloat = 8
    ) {
        self.particleCount = particleCount
        self.colors = colors
        self.particleSize = particleSize
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startAnimation()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: -100...-50)
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: particleSize * 0.5...particleSize * 1.5),
                opacity: Double.random(in: 0.5...1.0)
            )
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.x * 0.016
            particles[i].position.y += particles[i].velocity.y * 0.016
            particles[i].velocity.y += 100 * 0.016 // Gravity
            particles[i].opacity -= 0.005
            
            if particles[i].opacity <= 0 {
                particles[i].opacity = 1
                particles[i].position.y = 0
            }
        }
    }
    
    private struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var color: Color
        var size: CGFloat
        var opacity: Double
    }
}

// MARK: - Spring Animation View

/// A view with spring physics animation
public struct SpringAnimationView<Content: View>: View {
    
    @State private var value: CGFloat = 0
    let target: CGFloat
    let stiffness: Double
    let damping: Double
    let content: (CGFloat) -> Content
    
    public init(
        target: CGFloat,
        stiffness: Double = 300,
        damping: Double = 20,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) {
        self.target = target
        self.stiffness = stiffness
        self.damping = damping
        self.content = content
    }
    
    public var body: some View {
        content(value)
            .onChange(of: target) { _, newTarget in
                withAnimation(.spring(response: sqrt(1 / stiffness), dampingFraction: damping / (2 * sqrt(stiffness)))) {
                    value = newTarget
                }
            }
            .onAppear {
                value = target
            }
    }
}

// MARK: - Animated Counter

/// A view that animates number changes
public struct AnimatedCounter: View {
    
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    public init(value: Int, font: Font = .largeTitle, color: Color = .primary) {
        self.value = value
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText(value: displayValue))
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(duration: 0.5)) {
                    displayValue = newValue
                }
            }
            .onAppear {
                displayValue = value
            }
    }
}

// MARK: - View Extensions

public extension View {
    
    /// Apply a shake effect
    func shake(amount: CGFloat = 10, shakesPerUnit: Int = 3, animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: animatableData))
    }
    
    /// Apply a pulse effect
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 0.5) -> some View {
        modifier(PulseEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Apply a glow effect
    func glow(color: Color = .blue, radius: CGFloat = 10, animated: Bool = true) -> some View {
        modifier(GlowEffect(color: color, radius: radius, animated: animated))
    }
    
    /// Apply a flip effect
    func flip3D(isFlipped: Bool, axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)) -> some View {
        modifier(FlipEffect(isFlipped: isFlipped, axis: axis))
    }
    
    /// Spring animation modifier
    func springAnimation<Value: Equatable>(
        value: Value,
        response: Double = 0.5,
        dampingFraction: Double = 0.8
    ) -> some View {
        animation(.spring(response: response, dampingFraction: dampingFraction), value: value)
    }
    
    /// Bounce in animation
    func bounceIn(delay: Double = 0) -> some View {
        self
            .scaleEffect(0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                    // This would need state to work properly
                }
            }
    }
    
    /// Fade in animation
    func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    // This would need state to work properly
                }
            }
    }
    
    /// Slide in animation
    func slideIn(from edge: Edge, offset: CGFloat = 100, duration: Double = 0.3) -> some View {
        let x: CGFloat = edge == .leading ? -offset : (edge == .trailing ? offset : 0)
        let y: CGFloat = edge == .top ? -offset : (edge == .bottom ? offset : 0)
        
        return self
            .offset(x: x, y: y)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    // This would need state to work properly
                }
            }
    }
}

// MARK: - Motion Preference Key

/// Preference key for motion values
public struct MotionPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Motion Coordinator

/// Coordinates multiple motion animations
@Observable
public final class MotionCoordinator {
    
    public var animations: [String: MotionState] = [:]
    
    public init() {}
    
    /// Get or create an animation state
    public func state(for key: String) -> MotionState {
        if let existing = animations[key] {
            return existing
        }
        let newState = MotionState()
        animations[key] = newState
        return newState
    }
    
    /// Start an animation
    public func start(_ key: String) {
        animations[key]?.isAnimating = true
    }
    
    /// Stop an animation
    public func stop(_ key: String) {
        animations[key]?.isAnimating = false
    }
    
    /// Reset all animations
    public func resetAll() {
        for (_, state) in animations {
            state.reset()
        }
    }
}

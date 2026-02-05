//
//  PageCurlTransition.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - Page Curl Direction

/// Defines the direction of the page curl animation
public enum PageCurlDirection: Int, CaseIterable, Sendable {
    case left
    case right
    case up
    case down
    
    /// The starting anchor point for the curl
    var startAnchor: CGPoint {
        switch self {
        case .left: return CGPoint(x: 1.0, y: 0.5)
        case .right: return CGPoint(x: 0.0, y: 0.5)
        case .up: return CGPoint(x: 0.5, y: 1.0)
        case .down: return CGPoint(x: 0.5, y: 0.0)
        }
    }
    
    /// The ending anchor point for the curl
    var endAnchor: CGPoint {
        switch self {
        case .left: return CGPoint(x: 0.0, y: 0.5)
        case .right: return CGPoint(x: 1.0, y: 0.5)
        case .up: return CGPoint(x: 0.5, y: 0.0)
        case .down: return CGPoint(x: 0.5, y: 1.0)
        }
    }
    
    /// The rotation axis for 3D transform
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch self {
        case .left, .right: return (0, 1, 0)
        case .up, .down: return (1, 0, 0)
        }
    }
    
    /// The rotation angle direction multiplier
    var angleMultiplier: CGFloat {
        switch self {
        case .left, .up: return 1.0
        case .right, .down: return -1.0
        }
    }
}

// MARK: - Page Curl Style

/// Visual style options for the page curl effect
public struct PageCurlStyle: Sendable {
    /// Shadow opacity during curl (0.0 - 1.0)
    public var shadowOpacity: Float
    
    /// Shadow radius for the curled edge
    public var shadowRadius: CGFloat
    
    /// Shadow offset from the curl
    public var shadowOffset: CGSize
    
    /// Whether to show page backside
    public var showBackside: Bool
    
    /// Backside color if visible
    public var backsideColor: UIColor
    
    /// Curl radius at maximum
    public var maxCurlRadius: CGFloat
    
    /// Enable 3D perspective
    public var enable3DPerspective: Bool
    
    /// Perspective depth (smaller = more dramatic)
    public var perspectiveDepth: CGFloat
    
    /// Default style preset
    public static let `default` = PageCurlStyle(
        shadowOpacity: 0.5,
        shadowRadius: 10,
        shadowOffset: CGSize(width: -5, height: 5),
        showBackside: true,
        backsideColor: .systemGray6,
        maxCurlRadius: 50,
        enable3DPerspective: true,
        perspectiveDepth: 1000
    )
    
    /// Subtle curl style
    public static let subtle = PageCurlStyle(
        shadowOpacity: 0.3,
        shadowRadius: 5,
        shadowOffset: CGSize(width: -2, height: 2),
        showBackside: true,
        backsideColor: .systemGray5,
        maxCurlRadius: 30,
        enable3DPerspective: true,
        perspectiveDepth: 1500
    )
    
    /// Dramatic curl style
    public static let dramatic = PageCurlStyle(
        shadowOpacity: 0.7,
        shadowRadius: 20,
        shadowOffset: CGSize(width: -10, height: 10),
        showBackside: true,
        backsideColor: .white,
        maxCurlRadius: 80,
        enable3DPerspective: true,
        perspectiveDepth: 500
    )
    
    public init(
        shadowOpacity: Float = 0.5,
        shadowRadius: CGFloat = 10,
        shadowOffset: CGSize = CGSize(width: -5, height: 5),
        showBackside: Bool = true,
        backsideColor: UIColor = .systemGray6,
        maxCurlRadius: CGFloat = 50,
        enable3DPerspective: Bool = true,
        perspectiveDepth: CGFloat = 1000
    ) {
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.showBackside = showBackside
        self.backsideColor = backsideColor
        self.maxCurlRadius = maxCurlRadius
        self.enable3DPerspective = enable3DPerspective
        self.perspectiveDepth = perspectiveDepth
    }
}

// MARK: - Page Curl Configuration

/// Complete configuration for page curl transitions
public struct PageCurlConfiguration: Sendable {
    /// Animation duration
    public var duration: TimeInterval
    
    /// Curl direction
    public var direction: PageCurlDirection
    
    /// Visual style
    public var style: PageCurlStyle
    
    /// Animation timing function
    public var timingFunction: CAMediaTimingFunction
    
    /// Enable interactive gesture control
    public var isInteractive: Bool
    
    /// Minimum velocity for completion
    public var completionVelocityThreshold: CGFloat
    
    /// Progress threshold for automatic completion
    public var completionProgressThreshold: CGFloat
    
    /// Enable haptic feedback
    public var enableHaptics: Bool
    
    /// Default configuration
    public static let `default` = PageCurlConfiguration(
        duration: 0.5,
        direction: .left,
        style: .default,
        timingFunction: CAMediaTimingFunction(name: .easeInEaseOut),
        isInteractive: true,
        completionVelocityThreshold: 500,
        completionProgressThreshold: 0.5,
        enableHaptics: true
    )
    
    public init(
        duration: TimeInterval = 0.5,
        direction: PageCurlDirection = .left,
        style: PageCurlStyle = .default,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut),
        isInteractive: Bool = true,
        completionVelocityThreshold: CGFloat = 500,
        completionProgressThreshold: CGFloat = 0.5,
        enableHaptics: Bool = true
    ) {
        self.duration = duration
        self.direction = direction
        self.style = style
        self.timingFunction = timingFunction
        self.isInteractive = isInteractive
        self.completionVelocityThreshold = completionVelocityThreshold
        self.completionProgressThreshold = completionProgressThreshold
        self.enableHaptics = enableHaptics
    }
}

// MARK: - Page Curl Layer

/// Custom layer for rendering page curl effect
public final class PageCurlLayer: CALayer {
    
    /// Current curl progress (0.0 - 1.0)
    @NSManaged public var curlProgress: CGFloat
    
    /// Curl radius
    @NSManaged public var curlRadius: CGFloat
    
    /// Shadow intensity
    @NSManaged public var shadowIntensity: CGFloat
    
    private var curlDirection: PageCurlDirection = .left
    private var style: PageCurlStyle = .default
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLayer()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let curlLayer = layer as? PageCurlLayer {
            curlProgress = curlLayer.curlProgress
            curlRadius = curlLayer.curlRadius
            shadowIntensity = curlLayer.shadowIntensity
            curlDirection = curlLayer.curlDirection
            style = curlLayer.style
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        curlProgress = 0
        curlRadius = 50
        shadowIntensity = 0.5
        needsDisplayOnBoundsChange = true
    }
    
    // MARK: - Configuration
    
    public func configure(direction: PageCurlDirection, style: PageCurlStyle) {
        self.curlDirection = direction
        self.style = style
        self.curlRadius = style.maxCurlRadius
        setNeedsDisplay()
    }
    
    // MARK: - Animation Support
    
    public override class func needsDisplay(forKey key: String) -> Bool {
        if key == "curlProgress" || key == "curlRadius" || key == "shadowIntensity" {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    public override func action(forKey event: String) -> CAAction? {
        if event == "curlProgress" || event == "curlRadius" || event == "shadowIntensity" {
            let animation = CABasicAnimation(keyPath: event)
            animation.fromValue = presentation()?.value(forKey: event)
            return animation
        }
        return super.action(forKey: event)
    }
    
    // MARK: - Drawing
    
    public override func draw(in ctx: CGContext) {
        guard let contents = contents else {
            super.draw(in: ctx)
            return
        }
        
        let progress = presentation()?.curlProgress ?? curlProgress
        let radius = presentation()?.curlRadius ?? curlRadius
        let shadow = presentation()?.shadowIntensity ?? shadowIntensity
        
        drawPageCurl(
            in: ctx,
            contents: contents,
            progress: progress,
            radius: radius,
            shadowIntensity: shadow
        )
    }
    
    private func drawPageCurl(
        in ctx: CGContext,
        contents: Any,
        progress: CGFloat,
        radius: CGFloat,
        shadowIntensity: CGFloat
    ) {
        let rect = bounds
        
        // Calculate curl position based on progress and direction
        let curlPosition = calculateCurlPosition(progress: progress, in: rect)
        
        // Draw the main page content
        ctx.saveGState()
        
        // Apply clipping for the visible part of the page
        let visiblePath = createVisiblePath(curlPosition: curlPosition, in: rect)
        ctx.addPath(visiblePath)
        ctx.clip()
        
        // Draw the page content
        if let cgImage = contents as? CGImage {
            ctx.draw(cgImage, in: rect)
        }
        
        ctx.restoreGState()
        
        // Draw the curled part if showing backside
        if style.showBackside && progress > 0 {
            drawCurledBackside(
                in: ctx,
                curlPosition: curlPosition,
                radius: radius,
                in: rect
            )
        }
        
        // Draw shadow
        if shadowIntensity > 0 && progress > 0 {
            drawCurlShadow(
                in: ctx,
                curlPosition: curlPosition,
                intensity: shadowIntensity,
                in: rect
            )
        }
    }
    
    private func calculateCurlPosition(progress: CGFloat, in rect: CGRect) -> CGFloat {
        switch curlDirection {
        case .left:
            return rect.width * (1 - progress)
        case .right:
            return rect.width * progress
        case .up:
            return rect.height * (1 - progress)
        case .down:
            return rect.height * progress
        }
    }
    
    private func createVisiblePath(curlPosition: CGFloat, in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        
        switch curlDirection {
        case .left:
            path.addRect(CGRect(x: 0, y: 0, width: curlPosition, height: rect.height))
        case .right:
            path.addRect(CGRect(x: curlPosition, y: 0, width: rect.width - curlPosition, height: rect.height))
        case .up:
            path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: curlPosition))
        case .down:
            path.addRect(CGRect(x: 0, y: curlPosition, width: rect.width, height: rect.height - curlPosition))
        }
        
        return path
    }
    
    private func drawCurledBackside(
        in ctx: CGContext,
        curlPosition: CGFloat,
        radius: CGFloat,
        in rect: CGRect
    ) {
        ctx.saveGState()
        
        // Create backside gradient
        let colors = [
            style.backsideColor.cgColor,
            style.backsideColor.withAlphaComponent(0.8).cgColor
        ]
        
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else {
            ctx.restoreGState()
            return
        }
        
        let backsideRect: CGRect
        switch curlDirection {
        case .left:
            backsideRect = CGRect(x: curlPosition, y: 0, width: radius, height: rect.height)
        case .right:
            backsideRect = CGRect(x: curlPosition - radius, y: 0, width: radius, height: rect.height)
        case .up:
            backsideRect = CGRect(x: 0, y: curlPosition, width: rect.width, height: radius)
        case .down:
            backsideRect = CGRect(x: 0, y: curlPosition - radius, width: rect.width, height: radius)
        }
        
        ctx.addRect(backsideRect)
        ctx.clip()
        
        ctx.drawLinearGradient(
            gradient,
            start: backsideRect.origin,
            end: CGPoint(x: backsideRect.maxX, y: backsideRect.maxY),
            options: []
        )
        
        ctx.restoreGState()
    }
    
    private func drawCurlShadow(
        in ctx: CGContext,
        curlPosition: CGFloat,
        intensity: CGFloat,
        in rect: CGRect
    ) {
        ctx.saveGState()
        
        let shadowColor = UIColor.black.withAlphaComponent(intensity * CGFloat(style.shadowOpacity))
        ctx.setShadow(
            offset: style.shadowOffset,
            blur: style.shadowRadius,
            color: shadowColor.cgColor
        )
        
        // Draw shadow line at curl edge
        ctx.setStrokeColor(UIColor.clear.cgColor)
        ctx.setLineWidth(2)
        
        switch curlDirection {
        case .left, .right:
            ctx.move(to: CGPoint(x: curlPosition, y: 0))
            ctx.addLine(to: CGPoint(x: curlPosition, y: rect.height))
        case .up, .down:
            ctx.move(to: CGPoint(x: 0, y: curlPosition))
            ctx.addLine(to: CGPoint(x: rect.width, y: curlPosition))
        }
        
        ctx.strokePath()
        ctx.restoreGState()
    }
}

// MARK: - Page Curl Animator

/// Handles the animation logic for page curl transitions
public final class PageCurlAnimator: NSObject {
    
    // MARK: - Properties
    
    private let configuration: PageCurlConfiguration
    private weak var sourceView: UIView?
    private weak var destinationView: UIView?
    private var curlLayer: PageCurlLayer?
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var isAnimating = false
    
    /// Current progress of the animation
    public private(set) var progress: CGFloat = 0
    
    /// Completion handler
    public var onCompletion: ((Bool) -> Void)?
    
    /// Progress update handler
    public var onProgressUpdate: ((CGFloat) -> Void)?
    
    // MARK: - Initialization
    
    public init(configuration: PageCurlConfiguration = .default) {
        self.configuration = configuration
        super.init()
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Public Methods
    
    /// Setup the page curl transition between two views
    public func setup(from sourceView: UIView, to destinationView: UIView) {
        self.sourceView = sourceView
        self.destinationView = destinationView
        
        setupCurlLayer()
    }
    
    /// Start the page curl animation
    public func startAnimation() {
        guard !isAnimating else { return }
        
        isAnimating = true
        animationStartTime = CACurrentMediaTime()
        
        if configuration.enableHaptics {
            generateHapticFeedback(style: .light)
        }
        
        startDisplayLink()
    }
    
    /// Update animation with interactive progress
    public func updateProgress(_ newProgress: CGFloat) {
        progress = max(0, min(1, newProgress))
        curlLayer?.curlProgress = progress
        curlLayer?.shadowIntensity = progress
        onProgressUpdate?(progress)
    }
    
    /// Complete the animation
    public func completeAnimation(cancelled: Bool = false) {
        stopDisplayLink()
        
        let targetProgress: CGFloat = cancelled ? 0 : 1
        let remainingDuration = configuration.duration * Double(abs(targetProgress - progress))
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(remainingDuration)
        CATransaction.setAnimationTimingFunction(configuration.timingFunction)
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishAnimation(completed: !cancelled)
        }
        
        curlLayer?.curlProgress = targetProgress
        curlLayer?.shadowIntensity = targetProgress
        
        CATransaction.commit()
        
        if configuration.enableHaptics {
            generateHapticFeedback(style: cancelled ? .light : .medium)
        }
    }
    
    /// Cancel the animation
    public func cancelAnimation() {
        completeAnimation(cancelled: true)
    }
    
    /// Stop the animation immediately
    public func stopAnimation() {
        stopDisplayLink()
        curlLayer?.removeFromSuperlayer()
        curlLayer = nil
        isAnimating = false
    }
    
    // MARK: - Private Methods
    
    private func setupCurlLayer() {
        guard let sourceView = sourceView else { return }
        
        let layer = PageCurlLayer()
        layer.frame = sourceView.bounds
        layer.configure(direction: configuration.direction, style: configuration.style)
        
        // Capture source view content
        UIGraphicsBeginImageContextWithOptions(sourceView.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            sourceView.layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        layer.contents = image?.cgImage
        
        if configuration.style.enable3DPerspective {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / configuration.style.perspectiveDepth
            layer.transform = transform
        }
        
        sourceView.layer.addSublayer(layer)
        curlLayer = layer
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateAnimation(_ displayLink: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let normalizedProgress = min(1, elapsed / configuration.duration)
        
        // Apply timing function
        progress = applyTimingFunction(normalizedProgress)
        
        curlLayer?.curlProgress = progress
        curlLayer?.shadowIntensity = progress
        
        onProgressUpdate?(progress)
        
        if normalizedProgress >= 1 {
            finishAnimation(completed: true)
        }
    }
    
    private func applyTimingFunction(_ t: CGFloat) -> CGFloat {
        // Ease in-out approximation
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    private func finishAnimation(completed: Bool) {
        stopDisplayLink()
        isAnimating = false
        
        if completed {
            // Show destination view
            destinationView?.isHidden = false
            sourceView?.isHidden = true
        }
        
        curlLayer?.removeFromSuperlayer()
        curlLayer = nil
        
        onCompletion?(completed)
    }
    
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Page Curl Transition

/// UIKit view controller transition using page curl effect
public final class PageCurlTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - Properties
    
    private let configuration: PageCurlConfiguration
    private let isPresenting: Bool
    private var animator: PageCurlAnimator?
    
    /// Completion handler called when transition finishes
    public var transitionCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        configuration: PageCurlConfiguration = .default,
        isPresenting: Bool = true
    ) {
        self.configuration = configuration
        self.isPresenting = isPresenting
        super.init()
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return configuration.duration
    }
    
    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        // Setup views in container
        if isPresenting {
            containerView.addSubview(toVC.view)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            toVC.view.isHidden = true
        } else {
            containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
        }
        
        // Create and configure animator
        let animator = PageCurlAnimator(configuration: configuration)
        animator.setup(from: fromVC.view, to: toVC.view)
        
        animator.onCompletion = { [weak self] completed in
            let success = completed && !transitionContext.transitionWasCancelled
            transitionContext.completeTransition(success)
            self?.transitionCompletion?(success)
        }
        
        self.animator = animator
        animator.startAnimation()
    }
}

// MARK: - Interactive Page Curl Transition

/// Interactive version of page curl transition with gesture support
public final class InteractivePageCurlTransition: UIPercentDrivenInteractiveTransition {
    
    // MARK: - Properties
    
    private let configuration: PageCurlConfiguration
    private weak var viewController: UIViewController?
    private var panGesture: UIPanGestureRecognizer?
    
    /// Whether interaction is in progress
    public private(set) var isInteracting = false
    
    /// Callback when interaction should begin transition
    public var onShouldBeginTransition: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        configuration: PageCurlConfiguration = .default,
        viewController: UIViewController
    ) {
        self.configuration = configuration
        self.viewController = viewController
        super.init()
        
        setupGesture()
    }
    
    // MARK: - Setup
    
    private func setupGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        viewController?.view.addGestureRecognizer(gesture)
        panGesture = gesture
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        let progress: CGFloat
        switch configuration.direction {
        case .left:
            progress = -translation.x / view.bounds.width
        case .right:
            progress = translation.x / view.bounds.width
        case .up:
            progress = -translation.y / view.bounds.height
        case .down:
            progress = translation.y / view.bounds.height
        }
        
        let clampedProgress = max(0, min(1, progress))
        
        switch gesture.state {
        case .began:
            isInteracting = true
            onShouldBeginTransition?()
            
        case .changed:
            update(clampedProgress)
            
        case .ended, .cancelled:
            isInteracting = false
            
            let velocityThreshold = configuration.completionVelocityThreshold
            let progressThreshold = configuration.completionProgressThreshold
            
            let relevantVelocity: CGFloat
            switch configuration.direction {
            case .left: relevantVelocity = -velocity.x
            case .right: relevantVelocity = velocity.x
            case .up: relevantVelocity = -velocity.y
            case .down: relevantVelocity = velocity.y
            }
            
            let shouldComplete = clampedProgress > progressThreshold ||
                                 relevantVelocity > velocityThreshold
            
            if shouldComplete {
                finish()
            } else {
                cancel()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    
    public func removeGesture() {
        if let gesture = panGesture {
            viewController?.view.removeGestureRecognizer(gesture)
        }
        panGesture = nil
    }
}

// MARK: - Page Curl View

/// A UIView subclass that provides page curl effects
public final class PageCurlView: UIView {
    
    // MARK: - Properties
    
    private var curlLayer: PageCurlLayer?
    private let configuration: PageCurlConfiguration
    
    /// Current curl progress
    public var curlProgress: CGFloat {
        get { curlLayer?.curlProgress ?? 0 }
        set { curlLayer?.curlProgress = newValue }
    }
    
    // MARK: - Initialization
    
    public init(frame: CGRect, configuration: PageCurlConfiguration = .default) {
        self.configuration = configuration
        super.init(frame: frame)
        setupCurlLayer()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        setupCurlLayer()
    }
    
    // MARK: - Setup
    
    private func setupCurlLayer() {
        let layer = PageCurlLayer()
        layer.frame = bounds
        layer.configure(direction: configuration.direction, style: configuration.style)
        self.layer.addSublayer(layer)
        curlLayer = layer
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        curlLayer?.frame = bounds
    }
    
    // MARK: - Public Methods
    
    /// Animate the curl to a target progress
    public func animateCurl(
        to progress: CGFloat,
        duration: TimeInterval = 0.3,
        completion: ((Bool) -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(configuration.timingFunction)
        CATransaction.setCompletionBlock {
            completion?(true)
        }
        
        curlLayer?.curlProgress = progress
        curlLayer?.shadowIntensity = progress
        
        CATransaction.commit()
    }
    
    /// Reset the curl to initial state
    public func resetCurl(animated: Bool = true) {
        if animated {
            animateCurl(to: 0)
        } else {
            curlLayer?.curlProgress = 0
            curlLayer?.shadowIntensity = 0
        }
    }
    
    /// Update the content to be curled
    public func updateContent(_ image: UIImage?) {
        curlLayer?.contents = image?.cgImage
    }
}

//
//  GestureAnimator.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit

// MARK: - Gesture Animation State

/// Represents the current state of a gesture animation
public enum GestureAnimationState: Equatable, Sendable {
    case idle
    case began
    case changed(progress: CGFloat)
    case ended(completed: Bool)
    case cancelled
    
    public var isActive: Bool {
        switch self {
        case .began, .changed: return true
        default: return false
        }
    }
    
    public var progress: CGFloat {
        switch self {
        case .changed(let p): return p
        case .ended(let completed): return completed ? 1 : 0
        default: return 0
        }
    }
}

// MARK: - Gesture Animation Direction

/// Direction for gesture-driven animations
public enum GestureDirection: CaseIterable, Sendable {
    case left
    case right
    case up
    case down
    case horizontal
    case vertical
    case any
    
    /// Check if a translation matches this direction
    func matches(translation: CGPoint, threshold: CGFloat = 10) -> Bool {
        switch self {
        case .left: return translation.x < -threshold
        case .right: return translation.x > threshold
        case .up: return translation.y < -threshold
        case .down: return translation.y > threshold
        case .horizontal: return abs(translation.x) > abs(translation.y) && abs(translation.x) > threshold
        case .vertical: return abs(translation.y) > abs(translation.x) && abs(translation.y) > threshold
        case .any: return true
        }
    }
    
    /// Get progress value from translation
    func progress(from translation: CGPoint, distance: CGFloat) -> CGFloat {
        switch self {
        case .left: return max(0, min(1, -translation.x / distance))
        case .right: return max(0, min(1, translation.x / distance))
        case .up: return max(0, min(1, -translation.y / distance))
        case .down: return max(0, min(1, translation.y / distance))
        case .horizontal: return max(0, min(1, abs(translation.x) / distance))
        case .vertical: return max(0, min(1, abs(translation.y) / distance))
        case .any:
            let magnitude = sqrt(translation.x * translation.x + translation.y * translation.y)
            return max(0, min(1, magnitude / distance))
        }
    }
    
    /// Get velocity component
    func velocity(from velocityPoint: CGPoint) -> CGFloat {
        switch self {
        case .left: return -velocityPoint.x
        case .right: return velocityPoint.x
        case .up: return -velocityPoint.y
        case .down: return velocityPoint.y
        case .horizontal: return abs(velocityPoint.x)
        case .vertical: return abs(velocityPoint.y)
        case .any:
            return sqrt(velocityPoint.x * velocityPoint.x + velocityPoint.y * velocityPoint.y)
        }
    }
}

// MARK: - Gesture Animation Configuration

/// Configuration for gesture-driven animations
public struct GestureAnimationConfiguration: Sendable {
    /// Required gesture direction
    public var direction: GestureDirection
    
    /// Distance required for full animation
    public var animationDistance: CGFloat
    
    /// Velocity threshold for completion
    public var velocityThreshold: CGFloat
    
    /// Progress threshold for completion
    public var progressThreshold: CGFloat
    
    /// Enable rubber banding at edges
    public var rubberBandingEnabled: Bool
    
    /// Rubber band factor (0-1, lower = more resistance)
    public var rubberBandFactor: CGFloat
    
    /// Enable haptic feedback
    public var hapticsEnabled: Bool
    
    /// Duration for animated completion/cancellation
    public var completionDuration: TimeInterval
    
    /// Timing function for completion animation
    public var completionTimingFunction: CAMediaTimingFunction
    
    /// Default configuration
    public static let `default` = GestureAnimationConfiguration(
        direction: .any,
        animationDistance: 200,
        velocityThreshold: 500,
        progressThreshold: 0.5,
        rubberBandingEnabled: true,
        rubberBandFactor: 0.55,
        hapticsEnabled: true,
        completionDuration: 0.35,
        completionTimingFunction: CAMediaTimingFunction(name: .easeOut)
    )
    
    /// Swipe dismiss configuration
    public static let swipeDismiss = GestureAnimationConfiguration(
        direction: .down,
        animationDistance: 300,
        velocityThreshold: 1000,
        progressThreshold: 0.3,
        rubberBandingEnabled: true,
        rubberBandFactor: 0.55,
        hapticsEnabled: true,
        completionDuration: 0.3,
        completionTimingFunction: CAMediaTimingFunction(name: .easeOut)
    )
    
    /// Card swipe configuration
    public static let cardSwipe = GestureAnimationConfiguration(
        direction: .horizontal,
        animationDistance: 150,
        velocityThreshold: 800,
        progressThreshold: 0.4,
        rubberBandingEnabled: false,
        rubberBandFactor: 0.55,
        hapticsEnabled: true,
        completionDuration: 0.25,
        completionTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
    )
    
    public init(
        direction: GestureDirection = .any,
        animationDistance: CGFloat = 200,
        velocityThreshold: CGFloat = 500,
        progressThreshold: CGFloat = 0.5,
        rubberBandingEnabled: Bool = true,
        rubberBandFactor: CGFloat = 0.55,
        hapticsEnabled: Bool = true,
        completionDuration: TimeInterval = 0.35,
        completionTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeOut)
    ) {
        self.direction = direction
        self.animationDistance = animationDistance
        self.velocityThreshold = velocityThreshold
        self.progressThreshold = progressThreshold
        self.rubberBandingEnabled = rubberBandingEnabled
        self.rubberBandFactor = rubberBandFactor
        self.hapticsEnabled = hapticsEnabled
        self.completionDuration = completionDuration
        self.completionTimingFunction = completionTimingFunction
    }
}

// MARK: - Gesture Animator Delegate

/// Delegate protocol for gesture animator events
public protocol GestureAnimatorDelegate: AnyObject {
    /// Called when gesture animation state changes
    func gestureAnimator(_ animator: GestureAnimator, didChangeState state: GestureAnimationState)
    
    /// Called when progress updates during gesture
    func gestureAnimator(_ animator: GestureAnimator, didUpdateProgress progress: CGFloat)
    
    /// Called when animation completes
    func gestureAnimator(_ animator: GestureAnimator, didComplete completed: Bool)
}

// Default implementations
public extension GestureAnimatorDelegate {
    func gestureAnimator(_ animator: GestureAnimator, didChangeState state: GestureAnimationState) {}
    func gestureAnimator(_ animator: GestureAnimator, didUpdateProgress progress: CGFloat) {}
    func gestureAnimator(_ animator: GestureAnimator, didComplete completed: Bool) {}
}

// MARK: - Gesture Animator

/// Main class for gesture-driven animations
public final class GestureAnimator: NSObject {
    
    // MARK: - Properties
    
    private let configuration: GestureAnimationConfiguration
    private weak var targetView: UIView?
    private var panGesture: UIPanGestureRecognizer?
    
    private var state: GestureAnimationState = .idle {
        didSet {
            delegate?.gestureAnimator(self, didChangeState: state)
            onStateChange?(state)
        }
    }
    
    private var startPosition: CGPoint = .zero
    private var currentProgress: CGFloat = 0
    private var completionAnimator: UIViewPropertyAnimator?
    
    /// Delegate for gesture events
    public weak var delegate: GestureAnimatorDelegate?
    
    /// Progress update callback
    public var onProgressUpdate: ((CGFloat) -> Void)?
    
    /// State change callback
    public var onStateChange: ((GestureAnimationState) -> Void)?
    
    /// Completion callback
    public var onCompletion: ((Bool) -> Void)?
    
    /// Animation callback (called each frame with progress)
    public var animationBlock: ((CGFloat) -> Void)?
    
    /// Current animation state
    public var currentState: GestureAnimationState { state }
    
    /// Current progress value
    public var progress: CGFloat { currentProgress }
    
    /// Whether the animator is currently active
    public var isActive: Bool { state.isActive }
    
    // MARK: - Initialization
    
    public init(
        targetView: UIView,
        configuration: GestureAnimationConfiguration = .default
    ) {
        self.targetView = targetView
        self.configuration = configuration
        super.init()
        
        setupGesture()
    }
    
    deinit {
        removeGesture()
    }
    
    // MARK: - Setup
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        targetView?.addGestureRecognizer(pan)
        panGesture = pan
    }
    
    /// Remove the gesture recognizer
    public func removeGesture() {
        if let gesture = panGesture {
            targetView?.removeGestureRecognizer(gesture)
        }
        panGesture = nil
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            handleBegan(translation: translation)
            
        case .changed:
            handleChanged(translation: translation)
            
        case .ended:
            handleEnded(velocity: velocity)
            
        case .cancelled, .failed:
            handleCancelled()
            
        default:
            break
        }
    }
    
    private func handleBegan(translation: CGPoint) {
        // Cancel any existing animation
        completionAnimator?.stopAnimation(true)
        
        // Check if gesture direction matches
        if !configuration.direction.matches(translation: translation, threshold: 5) {
            return
        }
        
        startPosition = targetView?.center ?? .zero
        state = .began
        
        if configuration.hapticsEnabled {
            generateHaptic(.light)
        }
    }
    
    private func handleChanged(translation: CGPoint) {
        guard state.isActive || state == .idle else { return }
        
        // Check direction match for late starts
        if state == .idle && configuration.direction.matches(translation: translation, threshold: 10) {
            startPosition = targetView?.center ?? .zero
            state = .began
        }
        
        guard state.isActive else { return }
        
        // Calculate progress
        var progress = configuration.direction.progress(
            from: translation,
            distance: configuration.animationDistance
        )
        
        // Apply rubber banding if over 1
        if configuration.rubberBandingEnabled && progress > 1 {
            let overProgress = progress - 1
            progress = 1 + rubberBand(overProgress, factor: configuration.rubberBandFactor)
        }
        
        currentProgress = progress
        state = .changed(progress: progress)
        
        // Call animation block
        animationBlock?(progress)
        
        // Notify delegate
        delegate?.gestureAnimator(self, didUpdateProgress: progress)
        onProgressUpdate?(progress)
    }
    
    private func handleEnded(velocity: CGPoint) {
        guard state.isActive else { return }
        
        let gestureVelocity = configuration.direction.velocity(from: velocity)
        
        // Determine if should complete
        let shouldComplete = currentProgress > configuration.progressThreshold ||
                            gestureVelocity > configuration.velocityThreshold
        
        animateToEnd(completed: shouldComplete, velocity: gestureVelocity)
    }
    
    private func handleCancelled() {
        guard state.isActive else { return }
        
        state = .cancelled
        animateToEnd(completed: false, velocity: 0)
    }
    
    // MARK: - Animation
    
    private func animateToEnd(completed: Bool, velocity: CGFloat) {
        let targetProgress: CGFloat = completed ? 1 : 0
        let distance = abs(targetProgress - currentProgress)
        
        // Calculate duration based on velocity
        var duration = configuration.completionDuration
        if velocity > 0 && distance > 0 {
            let velocityBasedDuration = TimeInterval(distance * configuration.animationDistance / velocity)
            duration = min(duration, max(0.1, velocityBasedDuration))
        }
        
        // Create spring animator for smooth finish
        let animator = UIViewPropertyAnimator(
            duration: duration,
            timingParameters: UISpringTimingParameters(
                dampingRatio: 0.85,
                initialVelocity: CGVector(dx: velocity / 1000, dy: velocity / 1000)
            )
        )
        
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            self.currentProgress = targetProgress
            self.animationBlock?(targetProgress)
        }
        
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.state = .ended(completed: completed)
            self.delegate?.gestureAnimator(self, didComplete: completed)
            self.onCompletion?(completed)
            
            if self.configuration.hapticsEnabled {
                self.generateHaptic(completed ? .medium : .light)
            }
        }
        
        completionAnimator = animator
        animator.startAnimation()
    }
    
    // MARK: - Utility
    
    private func rubberBand(_ x: CGFloat, factor: CGFloat) -> CGFloat {
        return (1 - (1 / (x * factor + 1))) * factor
    }
    
    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Public Methods
    
    /// Manually complete the animation
    public func complete(animated: Bool = true) {
        if animated {
            animateToEnd(completed: true, velocity: 500)
        } else {
            currentProgress = 1
            animationBlock?(1)
            state = .ended(completed: true)
            delegate?.gestureAnimator(self, didComplete: true)
            onCompletion?(true)
        }
    }
    
    /// Manually cancel the animation
    public func cancel(animated: Bool = true) {
        if animated {
            animateToEnd(completed: false, velocity: 500)
        } else {
            currentProgress = 0
            animationBlock?(0)
            state = .cancelled
            delegate?.gestureAnimator(self, didComplete: false)
            onCompletion?(false)
        }
    }
    
    /// Reset to initial state
    public func reset() {
        completionAnimator?.stopAnimation(true)
        currentProgress = 0
        state = .idle
        animationBlock?(0)
    }
    
    /// Update progress manually (for programmatic control)
    public func setProgress(_ progress: CGFloat, animated: Bool = false) {
        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) { [weak self] in
                self?.currentProgress = progress
                self?.animationBlock?(progress)
            }
            animator.startAnimation()
        } else {
            currentProgress = progress
            animationBlock?(progress)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GestureAnimator: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else {
            return false
        }
        
        let translation = pan.translation(in: view)
        return configuration.direction.matches(translation: translation, threshold: 5)
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow simultaneous recognition with scroll views
        return otherGestureRecognizer is UIPanGestureRecognizer
    }
}

// MARK: - Interactive Dismiss Animator

/// Specialized animator for interactive view controller dismissal
public final class InteractiveDismissAnimator: NSObject {
    
    // MARK: - Properties
    
    private let configuration: GestureAnimationConfiguration
    private weak var viewController: UIViewController?
    private var panGesture: UIPanGestureRecognizer?
    private var interactiveTransition: UIPercentDrivenInteractiveTransition?
    
    private var isInteracting = false
    private var shouldComplete = false
    
    /// Whether an interactive dismissal is in progress
    public var isInteractivelyDismissing: Bool { isInteracting }
    
    // MARK: - Initialization
    
    public init(
        viewController: UIViewController,
        configuration: GestureAnimationConfiguration = .swipeDismiss
    ) {
        self.viewController = viewController
        self.configuration = configuration
        super.init()
        
        setupGesture()
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        viewController?.view.addGestureRecognizer(pan)
        panGesture = pan
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        let progress = configuration.direction.progress(
            from: translation,
            distance: configuration.animationDistance
        )
        
        switch gesture.state {
        case .began:
            isInteracting = true
            interactiveTransition = UIPercentDrivenInteractiveTransition()
            viewController?.dismiss(animated: true)
            
        case .changed:
            interactiveTransition?.update(progress)
            
            let gestureVelocity = configuration.direction.velocity(from: velocity)
            shouldComplete = progress > configuration.progressThreshold ||
                            gestureVelocity > configuration.velocityThreshold
            
        case .ended, .cancelled:
            isInteracting = false
            
            if shouldComplete && gesture.state == .ended {
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.cancel()
            }
            
            interactiveTransition = nil
            
        default:
            break
        }
    }
    
    /// Get the interactive transition for use with transitioning delegate
    public func interactiveTransitionForDismissal() -> UIViewControllerInteractiveTransitioning? {
        return isInteracting ? interactiveTransition : nil
    }
}

// MARK: - Swipe Action Animator

/// Animator for swipe action animations (like table view swipe actions)
public final class SwipeActionAnimator {
    
    // MARK: - Properties
    
    private weak var targetView: UIView?
    private weak var actionsView: UIView?
    private var panGesture: UIPanGestureRecognizer?
    private let configuration: GestureAnimationConfiguration
    
    private var actionsWidth: CGFloat = 0
    private var isShowingActions = false
    
    /// Called when actions are revealed/hidden
    public var onActionsVisibilityChanged: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        targetView: UIView,
        actionsView: UIView,
        actionsWidth: CGFloat,
        configuration: GestureAnimationConfiguration = .cardSwipe
    ) {
        self.targetView = targetView
        self.actionsView = actionsView
        self.actionsWidth = actionsWidth
        self.configuration = configuration
        
        setupGesture()
        setupActionsView()
    }
    
    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        targetView?.addGestureRecognizer(pan)
        panGesture = pan
    }
    
    private func setupActionsView() {
        actionsView?.clipsToBounds = true
        actionsView?.frame.size.width = 0
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let target = targetView,
              let actions = actionsView else { return }
        
        let translation = gesture.translation(in: target)
        let velocity = gesture.velocity(in: target)
        
        switch gesture.state {
        case .changed:
            let offset = isShowingActions ? actionsWidth - translation.x : -translation.x
            let clampedOffset = max(0, min(actionsWidth, offset))
            
            target.transform = CGAffineTransform(translationX: -clampedOffset, y: 0)
            actions.frame.size.width = clampedOffset
            
        case .ended:
            let offset = isShowingActions ? actionsWidth - translation.x : -translation.x
            let shouldShow = offset > actionsWidth / 2 || -velocity.x > configuration.velocityThreshold
            
            animateToState(showing: shouldShow)
            
        case .cancelled:
            animateToState(showing: isShowingActions)
            
        default:
            break
        }
    }
    
    private func animateToState(showing: Bool) {
        guard let target = targetView,
              let actions = actionsView else { return }
        
        isShowingActions = showing
        
        UIView.animate(
            withDuration: configuration.completionDuration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5
        ) {
            if showing {
                target.transform = CGAffineTransform(translationX: -self.actionsWidth, y: 0)
                actions.frame.size.width = self.actionsWidth
            } else {
                target.transform = .identity
                actions.frame.size.width = 0
            }
        } completion: { _ in
            self.onActionsVisibilityChanged?(showing)
        }
    }
    
    /// Hide actions programmatically
    public func hideActions(animated: Bool = true) {
        if animated {
            animateToState(showing: false)
        } else {
            targetView?.transform = .identity
            actionsView?.frame.size.width = 0
            isShowingActions = false
        }
    }
    
    /// Show actions programmatically
    public func showActions(animated: Bool = true) {
        if animated {
            animateToState(showing: true)
        } else {
            targetView?.transform = CGAffineTransform(translationX: -actionsWidth, y: 0)
            actionsView?.frame.size.width = actionsWidth
            isShowingActions = true
        }
    }
}

// MARK: - Pull to Refresh Animator

/// Animator for pull-to-refresh gestures
public final class PullToRefreshAnimator {
    
    // MARK: - Properties
    
    private weak var scrollView: UIScrollView?
    private weak var refreshView: UIView?
    private let triggerDistance: CGFloat
    private let configuration: GestureAnimationConfiguration
    
    private var isRefreshing = false
    private var observation: NSKeyValueObservation?
    
    /// Called when refresh is triggered
    public var onRefresh: (() -> Void)?
    
    /// Called with pull progress (0-1+)
    public var onProgressUpdate: ((CGFloat) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        scrollView: UIScrollView,
        refreshView: UIView,
        triggerDistance: CGFloat = 80,
        configuration: GestureAnimationConfiguration = .default
    ) {
        self.scrollView = scrollView
        self.refreshView = refreshView
        self.triggerDistance = triggerDistance
        self.configuration = configuration
        
        setupObservation()
    }
    
    deinit {
        observation?.invalidate()
    }
    
    private func setupObservation() {
        observation = scrollView?.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            self?.handleScroll(scrollView)
        }
    }
    
    private func handleScroll(_ scrollView: UIScrollView) {
        guard !isRefreshing else { return }
        
        let offset = scrollView.contentOffset.y
        let adjustedOffset = offset + scrollView.adjustedContentInset.top
        
        if adjustedOffset < 0 {
            let progress = min(1.5, -adjustedOffset / triggerDistance)
            
            onProgressUpdate?(progress)
            updateRefreshView(progress: progress)
            
            // Check for trigger
            if !scrollView.isDragging && progress >= 1 {
                triggerRefresh()
            }
        }
    }
    
    private func updateRefreshView(progress: CGFloat) {
        refreshView?.alpha = progress
        refreshView?.transform = CGAffineTransform(scaleX: progress, y: progress)
    }
    
    private func triggerRefresh() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        if configuration.hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        onRefresh?()
    }
    
    /// Call when refresh completes
    public func endRefreshing() {
        isRefreshing = false
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.refreshView?.alpha = 0
            self?.refreshView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }
    }
}

// MARK: - UIView Extension

public extension UIView {
    
    /// Add gesture-driven animation
    func addGestureAnimator(
        configuration: GestureAnimationConfiguration = .default,
        animation: @escaping (CGFloat) -> Void
    ) -> GestureAnimator {
        let animator = GestureAnimator(targetView: self, configuration: configuration)
        animator.animationBlock = animation
        return animator
    }
    
    /// Add swipe-to-dismiss gesture
    func addSwipeToDismiss(
        direction: GestureDirection = .down,
        onDismiss: @escaping () -> Void
    ) -> GestureAnimator {
        var config = GestureAnimationConfiguration.swipeDismiss
        config.direction = direction
        
        let animator = GestureAnimator(targetView: self, configuration: config)
        animator.onCompletion = { completed in
            if completed {
                onDismiss()
            }
        }
        
        animator.animationBlock = { [weak self] progress in
            self?.alpha = 1 - progress * 0.3
            
            switch direction {
            case .down:
                self?.transform = CGAffineTransform(translationX: 0, y: progress * 200)
            case .up:
                self?.transform = CGAffineTransform(translationX: 0, y: -progress * 200)
            case .left:
                self?.transform = CGAffineTransform(translationX: -progress * 200, y: 0)
            case .right:
                self?.transform = CGAffineTransform(translationX: progress * 200, y: 0)
            default:
                self?.transform = CGAffineTransform(translationX: 0, y: progress * 200)
            }
        }
        
        return animator
    }
}

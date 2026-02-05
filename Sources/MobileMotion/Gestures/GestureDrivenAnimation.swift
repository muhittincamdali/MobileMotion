import UIKit

/// Represents the current state of a gesture-driven animation.
public enum GestureAnimationState {
    /// The user is actively dragging.
    case dragging(translation: CGPoint, velocity: CGPoint)

    /// The user released and physics is taking over.
    case released(velocity: CGPoint)

    /// The animation has settled at a final position.
    case settled(position: CGPoint)

    /// The gesture was cancelled.
    case cancelled
}

/// Configuration for snap points that the animation can settle at.
public struct SnapPoint {
    /// Position of the snap point.
    public let position: CGPoint

    /// Attraction radius — when the release position is within this
    /// distance, the animation will snap to this point.
    public let radius: Double

    public init(position: CGPoint, radius: Double = 100.0) {
        self.position = position
        self.radius = radius
    }
}

/// Bridges gesture recognizers to physics-based animations.
///
/// Tracks a `UIPanGestureRecognizer` and uses release velocity to
/// drive a spring animation toward the nearest snap point (or origin).
///
/// ```swift
/// let gesture = GestureDrivenAnimation(
///     spring: SpringAnimation(stiffness: 220, damping: 18)
/// )
/// gesture.track(panGesture: recognizer, on: cardView) { state in
///     switch state {
///     case .dragging(let t, _):
///         cardView.transform = CGAffineTransform(translationX: t.x, y: t.y)
///     case .settled(let pos):
///         print("Settled at \(pos)")
///     default: break
///     }
/// }
/// ```
public final class GestureDrivenAnimation {

    // MARK: - Configuration

    /// Spring used for the settle animation after release.
    public let spring: SpringAnimation

    /// Optional Y-axis spring (if different from X).
    public var ySpring: SpringAnimation?

    /// Points the animation can snap to on release.
    public var snapPoints: [SnapPoint] = []

    /// Whether to apply rubber-banding when dragging beyond bounds.
    public var rubberBandingEnabled: Bool = true

    /// Rubber band factor (0–1). Lower = more resistance.
    public var rubberBandFactor: Double = 0.55

    /// Bounding rect for rubber banding. `nil` means unbounded.
    public var bounds: CGRect?

    // MARK: - State

    /// Current animation state.
    public private(set) var state: GestureAnimationState = .cancelled

    /// Callback for state changes.
    public var onStateChanged: ((GestureAnimationState) -> Void)?

    // MARK: - Private

    private var engine: AnimationEngine?
    private var xAnimationId: String?
    private var yAnimationId: String?
    private var initialCenter: CGPoint = .zero
    private weak var trackedView: UIView?

    // MARK: - Initialization

    /// Creates a gesture-driven animation controller.
    ///
    /// - Parameter spring: Spring configuration for the settle phase.
    public init(spring: SpringAnimation) {
        self.spring = spring
        self.engine = AnimationEngine()
    }

    // MARK: - Public API

    /// Begins tracking a pan gesture on the given view.
    ///
    /// - Parameters:
    ///   - panGesture: The pan gesture recognizer to observe.
    ///   - view: The view being manipulated.
    ///   - handler: Called on each state change.
    public func track(
        panGesture: UIPanGestureRecognizer,
        on view: UIView,
        handler: @escaping (GestureAnimationState) -> Void
    ) {
        trackedView = view
        onStateChanged = handler
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
    }

    /// Manually triggers the settle animation toward the given point.
    public func settleTo(_ point: CGPoint, velocity: CGPoint = .zero) {
        cancelCurrentAnimations()
        animateSettle(to: point, velocity: velocity)
    }

    /// Finds the nearest snap point to a given position, or `nil` if none are in range.
    public func nearestSnapPoint(to position: CGPoint) -> SnapPoint? {
        var closest: SnapPoint?
        var closestDistance = Double.greatestFiniteMagnitude

        for snap in snapPoints {
            let dx = position.x - snap.position.x
            let dy = position.y - snap.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < snap.radius && distance < closestDistance {
                closest = snap
                closestDistance = distance
            }
        }

        return closest
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = trackedView else { return }

        switch gesture.state {
        case .began:
            cancelCurrentAnimations()
            initialCenter = view.center

        case .changed:
            let translation = gesture.translation(in: view.superview)
            let velocity = gesture.velocity(in: view.superview)

            var adjustedTranslation = translation

            // Apply rubber banding if we're beyond bounds
            if rubberBandingEnabled, let bounds = bounds {
                adjustedTranslation.x = rubberBand(
                    value: translation.x + initialCenter.x,
                    min: bounds.minX,
                    max: bounds.maxX,
                    offset: initialCenter.x
                )
                adjustedTranslation.y = rubberBand(
                    value: translation.y + initialCenter.y,
                    min: bounds.minY,
                    max: bounds.maxY,
                    offset: initialCenter.y
                )
            }

            let newState = GestureAnimationState.dragging(
                translation: adjustedTranslation,
                velocity: velocity
            )
            state = newState
            onStateChanged?(newState)

        case .ended:
            let velocity = gesture.velocity(in: view.superview)
            let currentPos = view.center

            state = .released(velocity: velocity)
            onStateChanged?(state)

            // Find snap target
            let target: CGPoint
            if let snap = nearestSnapPoint(to: currentPos) {
                target = snap.position
            } else {
                target = initialCenter
            }

            animateSettle(to: target, velocity: velocity)

        case .cancelled, .failed:
            state = .cancelled
            onStateChanged?(state)
            animateSettle(to: initialCenter, velocity: .zero)

        default:
            break
        }
    }

    // MARK: - Animation

    private func animateSettle(to target: CGPoint, velocity: CGPoint) {
        guard let engine = engine, let view = trackedView else { return }

        let xSpring = SpringAnimation(
            mass: spring.mass,
            stiffness: spring.stiffness,
            damping: spring.damping
        )

        let effectiveYSpring = ySpring ?? SpringAnimation(
            mass: spring.mass,
            stiffness: spring.stiffness,
            damping: spring.damping
        )

        var currentX = Double(view.center.x)
        var currentY = Double(view.center.y)

        xAnimationId = engine.run(
            xSpring,
            from: currentX,
            to: Double(target.x),
            initialVelocity: Double(velocity.x),
            update: { [weak self, weak view] value in
                currentX = value
                view?.center.x = CGFloat(value)
            },
            completion: { [weak self] in
                self?.checkSettled(target: target)
            }
        )

        yAnimationId = engine.run(
            effectiveYSpring,
            from: currentY,
            to: Double(target.y),
            initialVelocity: Double(velocity.y),
            update: { [weak view] value in
                currentY = value
                view?.center.y = CGFloat(value)
            },
            completion: { [weak self] in
                self?.checkSettled(target: target)
            }
        )
    }

    private func checkSettled(target: CGPoint) {
        guard let engine = engine else { return }

        if engine.activeCount == 0 {
            state = .settled(position: target)
            onStateChanged?(state)
        }
    }

    private func cancelCurrentAnimations() {
        guard let engine = engine else { return }

        if let id = xAnimationId { engine.cancel(id: id) }
        if let id = yAnimationId { engine.cancel(id: id) }
        xAnimationId = nil
        yAnimationId = nil
    }

    // MARK: - Rubber Banding

    private func rubberBand(value: CGFloat, min: CGFloat, max: CGFloat, offset: CGFloat) -> CGFloat {
        let clamped = Swift.min(Swift.max(value, min), max)
        if value == clamped { return value - offset }

        let overflow = value - clamped
        let dampened = overflow * CGFloat(rubberBandFactor)
        return clamped + dampened - offset
    }
}

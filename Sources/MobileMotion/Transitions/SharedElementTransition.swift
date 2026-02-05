import UIKit

/// Identifies a shared element that participates in a transition.
public struct SharedElement {
    /// Unique identifier matching across source and destination.
    public let identifier: String

    /// The view in the source screen.
    public let sourceView: UIView

    /// The view in the destination screen.
    public let destinationView: UIView

    public init(identifier: String, sourceView: UIView, destinationView: UIView) {
        self.identifier = identifier
        self.sourceView = sourceView
        self.destinationView = destinationView
    }
}

/// Registry for shared element views across screens.
public final class SharedElementRegistry {

    /// Registered source views keyed by identifier.
    private var sources: [String: UIView] = [:]

    /// Registered destination views keyed by identifier.
    private var destinations: [String: UIView] = [:]

    public init() {}

    /// Registers a view as a shared element source.
    public func registerSource(_ view: UIView, identifier: String) {
        sources[identifier] = view
    }

    /// Registers a view as a shared element destination.
    public func registerDestination(_ view: UIView, identifier: String) {
        destinations[identifier] = view
    }

    /// Removes a registration.
    public func unregister(identifier: String) {
        sources.removeValue(forKey: identifier)
        destinations.removeValue(forKey: identifier)
    }

    /// Resolves all matched pairs into SharedElement instances.
    public func resolveElements() -> [SharedElement] {
        var elements: [SharedElement] = []

        for (identifier, source) in sources {
            if let destination = destinations[identifier] {
                elements.append(SharedElement(
                    identifier: identifier,
                    sourceView: source,
                    destinationView: destination
                ))
            }
        }

        return elements
    }

    /// Removes all registrations.
    public func clear() {
        sources.removeAll()
        destinations.removeAll()
    }
}

/// Performs hero-style shared element transitions between view controllers.
///
/// Each shared element smoothly animates from its source position/size to
/// its destination using physics-based springs, creating a natural connection
/// between screens.
///
/// ```swift
/// let transition = SharedElementTransition()
/// transition.registry.registerSource(avatarView, identifier: "avatar")
/// transition.registry.registerDestination(detailAvatarView, identifier: "avatar")
///
/// transition.perform(in: containerView) {
///     print("Transition complete")
/// }
/// ```
public final class SharedElementTransition {

    // MARK: - Configuration

    /// The spring used for element animations.
    public var spring: SpringAnimation

    /// Whether to fade non-shared content during transition.
    public var fadeNonSharedContent: Bool = true

    /// Duration of the non-shared content fade (in spring progress).
    public var fadeThreshold: Double = 0.3

    /// The element registry.
    public let registry = SharedElementRegistry()

    // MARK: - State

    /// Whether a transition is in progress.
    public private(set) var isTransitioning: Bool = false

    // MARK: - Private

    private let engine = AnimationEngine()
    private var overlayViews: [String: UIView] = [:]
    private var animationIds: [String] = []

    // MARK: - Initialization

    /// Creates a shared element transition.
    ///
    /// - Parameter spring: Spring for the element animations. Default is `.snappy`.
    public init(spring: SpringAnimation = .snappy) {
        self.spring = spring
    }

    // MARK: - Public API

    /// Performs the shared element transition.
    ///
    /// - Parameters:
    ///   - container: The view to host transition overlays.
    ///   - elements: Explicit elements. If nil, uses the registry.
    ///   - completion: Called when all elements have settled.
    public func perform(
        in container: UIView,
        elements: [SharedElement]? = nil,
        completion: (() -> Void)? = nil
    ) {
        let resolvedElements = elements ?? registry.resolveElements()
        guard !resolvedElements.isEmpty else {
            completion?()
            return
        }

        isTransitioning = true
        var completedCount = 0
        let totalCount = resolvedElements.count

        for element in resolvedElements {
            animateElement(element, in: container) { [weak self] in
                completedCount += 1
                if completedCount >= totalCount {
                    self?.cleanup()
                    self?.isTransitioning = false
                    completion?()
                }
            }
        }
    }

    /// Cancels the current transition and cleans up.
    public func cancel() {
        engine.stopAll()
        cleanup()
        isTransitioning = false
    }

    // MARK: - Private

    private func animateElement(
        _ element: SharedElement,
        in container: UIView,
        completion: @escaping () -> Void
    ) {
        let sourceFrame = element.sourceView.convert(
            element.sourceView.bounds,
            to: container
        )
        let destFrame = element.destinationView.convert(
            element.destinationView.bounds,
            to: container
        )

        // Create snapshot of source for smooth animation
        let snapshot = element.sourceView.snapshotView(afterScreenUpdates: false)
            ?? UIView()
        snapshot.frame = sourceFrame
        snapshot.layer.cornerRadius = element.sourceView.layer.cornerRadius
        snapshot.clipsToBounds = true
        container.addSubview(snapshot)

        overlayViews[element.identifier] = snapshot

        // Hide originals during transition
        element.sourceView.alpha = 0
        element.destinationView.alpha = 0

        // Create individual springs for x, y, width, height
        let positionSpring = SpringAnimation(
            mass: spring.mass,
            stiffness: spring.stiffness,
            damping: spring.damping
        )

        let id = engine.run(positionSpring, from: 0, to: 1) { progress in
            let t = CGFloat(progress)

            let x = sourceFrame.origin.x + (destFrame.origin.x - sourceFrame.origin.x) * t
            let y = sourceFrame.origin.y + (destFrame.origin.y - sourceFrame.origin.y) * t
            let w = sourceFrame.width + (destFrame.width - sourceFrame.width) * t
            let h = sourceFrame.height + (destFrame.height - sourceFrame.height) * t

            snapshot.frame = CGRect(x: x, y: y, width: w, height: h)

            // Interpolate corner radius
            let srcRadius = element.sourceView.layer.cornerRadius
            let dstRadius = element.destinationView.layer.cornerRadius
            snapshot.layer.cornerRadius = srcRadius + (dstRadius - srcRadius) * t

        } completion: { [weak self] in
            // Show destination, remove overlay
            element.destinationView.alpha = 1
            snapshot.removeFromSuperview()
            self?.overlayViews.removeValue(forKey: element.identifier)
            completion()
        }

        animationIds.append(id)
    }

    private func cleanup() {
        for (_, view) in overlayViews {
            view.removeFromSuperview()
        }
        overlayViews.removeAll()
        animationIds.removeAll()
    }
}

// MARK: - UIViewController Extension

extension SharedElementTransition {

    /// Convenience to perform a transition between two view controllers.
    ///
    /// - Parameters:
    ///   - from: Source view controller.
    ///   - to: Destination view controller.
    ///   - elements: Shared elements to animate.
    ///   - completion: Called on finish.
    public func perform(
        from source: UIViewController,
        to destination: UIViewController,
        elements: [SharedElement],
        completion: (() -> Void)? = nil
    ) {
        guard let container = source.view.window ?? source.view else {
            completion?()
            return
        }

        perform(in: container, elements: elements, completion: completion)
    }
}

import UIKit

/// Properties that can be morphed between two views.
public struct MorphProperty: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Animate the frame (position + size).
    public static let frame = MorphProperty(rawValue: 1 << 0)

    /// Animate corner radius.
    public static let cornerRadius = MorphProperty(rawValue: 1 << 1)

    /// Animate background color.
    public static let backgroundColor = MorphProperty(rawValue: 1 << 2)

    /// Animate opacity.
    public static let opacity = MorphProperty(rawValue: 1 << 3)

    /// Animate transform (scale, rotation).
    public static let transform = MorphProperty(rawValue: 1 << 4)

    /// Animate shadow properties.
    public static let shadow = MorphProperty(rawValue: 1 << 5)

    /// Animate border.
    public static let border = MorphProperty(rawValue: 1 << 6)

    /// All morphable properties.
    public static let all: MorphProperty = [
        .frame, .cornerRadius, .backgroundColor,
        .opacity, .transform, .shadow, .border
    ]
}

/// Captures the visual state of a view for morphing.
struct MorphSnapshot {
    let frame: CGRect
    let cornerRadius: CGFloat
    let backgroundColor: UIColor?
    let opacity: Float
    let transform: CGAffineTransform
    let shadowColor: CGColor?
    let shadowOpacity: Float
    let shadowOffset: CGSize
    let shadowRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: CGColor?

    static func capture(from view: UIView) -> MorphSnapshot {
        MorphSnapshot(
            frame: view.frame,
            cornerRadius: view.layer.cornerRadius,
            backgroundColor: view.backgroundColor,
            opacity: view.layer.opacity,
            transform: view.transform,
            shadowColor: view.layer.shadowColor,
            shadowOpacity: view.layer.shadowOpacity,
            shadowOffset: view.layer.shadowOffset,
            shadowRadius: view.layer.shadowRadius,
            borderWidth: view.layer.borderWidth,
            borderColor: view.layer.borderColor
        )
    }
}

/// Morphs one view into another using physics-based interpolation.
///
/// Instead of cross-fading, MorphTransition creates a smooth physical
/// transformation between two views' visual properties.
///
/// ```swift
/// let morph = MorphTransition(spring: .bouncy)
/// morph.transition(from: circleView, to: rectView, properties: .all)
/// ```
public final class MorphTransition {

    // MARK: - Configuration

    /// Spring used for the morph interpolation.
    public let spring: SpringAnimation

    /// Which properties to morph.
    public var properties: MorphProperty

    /// Whether to hide the source view during transition.
    public var hideSourceDuringTransition: Bool = true

    /// Whether to show the destination view at the end.
    public var showDestinationOnComplete: Bool = true

    // MARK: - State

    /// Whether a transition is in progress.
    public private(set) var isTransitioning: Bool = false

    // MARK: - Private

    private let engine = AnimationEngine()
    private var morphView: UIView?

    // MARK: - Initialization

    /// Creates a morph transition with the given spring and properties.
    ///
    /// - Parameters:
    ///   - spring: Spring configuration. Default is `.snappy`.
    ///   - properties: Properties to morph. Default is `.all`.
    public init(
        spring: SpringAnimation = .snappy,
        properties: MorphProperty = .all
    ) {
        self.spring = spring
        self.properties = properties
    }

    // MARK: - Public API

    /// Performs a morph transition between two views.
    ///
    /// - Parameters:
    ///   - source: The starting view.
    ///   - destination: The ending view.
    ///   - container: The container view for the transition overlay.
    ///   - completion: Called when the morph completes.
    public func transition(
        from source: UIView,
        to destination: UIView,
        in container: UIView? = nil,
        completion: (() -> Void)? = nil
    ) {
        let transitionContainer = container ?? source.superview ?? source

        let sourceSnapshot = MorphSnapshot.capture(from: source)
        let destSnapshot = MorphSnapshot.capture(from: destination)

        // Create an intermediate view for the morph
        let intermediate = UIView()
        intermediate.frame = sourceSnapshot.frame
        intermediate.layer.cornerRadius = sourceSnapshot.cornerRadius
        intermediate.backgroundColor = sourceSnapshot.backgroundColor
        intermediate.layer.opacity = sourceSnapshot.opacity
        intermediate.clipsToBounds = true
        transitionContainer.addSubview(intermediate)
        morphView = intermediate

        if hideSourceDuringTransition {
            source.isHidden = true
        }
        destination.isHidden = true

        isTransitioning = true

        // Animate with spring from 0 to 1
        let morphSpring = SpringAnimation(
            mass: spring.mass,
            stiffness: spring.stiffness,
            damping: spring.damping
        )

        engine.run(morphSpring, from: 0, to: 1) { [weak self] progress in
            guard let self = self else { return }
            self.interpolate(
                view: intermediate,
                from: sourceSnapshot,
                to: destSnapshot,
                progress: CGFloat(progress)
            )
        } completion: { [weak self] in
            guard let self = self else { return }

            intermediate.removeFromSuperview()
            self.morphView = nil

            if self.showDestinationOnComplete {
                destination.isHidden = false
            }

            self.isTransitioning = false
            completion?()
        }
    }

    /// Cancels the current transition.
    public func cancel() {
        engine.stopAll()
        morphView?.removeFromSuperview()
        morphView = nil
        isTransitioning = false
    }

    // MARK: - Interpolation

    private func interpolate(
        view: UIView,
        from source: MorphSnapshot,
        to dest: MorphSnapshot,
        progress: CGFloat
    ) {
        let t = progress

        if properties.contains(.frame) {
            view.frame = CGRect(
                x: lerp(source.frame.origin.x, dest.frame.origin.x, t),
                y: lerp(source.frame.origin.y, dest.frame.origin.y, t),
                width: lerp(source.frame.width, dest.frame.width, t),
                height: lerp(source.frame.height, dest.frame.height, t)
            )
        }

        if properties.contains(.cornerRadius) {
            view.layer.cornerRadius = lerp(source.cornerRadius, dest.cornerRadius, t)
        }

        if properties.contains(.backgroundColor) {
            view.backgroundColor = interpolateColor(
                from: source.backgroundColor,
                to: dest.backgroundColor,
                progress: t
            )
        }

        if properties.contains(.opacity) {
            view.layer.opacity = Float(lerp(CGFloat(source.opacity), CGFloat(dest.opacity), t))
        }

        if properties.contains(.shadow) {
            view.layer.shadowOpacity = Float(
                lerp(CGFloat(source.shadowOpacity), CGFloat(dest.shadowOpacity), t)
            )
            view.layer.shadowRadius = lerp(source.shadowRadius, dest.shadowRadius, t)
            view.layer.shadowOffset = CGSize(
                width: lerp(source.shadowOffset.width, dest.shadowOffset.width, t),
                height: lerp(source.shadowOffset.height, dest.shadowOffset.height, t)
            )
        }

        if properties.contains(.border) {
            view.layer.borderWidth = lerp(source.borderWidth, dest.borderWidth, t)
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }

    private func interpolateColor(
        from: UIColor?,
        to: UIColor?,
        progress: CGFloat
    ) -> UIColor? {
        guard let from = from, let to = to else { return to ?? from }

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: lerp(r1, r2, progress),
            green: lerp(g1, g2, progress),
            blue: lerp(b1, b2, progress),
            alpha: lerp(a1, a2, progress)
        )
    }
}

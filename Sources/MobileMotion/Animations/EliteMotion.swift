import SwiftUI

/// A high-performance animation modifier for the portfolio.
/// 
/// This provides a standardized way to apply elite animations across the ecosystem.
public struct MobileMotionModifier: ViewModifier {
    public let scale: CGFloat
    public let opacity: Double
    public let duration: Double
    
    public init(scale: CGFloat = 1.0, opacity: Double = 1.0, duration: Double = 0.3) {
        self.scale = scale
        self.opacity = opacity
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.spring(response: duration, dampingFraction: 0.7), value: scale)
            .animation(.spring(response: duration, dampingFraction: 0.7), value: opacity)
    }
}

public extension View {
    /// Applies the elite MobileMotion signature animation.
    func mobileMotion(scale: CGFloat = 1.0, opacity: Double = 1.0, duration: Double = 0.3) -> some View {
        self.modifier(MobileMotionModifier(scale: scale, opacity: opacity, duration: duration))
    }
}

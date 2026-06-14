import SwiftUI

/// A highly calibrated, physics-based interactive gesture.
/// 
/// This gesture tracks velocity and converts it into fluid decay animations,
/// mimicking the exact spatial feel of native Apple applications.
public struct FluidGestureModifier: ViewModifier {
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .offset(offset)
            .scaleEffect(isDragging ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        // Apply friction logic for a premium feel
                        let friction = 0.5
                        offset = CGSize(
                            width: value.translation.width * friction,
                            height: value.translation.height * friction
                        )
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // Physics-based decay based on final velocity
                        let velocityX = value.velocity.width
                        let velocityY = value.velocity.height
                        
                        if abs(velocityX) > 1000 || abs(velocityY) > 1000 {
                            // Fling off screen
                            offset = CGSize(width: velocityX, height: velocityY)
                        } else {
                            // Snap back to origin
                            offset = .zero
                        }
                    }
            )
    }
}

public extension View {
    /// Applies a physics-based, fluid interaction to any view.
    func fluidGesture() -> some View {
        self.modifier(FluidGestureModifier())
    }
}

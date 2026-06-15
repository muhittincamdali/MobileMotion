import SwiftUI

#if canImport(UIKit)
import UIKit

/// MobileMotion: Spatial Haptic Engine.
/// 
/// Advanced haptic sequences calibrated to match physics-based gestures, 
/// creating an unmatched sense of tangibility in the digital environment.
@MainActor
public struct SpatialHaptics {
    
    /// Plays a 'Rubber-Band' haptic effect for over-scroll or limits.
    public static func rubberBand() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
    }
    
    /// Plays a 'Magnetic-Lock' haptic effect for grid snapping.
    public static func magneticSnap() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
    }
}
#endif

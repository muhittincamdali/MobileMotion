//
//  MobileMotion.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// MobileMotion provides a unified interface for device motion sensors,
/// physics-based animations, gesture-driven interactions, and activity recognition.
///
/// Use ``MotionManager`` for raw sensor access, ``ActivityRecognizer`` for
/// detecting user activities, and the SwiftUI property wrappers for declarative
/// sensor bindings in your views.
///
/// ```swift
/// import MobileMotion
///
/// let manager = MotionManager()
/// manager.startAccelerometer { data in
///     print(data.acceleration)
/// }
/// ```
public enum MobileMotion {

    /// Library version string.
    public static let version = "2.0.0"

    /// Bundle identifier used for logging.
    static let bundleIdentifier = "com.muhittincamdali.MobileMotion"
}

//
//  GestureDetector.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// Types of motion gestures that can be detected from sensor data.
public enum MotionGestureType: String, CaseIterable, Sendable {
    /// Device shake (rapid back-and-forth).
    case shake

    /// Tilt forward (pitch increase).
    case tiltForward

    /// Tilt backward (pitch decrease).
    case tiltBackward

    /// Tilt left (roll decrease).
    case tiltLeft

    /// Tilt right (roll increase).
    case tiltRight

    /// Device turned face down.
    case faceDown

    /// Device turned face up.
    case faceUp

    /// Quick twist / wrist flick.
    case twist

    /// Significant impact detected.
    case impact

    /// Device picked up from rest.
    case pickup
}

/// Configuration thresholds for gesture detection.
public struct GestureDetectorConfig: Sendable {
    /// Minimum acceleration magnitude to register a shake (G).
    public var shakeThreshold: Double

    /// Minimum number of direction changes for a shake.
    public var shakeMinChanges: Int

    /// Time window for counting shake direction changes (seconds).
    public var shakeWindow: TimeInterval

    /// Tilt angle threshold in radians.
    public var tiltThreshold: Double

    /// Impact acceleration threshold (G).
    public var impactThreshold: Double

    /// Pickup acceleration change threshold (G).
    public var pickupThreshold: Double

    /// Twist angular velocity threshold (rad/s).
    public var twistThreshold: Double

    /// Default configuration.
    public static let `default` = GestureDetectorConfig(
        shakeThreshold: 1.5,
        shakeMinChanges: 3,
        shakeWindow: 0.5,
        tiltThreshold: 0.4,
        impactThreshold: 3.0,
        pickupThreshold: 0.5,
        twistThreshold: 5.0
    )

    /// Sensitive configuration (easier to trigger).
    public static let sensitive = GestureDetectorConfig(
        shakeThreshold: 1.0,
        shakeMinChanges: 2,
        shakeWindow: 0.7,
        tiltThreshold: 0.25,
        impactThreshold: 2.0,
        pickupThreshold: 0.3,
        twistThreshold: 3.5
    )

    public init(
        shakeThreshold: Double = 1.5,
        shakeMinChanges: Int = 3,
        shakeWindow: TimeInterval = 0.5,
        tiltThreshold: Double = 0.4,
        impactThreshold: Double = 3.0,
        pickupThreshold: Double = 0.5,
        twistThreshold: Double = 5.0
    ) {
        self.shakeThreshold = shakeThreshold
        self.shakeMinChanges = shakeMinChanges
        self.shakeWindow = shakeWindow
        self.tiltThreshold = tiltThreshold
        self.impactThreshold = impactThreshold
        self.pickupThreshold = pickupThreshold
        self.twistThreshold = twistThreshold
    }
}

/// Detected gesture event.
public struct DetectedGesture: Sendable {
    /// The type of gesture detected.
    public let type: MotionGestureType

    /// Intensity of the gesture (0–1 normalized, >1 for strong).
    public let intensity: Double

    /// When the gesture was detected.
    public let timestamp: Date

    public init(type: MotionGestureType, intensity: Double, timestamp: Date = Date()) {
        self.type = type
        self.intensity = intensity
        self.timestamp = timestamp
    }
}

/// Detects motion gestures (shake, tilt, twist, impact, etc.) from sensor data.
///
/// ```swift
/// let detector = GestureDetector()
///
/// detector.onGesture = { gesture in
///     switch gesture.type {
///     case .shake:
///         print("Device shaken! Intensity: \(gesture.intensity)")
///     case .faceDown:
///         print("Placed face down")
///     default:
///         break
///     }
/// }
///
/// detector.start()
/// ```
public final class GestureDetector {

    // MARK: - Properties

    private let manager: MotionManager
    private let config: GestureDetectorConfig

    /// Called when a gesture is detected.
    public var onGesture: ((DetectedGesture) -> Void)?

    /// Set of gesture types to listen for. Nil means all gestures.
    public var enabledGestures: Set<MotionGestureType>?

    /// Whether the detector is running.
    public private(set) var isActive: Bool = false

    // MARK: - Detection State

    private var shakeTimestamps: [TimeInterval] = []
    private var lastShakeDirection: Double = 0
    private var previousAccelMagnitude: Double = 1.0
    private var previousGravityZ: Double = 0

    // MARK: - Initialization

    /// Creates a gesture detector.
    ///
    /// - Parameters:
    ///   - manager: Shared motion manager.
    ///   - config: Detection thresholds.
    public init(
        manager: MotionManager? = nil,
        config: GestureDetectorConfig = .default
    ) {
        self.manager = manager ?? MotionManager()
        self.config = config
    }

    // MARK: - Control

    /// Starts gesture detection using device motion.
    ///
    /// - Parameter interval: Sensor update interval. Default `0.02`.
    public func start(interval: TimeInterval = 0.02) {
        guard !isActive else { return }
        isActive = true

        manager.startDeviceMotion(interval: interval) { [weak self] motion in
            self?.processMotion(motion)
        }
    }

    /// Stops gesture detection.
    public func stop() {
        isActive = false
        manager.stopDeviceMotion()
        shakeTimestamps.removeAll()
    }

    // MARK: - Processing

    private func processMotion(_ motion: CMDeviceMotion) {
        detectShake(motion)
        detectTilt(motion)
        detectFaceOrientation(motion)
        detectTwist(motion)
        detectImpact(motion)
        detectPickup(motion)

        previousAccelMagnitude = userAccelMagnitude(motion)
        previousGravityZ = motion.gravity.z
    }

    // MARK: - Shake Detection

    private func detectShake(_ motion: CMDeviceMotion) {
        guard isEnabled(.shake) else { return }

        let accel = motion.userAcceleration
        let mag = (accel.x * accel.x + accel.y * accel.y + accel.z * accel.z).squareRoot()

        if mag > config.shakeThreshold {
            let direction = accel.x + accel.y
            if direction * lastShakeDirection < 0 {
                shakeTimestamps.append(motion.timestamp)
            }
            lastShakeDirection = direction
        }

        // Prune old entries outside the time window
        let cutoff = motion.timestamp - config.shakeWindow
        shakeTimestamps.removeAll { $0 < cutoff }

        if shakeTimestamps.count >= config.shakeMinChanges {
            let intensity = min(2.0, mag / config.shakeThreshold)
            emit(.shake, intensity: intensity)
            shakeTimestamps.removeAll()
        }
    }

    // MARK: - Tilt Detection

    private func detectTilt(_ motion: CMDeviceMotion) {
        let pitch = motion.attitude.pitch
        let roll = motion.attitude.roll
        let threshold = config.tiltThreshold

        if isEnabled(.tiltForward), pitch > threshold {
            emit(.tiltForward, intensity: pitch / (.pi / 2))
        }
        if isEnabled(.tiltBackward), pitch < -threshold {
            emit(.tiltBackward, intensity: abs(pitch) / (.pi / 2))
        }
        if isEnabled(.tiltLeft), roll < -threshold {
            emit(.tiltLeft, intensity: abs(roll) / (.pi / 2))
        }
        if isEnabled(.tiltRight), roll > threshold {
            emit(.tiltRight, intensity: roll / (.pi / 2))
        }
    }

    // MARK: - Face Orientation

    private func detectFaceOrientation(_ motion: CMDeviceMotion) {
        let gz = motion.gravity.z
        let prevGz = previousGravityZ

        if isEnabled(.faceDown), gz > 0.9, prevGz <= 0.9 {
            emit(.faceDown, intensity: gz)
        }
        if isEnabled(.faceUp), gz < -0.9, prevGz >= -0.9 {
            emit(.faceUp, intensity: abs(gz))
        }
    }

    // MARK: - Twist Detection

    private func detectTwist(_ motion: CMDeviceMotion) {
        guard isEnabled(.twist) else { return }

        let yawRate = abs(motion.rotationRate.z)
        if yawRate > config.twistThreshold {
            emit(.twist, intensity: yawRate / config.twistThreshold)
        }
    }

    // MARK: - Impact Detection

    private func detectImpact(_ motion: CMDeviceMotion) {
        guard isEnabled(.impact) else { return }

        let mag = userAccelMagnitude(motion)
        if mag > config.impactThreshold {
            emit(.impact, intensity: mag / config.impactThreshold)
        }
    }

    // MARK: - Pickup Detection

    private func detectPickup(_ motion: CMDeviceMotion) {
        guard isEnabled(.pickup) else { return }

        let mag = userAccelMagnitude(motion)
        let delta = abs(mag - previousAccelMagnitude)

        if delta > config.pickupThreshold, previousAccelMagnitude < 0.1 {
            emit(.pickup, intensity: delta / config.pickupThreshold)
        }
    }

    // MARK: - Helpers

    private func userAccelMagnitude(_ motion: CMDeviceMotion) -> Double {
        let a = motion.userAcceleration
        return (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
    }

    private func isEnabled(_ type: MotionGestureType) -> Bool {
        guard let enabled = enabledGestures else { return true }
        return enabled.contains(type)
    }

    private func emit(_ type: MotionGestureType, intensity: Double) {
        let gesture = DetectedGesture(type: type, intensity: intensity)
        onGesture?(gesture)
    }
}

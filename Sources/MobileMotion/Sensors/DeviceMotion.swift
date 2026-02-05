//
//  DeviceMotion.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// Fused device motion data combining accelerometer, gyroscope,
/// and magnetometer readings through sensor-fusion algorithms.
///
/// Provides separated gravity and user acceleration, along with
/// attitude (pitch, roll, yaw) and rotation rate.
public struct DeviceMotionData: Sendable {

    /// Device attitude as Euler angles.
    public struct Attitude: Sendable, Equatable {
        /// Pitch in radians (rotation around X axis). Positive tilts forward.
        public let pitch: Double
        /// Roll in radians (rotation around Y axis). Positive tilts right.
        public let roll: Double
        /// Yaw in radians (rotation around Z axis). Positive rotates left.
        public let yaw: Double

        public init(pitch: Double, roll: Double, yaw: Double) {
            self.pitch = pitch
            self.roll = roll
            self.yaw = yaw
        }

        /// A neutral attitude.
        public static let zero = Attitude(pitch: 0, roll: 0, yaw: 0)
    }

    /// Three-component vector.
    public struct Vector3: Sendable, Equatable {
        public let x: Double
        public let y: Double
        public let z: Double

        public var magnitude: Double {
            (x * x + y * y + z * z).squareRoot()
        }

        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }

        public static let zero = Vector3(x: 0, y: 0, z: 0)
    }

    /// Current device attitude (pitch, roll, yaw).
    public let attitude: Attitude

    /// Gravity vector in the device's reference frame.
    public let gravity: Vector3

    /// Acceleration caused by the user, excluding gravity.
    public let userAcceleration: Vector3

    /// Rotation rate from gyroscope after sensor fusion.
    public let rotationRate: Vector3

    /// Calibrated magnetic field direction and accuracy.
    public let magneticField: Vector3

    /// Timestamp of the measurement.
    public let timestamp: TimeInterval

    /// Creates fused device motion data.
    public init(
        attitude: Attitude,
        gravity: Vector3,
        userAcceleration: Vector3,
        rotationRate: Vector3,
        magneticField: Vector3 = .zero,
        timestamp: TimeInterval = 0
    ) {
        self.attitude = attitude
        self.gravity = gravity
        self.userAcceleration = userAcceleration
        self.rotationRate = rotationRate
        self.magneticField = magneticField
        self.timestamp = timestamp
    }

    /// Creates from a `CMDeviceMotion` reading.
    public init(_ motion: CMDeviceMotion) {
        self.attitude = Attitude(
            pitch: motion.attitude.pitch,
            roll: motion.attitude.roll,
            yaw: motion.attitude.yaw
        )
        self.gravity = Vector3(
            x: motion.gravity.x,
            y: motion.gravity.y,
            z: motion.gravity.z
        )
        self.userAcceleration = Vector3(
            x: motion.userAcceleration.x,
            y: motion.userAcceleration.y,
            z: motion.userAcceleration.z
        )
        self.rotationRate = Vector3(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        )
        self.magneticField = Vector3(
            x: motion.magneticField.field.x,
            y: motion.magneticField.field.y,
            z: motion.magneticField.field.z
        )
        self.timestamp = motion.timestamp
    }

    /// A zero reading.
    public static let zero = DeviceMotionData(
        attitude: .zero,
        gravity: .zero,
        userAcceleration: .zero,
        rotationRate: .zero
    )
}

/// Wrapper for fused device-motion data.
///
/// Device motion provides the highest quality sensor data by fusing
/// accelerometer, gyroscope, and optionally magnetometer readings.
///
/// ```swift
/// let dm = DeviceMotionSensor()
/// dm.start { data in
///     print("Pitch: \(data.attitude.pitch)")
///     print("User accel: \(data.userAcceleration.magnitude)G")
/// }
/// ```
public final class DeviceMotionSensor {

    // MARK: - Properties

    private let manager: MotionManager

    /// Most recent fused reading.
    public private(set) var latest: DeviceMotionData = .zero

    /// Whether device motion is running.
    public var isActive: Bool { manager.isDeviceMotionActive }

    /// Whether device motion is available.
    public var isAvailable: Bool { manager.isDeviceMotionAvailable }

    // MARK: - Initialization

    /// Creates a device motion sensor.
    ///
    /// - Parameter manager: Shared motion manager. Creates one if nil.
    public init(manager: MotionManager? = nil) {
        self.manager = manager ?? MotionManager()
    }

    // MARK: - Control

    /// Starts device motion updates.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02`.
    ///   - referenceFrame: Attitude reference frame.
    ///   - handler: Called with each new reading.
    public func start(
        interval: TimeInterval = 0.02,
        referenceFrame: CMAttitudeReferenceFrame = .xArbitraryZVertical,
        handler: @escaping (DeviceMotionData) -> Void
    ) {
        manager.startDeviceMotion(
            interval: interval,
            referenceFrame: referenceFrame
        ) { [weak self] motion in
            let data = DeviceMotionData(motion)
            self?.latest = data
            handler(data)
        }
    }

    /// Stops device motion updates.
    public func stop() {
        manager.stopDeviceMotion()
    }
}

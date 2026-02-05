//
//  MotionManager.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// Unified wrapper around `CMMotionManager` providing access to
/// accelerometer, gyroscope, magnetometer, and fused device-motion data.
///
/// `MotionManager` simplifies sensor lifecycle management and provides
/// both closure-based and Combine-compatible interfaces.
///
/// ```swift
/// let manager = MotionManager()
///
/// manager.startAccelerometer(interval: 0.02) { data in
///     print("x: \(data.acceleration.x)")
/// }
/// ```
///
/// - Important: Only one `CMMotionManager` should exist per app.
///   Share a single ``MotionManager`` instance across your codebase.
public final class MotionManager {

    // MARK: - Properties

    /// The underlying Core Motion manager.
    public let coreMotionManager: CMMotionManager

    /// Queue used for sensor callbacks.
    private let operationQueue: OperationQueue

    /// Whether the accelerometer is currently active.
    public var isAccelerometerActive: Bool { coreMotionManager.isAccelerometerActive }

    /// Whether the gyroscope is currently active.
    public var isGyroscopeActive: Bool { coreMotionManager.isGyroActive }

    /// Whether the magnetometer is currently active.
    public var isMagnetometerActive: Bool { coreMotionManager.isMagnetometerActive }

    /// Whether device motion is currently active.
    public var isDeviceMotionActive: Bool { coreMotionManager.isDeviceMotionActive }

    // MARK: - Availability

    /// Whether accelerometer hardware is available.
    public var isAccelerometerAvailable: Bool { coreMotionManager.isAccelerometerAvailable }

    /// Whether gyroscope hardware is available.
    public var isGyroscopeAvailable: Bool { coreMotionManager.isGyroAvailable }

    /// Whether magnetometer hardware is available.
    public var isMagnetometerAvailable: Bool { coreMotionManager.isMagnetometerAvailable }

    /// Whether device motion is available.
    public var isDeviceMotionAvailable: Bool { coreMotionManager.isDeviceMotionAvailable }

    // MARK: - Initialization

    /// Creates a new motion manager.
    ///
    /// - Parameter queue: Operation queue for callbacks. Defaults to a
    ///   serial queue named `"com.mobilemotion.sensors"`.
    public init(queue: OperationQueue? = nil) {
        self.coreMotionManager = CMMotionManager()
        if let queue = queue {
            self.operationQueue = queue
        } else {
            let q = OperationQueue()
            q.name = "com.mobilemotion.sensors"
            q.maxConcurrentOperationCount = 1
            self.operationQueue = q
        }
    }

    deinit {
        stopAll()
    }

    // MARK: - Accelerometer

    /// Starts accelerometer updates at the given interval.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02` (50 Hz).
    ///   - handler: Called on each update with accelerometer data.
    public func startAccelerometer(
        interval: TimeInterval = 0.02,
        handler: @escaping (CMAccelerometerData) -> Void
    ) {
        guard coreMotionManager.isAccelerometerAvailable else { return }
        coreMotionManager.accelerometerUpdateInterval = interval
        coreMotionManager.startAccelerometerUpdates(to: operationQueue) { data, error in
            guard let data = data, error == nil else { return }
            handler(data)
        }
    }

    /// Stops accelerometer updates.
    public func stopAccelerometer() {
        coreMotionManager.stopAccelerometerUpdates()
    }

    /// Returns the most recent accelerometer data, if available.
    public var latestAccelerometerData: CMAccelerometerData? {
        coreMotionManager.accelerometerData
    }

    // MARK: - Gyroscope

    /// Starts gyroscope updates at the given interval.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02` (50 Hz).
    ///   - handler: Called on each update with gyroscope data.
    public func startGyroscope(
        interval: TimeInterval = 0.02,
        handler: @escaping (CMGyroData) -> Void
    ) {
        guard coreMotionManager.isGyroAvailable else { return }
        coreMotionManager.gyroUpdateInterval = interval
        coreMotionManager.startGyroUpdates(to: operationQueue) { data, error in
            guard let data = data, error == nil else { return }
            handler(data)
        }
    }

    /// Stops gyroscope updates.
    public func stopGyroscope() {
        coreMotionManager.stopGyroUpdates()
    }

    /// Returns the most recent gyroscope data, if available.
    public var latestGyroscopeData: CMGyroData? {
        coreMotionManager.gyroData
    }

    // MARK: - Magnetometer

    /// Starts magnetometer updates at the given interval.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02` (50 Hz).
    ///   - handler: Called on each update with magnetometer data.
    public func startMagnetometer(
        interval: TimeInterval = 0.02,
        handler: @escaping (CMMagnetometerData) -> Void
    ) {
        guard coreMotionManager.isMagnetometerAvailable else { return }
        coreMotionManager.magnetometerUpdateInterval = interval
        coreMotionManager.startMagnetometerUpdates(to: operationQueue) { data, error in
            guard let data = data, error == nil else { return }
            handler(data)
        }
    }

    /// Stops magnetometer updates.
    public func stopMagnetometer() {
        coreMotionManager.stopMagnetometerUpdates()
    }

    /// Returns the most recent magnetometer data, if available.
    public var latestMagnetometerData: CMMagnetometerData? {
        coreMotionManager.magnetometerData
    }

    // MARK: - Device Motion

    /// Starts device motion updates using sensor fusion.
    ///
    /// Device motion combines accelerometer, gyroscope, and magnetometer
    /// data to provide attitude, rotation rate, gravity, and user acceleration.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02` (50 Hz).
    ///   - referenceFrame: Attitude reference frame. Default `.xArbitraryZVertical`.
    ///   - handler: Called on each update with fused motion data.
    public func startDeviceMotion(
        interval: TimeInterval = 0.02,
        referenceFrame: CMAttitudeReferenceFrame = .xArbitraryZVertical,
        handler: @escaping (CMDeviceMotion) -> Void
    ) {
        guard coreMotionManager.isDeviceMotionAvailable else { return }
        coreMotionManager.deviceMotionUpdateInterval = interval
        coreMotionManager.startDeviceMotionUpdates(
            using: referenceFrame,
            to: operationQueue
        ) { motion, error in
            guard let motion = motion, error == nil else { return }
            handler(motion)
        }
    }

    /// Stops device motion updates.
    public func stopDeviceMotion() {
        coreMotionManager.stopDeviceMotionUpdates()
    }

    /// Returns the most recent device motion data, if available.
    public var latestDeviceMotion: CMDeviceMotion? {
        coreMotionManager.deviceMotion
    }

    // MARK: - Convenience

    /// Stops all active sensor updates.
    public func stopAll() {
        stopAccelerometer()
        stopGyroscope()
        stopMagnetometer()
        stopDeviceMotion()
    }
}

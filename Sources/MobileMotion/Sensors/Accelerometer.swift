//
//  Accelerometer.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// A three-axis acceleration reading in G-forces.
///
/// Positive X points right when holding the device in portrait,
/// positive Y points up, and positive Z points toward the user.
public struct AccelerationData: Sendable, Equatable {
    /// Acceleration along the X axis (G).
    public let x: Double

    /// Acceleration along the Y axis (G).
    public let y: Double

    /// Acceleration along the Z axis (G).
    public let z: Double

    /// Timestamp of the measurement.
    public let timestamp: TimeInterval

    /// Magnitude of the acceleration vector.
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    /// Creates an acceleration data point.
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// Creates from a `CMAccelerometerData` reading.
    public init(_ data: CMAccelerometerData) {
        self.x = data.acceleration.x
        self.y = data.acceleration.y
        self.z = data.acceleration.z
        self.timestamp = data.timestamp
    }

    /// A zero reading.
    public static let zero = AccelerationData(x: 0, y: 0, z: 0)
}

/// Dedicated accelerometer wrapper with buffering and statistics.
///
/// ```swift
/// let accel = Accelerometer()
/// accel.start { data in
///     print("Magnitude: \(data.magnitude)G")
/// }
/// ```
public final class Accelerometer {

    // MARK: - Properties

    private let manager: MotionManager

    /// Ring buffer storing the last `bufferSize` readings.
    public private(set) var buffer: [AccelerationData] = []

    /// Maximum number of readings to keep in the buffer.
    public var bufferSize: Int = 100

    /// Most recent reading.
    public private(set) var latest: AccelerationData = .zero

    /// Whether the accelerometer is running.
    public var isActive: Bool { manager.isAccelerometerActive }

    /// Whether hardware is available.
    public var isAvailable: Bool { manager.isAccelerometerAvailable }

    // MARK: - Initialization

    /// Creates an accelerometer wrapper.
    ///
    /// - Parameter manager: Shared motion manager. Creates one if nil.
    public init(manager: MotionManager? = nil) {
        self.manager = manager ?? MotionManager()
    }

    // MARK: - Control

    /// Starts accelerometer updates.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02`.
    ///   - handler: Called with each new reading.
    public func start(
        interval: TimeInterval = 0.02,
        handler: @escaping (AccelerationData) -> Void
    ) {
        manager.startAccelerometer(interval: interval) { [weak self] cmData in
            guard let self = self else { return }
            let data = AccelerationData(cmData)
            self.latest = data
            self.appendToBuffer(data)
            handler(data)
        }
    }

    /// Stops accelerometer updates.
    public func stop() {
        manager.stopAccelerometer()
    }

    // MARK: - Statistics

    /// Average acceleration over the buffer.
    public var average: AccelerationData {
        guard !buffer.isEmpty else { return .zero }
        let count = Double(buffer.count)
        let sumX = buffer.reduce(0.0) { $0 + $1.x }
        let sumY = buffer.reduce(0.0) { $0 + $1.y }
        let sumZ = buffer.reduce(0.0) { $0 + $1.z }
        return AccelerationData(x: sumX / count, y: sumY / count, z: sumZ / count)
    }

    /// Peak magnitude in the buffer.
    public var peakMagnitude: Double {
        buffer.map(\.magnitude).max() ?? 0
    }

    // MARK: - Private

    private func appendToBuffer(_ data: AccelerationData) {
        buffer.append(data)
        if buffer.count > bufferSize {
            buffer.removeFirst(buffer.count - bufferSize)
        }
    }
}

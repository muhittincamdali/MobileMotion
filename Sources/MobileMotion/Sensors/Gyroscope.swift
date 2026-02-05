//
//  Gyroscope.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// A three-axis rotation rate reading in radians per second.
public struct RotationRateData: Sendable, Equatable {
    /// Rotation around the X axis (rad/s).
    public let x: Double

    /// Rotation around the Y axis (rad/s).
    public let y: Double

    /// Rotation around the Z axis (rad/s).
    public let z: Double

    /// Timestamp of the measurement.
    public let timestamp: TimeInterval

    /// Magnitude of the rotation vector.
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    /// Creates a rotation rate data point.
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// Creates from a `CMGyroData` reading.
    public init(_ data: CMGyroData) {
        self.x = data.rotationRate.x
        self.y = data.rotationRate.y
        self.z = data.rotationRate.z
        self.timestamp = data.timestamp
    }

    /// A zero reading.
    public static let zero = RotationRateData(x: 0, y: 0, z: 0)
}

/// Dedicated gyroscope wrapper with buffering and statistics.
///
/// ```swift
/// let gyro = Gyroscope()
/// gyro.start { data in
///     print("Rotation: \(data.magnitude) rad/s")
/// }
/// ```
public final class Gyroscope {

    // MARK: - Properties

    private let manager: MotionManager

    /// Ring buffer storing recent readings.
    public private(set) var buffer: [RotationRateData] = []

    /// Maximum buffer size.
    public var bufferSize: Int = 100

    /// Most recent reading.
    public private(set) var latest: RotationRateData = .zero

    /// Whether the gyroscope is running.
    public var isActive: Bool { manager.isGyroscopeActive }

    /// Whether hardware is available.
    public var isAvailable: Bool { manager.isGyroscopeAvailable }

    // MARK: - Initialization

    /// Creates a gyroscope wrapper.
    ///
    /// - Parameter manager: Shared motion manager. Creates one if nil.
    public init(manager: MotionManager? = nil) {
        self.manager = manager ?? MotionManager()
    }

    // MARK: - Control

    /// Starts gyroscope updates.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02`.
    ///   - handler: Called with each new reading.
    public func start(
        interval: TimeInterval = 0.02,
        handler: @escaping (RotationRateData) -> Void
    ) {
        manager.startGyroscope(interval: interval) { [weak self] cmData in
            guard let self = self else { return }
            let data = RotationRateData(cmData)
            self.latest = data
            self.appendToBuffer(data)
            handler(data)
        }
    }

    /// Stops gyroscope updates.
    public func stop() {
        manager.stopGyroscope()
    }

    // MARK: - Statistics

    /// Average rotation rate over the buffer.
    public var average: RotationRateData {
        guard !buffer.isEmpty else { return .zero }
        let count = Double(buffer.count)
        let sumX = buffer.reduce(0.0) { $0 + $1.x }
        let sumY = buffer.reduce(0.0) { $0 + $1.y }
        let sumZ = buffer.reduce(0.0) { $0 + $1.z }
        return RotationRateData(x: sumX / count, y: sumY / count, z: sumZ / count)
    }

    /// Peak rotation magnitude in the buffer.
    public var peakMagnitude: Double {
        buffer.map(\.magnitude).max() ?? 0
    }

    // MARK: - Private

    private func appendToBuffer(_ data: RotationRateData) {
        buffer.append(data)
        if buffer.count > bufferSize {
            buffer.removeFirst(buffer.count - bufferSize)
        }
    }
}

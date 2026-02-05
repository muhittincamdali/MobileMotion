//
//  Magnetometer.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// A three-axis magnetic field reading in microteslas.
public struct MagneticFieldData: Sendable, Equatable {
    /// Magnetic field along the X axis (µT).
    public let x: Double

    /// Magnetic field along the Y axis (µT).
    public let y: Double

    /// Magnetic field along the Z axis (µT).
    public let z: Double

    /// Timestamp of the measurement.
    public let timestamp: TimeInterval

    /// Magnitude of the magnetic field vector.
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    /// Creates a magnetic field data point.
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    /// Creates from a `CMMagnetometerData` reading.
    public init(_ data: CMMagnetometerData) {
        self.x = data.magneticField.x
        self.y = data.magneticField.y
        self.z = data.magneticField.z
        self.timestamp = data.timestamp
    }

    /// A zero reading.
    public static let zero = MagneticFieldData(x: 0, y: 0, z: 0)
}

/// Dedicated magnetometer wrapper with compass heading support.
///
/// ```swift
/// let mag = Magnetometer()
/// mag.start { data in
///     print("Field strength: \(data.magnitude) µT")
/// }
/// ```
public final class Magnetometer {

    // MARK: - Properties

    private let manager: MotionManager

    /// Ring buffer storing recent readings.
    public private(set) var buffer: [MagneticFieldData] = []

    /// Maximum buffer size.
    public var bufferSize: Int = 100

    /// Most recent reading.
    public private(set) var latest: MagneticFieldData = .zero

    /// Whether the magnetometer is running.
    public var isActive: Bool { manager.isMagnetometerActive }

    /// Whether hardware is available.
    public var isAvailable: Bool { manager.isMagnetometerAvailable }

    // MARK: - Initialization

    /// Creates a magnetometer wrapper.
    ///
    /// - Parameter manager: Shared motion manager. Creates one if nil.
    public init(manager: MotionManager? = nil) {
        self.manager = manager ?? MotionManager()
    }

    // MARK: - Control

    /// Starts magnetometer updates.
    ///
    /// - Parameters:
    ///   - interval: Update interval in seconds. Default `0.02`.
    ///   - handler: Called with each new reading.
    public func start(
        interval: TimeInterval = 0.02,
        handler: @escaping (MagneticFieldData) -> Void
    ) {
        manager.startMagnetometer(interval: interval) { [weak self] cmData in
            guard let self = self else { return }
            let data = MagneticFieldData(cmData)
            self.latest = data
            self.appendToBuffer(data)
            handler(data)
        }
    }

    /// Stops magnetometer updates.
    public func stop() {
        manager.stopMagnetometer()
    }

    // MARK: - Statistics

    /// Average magnetic field over the buffer.
    public var average: MagneticFieldData {
        guard !buffer.isEmpty else { return .zero }
        let count = Double(buffer.count)
        let sumX = buffer.reduce(0.0) { $0 + $1.x }
        let sumY = buffer.reduce(0.0) { $0 + $1.y }
        let sumZ = buffer.reduce(0.0) { $0 + $1.z }
        return MagneticFieldData(x: sumX / count, y: sumY / count, z: sumZ / count)
    }

    /// Peak field magnitude in the buffer.
    public var peakMagnitude: Double {
        buffer.map(\.magnitude).max() ?? 0
    }

    /// Estimated compass heading in degrees (0–360).
    ///
    /// Uses the X and Y components of the magnetic field to approximate
    /// heading. For accurate results, ensure the device is held level.
    public var estimatedHeading: Double {
        let heading = atan2(latest.y, latest.x) * 180.0 / .pi
        return heading < 0 ? heading + 360 : heading
    }

    // MARK: - Private

    private func appendToBuffer(_ data: MagneticFieldData) {
        buffer.append(data)
        if buffer.count > bufferSize {
            buffer.removeFirst(buffer.count - bufferSize)
        }
    }
}

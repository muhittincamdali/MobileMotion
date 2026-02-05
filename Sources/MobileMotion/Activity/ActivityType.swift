//
//  ActivityType.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation

/// Recognized user activity types.
///
/// Maps to `CMMotionActivity` flags but provides a cleaner API.
public enum ActivityType: String, CaseIterable, Sendable, CustomStringConvertible {
    /// User is stationary.
    case stationary

    /// User is walking.
    case walking

    /// User is running.
    case running

    /// User is cycling.
    case cycling

    /// User is in an automotive vehicle.
    case automotive

    /// Activity could not be determined.
    case unknown

    public var description: String { rawValue }

    /// SF Symbol name representing the activity.
    public var symbolName: String {
        switch self {
        case .stationary:  return "figure.stand"
        case .walking:     return "figure.walk"
        case .running:     return "figure.run"
        case .cycling:     return "figure.outdoor.cycle"
        case .automotive:  return "car.fill"
        case .unknown:     return "questionmark.circle"
        }
    }
}

/// A snapshot of recognized activity with confidence.
public struct ActivitySnapshot: Sendable {
    /// The detected activity type.
    public let activity: ActivityType

    /// Confidence level (0 = low, 1 = medium, 2 = high).
    public let confidence: Int

    /// When the activity was detected.
    public let date: Date

    /// Whether this is a high-confidence reading.
    public var isHighConfidence: Bool { confidence == 2 }

    public init(activity: ActivityType, confidence: Int, date: Date = Date()) {
        self.activity = activity
        self.confidence = confidence
        self.date = date
    }
}

//
//  ActivityRecognizer.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import Foundation
import CoreMotion

/// Recognizes user activities (walking, running, cycling, etc.)
/// using `CMMotionActivityManager`.
///
/// ```swift
/// let recognizer = ActivityRecognizer()
///
/// recognizer.startUpdates { snapshot in
///     print("Activity: \(snapshot.activity)")
/// }
///
/// // Query recent history
/// let history = await recognizer.queryActivities(
///     from: Date().addingTimeInterval(-3600),
///     to: Date()
/// )
/// ```
///
/// - Important: Add the `NSMotionUsageDescription` key to your Info.plist.
public final class ActivityRecognizer {

    // MARK: - Properties

    private let activityManager: CMMotionActivityManager
    private let operationQueue: OperationQueue

    /// Most recently detected activity.
    public private(set) var currentActivity: ActivitySnapshot?

    /// Whether activity recognition is available on this device.
    public static var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    // MARK: - Initialization

    public init() {
        self.activityManager = CMMotionActivityManager()
        let queue = OperationQueue()
        queue.name = "com.mobilemotion.activity"
        queue.maxConcurrentOperationCount = 1
        self.operationQueue = queue
    }

    deinit {
        stopUpdates()
    }

    // MARK: - Live Updates

    /// Starts receiving real-time activity updates.
    ///
    /// - Parameter handler: Called when a new activity is detected.
    public func startUpdates(handler: @escaping (ActivitySnapshot) -> Void) {
        guard Self.isAvailable else { return }

        activityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let activity = activity else { return }

            let snapshot = Self.convert(activity)
            self?.currentActivity = snapshot
            handler(snapshot)
        }
    }

    /// Stops live activity updates.
    public func stopUpdates() {
        activityManager.stopActivityUpdates()
    }

    // MARK: - Historical Query

    /// Queries activity history for a date range.
    ///
    /// - Parameters:
    ///   - start: Start date.
    ///   - end: End date.
    ///   - completion: Called with an array of activity snapshots.
    public func queryActivities(
        from start: Date,
        to end: Date,
        completion: @escaping ([ActivitySnapshot]) -> Void
    ) {
        guard Self.isAvailable else {
            completion([])
            return
        }

        activityManager.queryActivityStarting(from: start, to: end, to: operationQueue) { activities, _ in
            let snapshots = (activities ?? []).map(Self.convert)
            completion(snapshots)
        }
    }

    // MARK: - Step Counting

    /// Queries the step count between two dates using the pedometer.
    ///
    /// - Parameters:
    ///   - start: Start date.
    ///   - end: End date.
    ///   - completion: Called with the step count or nil on failure.
    public func querySteps(
        from start: Date,
        to end: Date,
        completion: @escaping (Int?) -> Void
    ) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(nil)
            return
        }

        let pedometer = CMPedometer()
        pedometer.queryPedometerData(from: start, to: end) { data, _ in
            completion(data?.numberOfSteps.intValue)
        }
    }

    // MARK: - Conversion

    private static func convert(_ activity: CMMotionActivity) -> ActivitySnapshot {
        let type: ActivityType
        let confidence = activity.confidence.rawValue

        if activity.running {
            type = .running
        } else if activity.cycling {
            type = .cycling
        } else if activity.automotive {
            type = .automotive
        } else if activity.walking {
            type = .walking
        } else if activity.stationary {
            type = .stationary
        } else {
            type = .unknown
        }

        return ActivitySnapshot(
            activity: type,
            confidence: confidence,
            date: activity.startDate
        )
    }
}

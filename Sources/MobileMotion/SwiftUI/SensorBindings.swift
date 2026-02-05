//
//  SensorBindings.swift
//  MobileMotion
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
import CoreMotion

// MARK: - Accelerometer Observable

/// Observable object that publishes accelerometer data for SwiftUI.
///
/// ```swift
/// struct AccelerometerView: View {
///     @StateObject var sensor = AccelerometerObservable()
///
///     var body: some View {
///         VStack {
///             Text("X: \(sensor.data.x, specifier: "%.3f")")
///             Text("Y: \(sensor.data.y, specifier: "%.3f")")
///             Text("Z: \(sensor.data.z, specifier: "%.3f")")
///         }
///         .onAppear { sensor.start() }
///         .onDisappear { sensor.stop() }
///     }
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, *)
public final class AccelerometerObservable: ObservableObject {
    @Published public var data: AccelerationData = .zero
    @Published public var isActive: Bool = false

    private let accelerometer: Accelerometer

    public init(manager: MotionManager? = nil) {
        self.accelerometer = Accelerometer(manager: manager)
    }

    public func start(interval: TimeInterval = 0.05) {
        isActive = true
        accelerometer.start(interval: interval) { [weak self] newData in
            DispatchQueue.main.async {
                self?.data = newData
            }
        }
    }

    public func stop() {
        accelerometer.stop()
        isActive = false
    }
}

// MARK: - Gyroscope Observable

/// Observable object that publishes gyroscope data for SwiftUI.
@available(iOS 15.0, watchOS 8.0, *)
public final class GyroscopeObservable: ObservableObject {
    @Published public var data: RotationRateData = .zero
    @Published public var isActive: Bool = false

    private let gyroscope: Gyroscope

    public init(manager: MotionManager? = nil) {
        self.gyroscope = Gyroscope(manager: manager)
    }

    public func start(interval: TimeInterval = 0.05) {
        isActive = true
        gyroscope.start(interval: interval) { [weak self] newData in
            DispatchQueue.main.async {
                self?.data = newData
            }
        }
    }

    public func stop() {
        gyroscope.stop()
        isActive = false
    }
}

// MARK: - Magnetometer Observable

/// Observable object that publishes magnetometer data for SwiftUI.
@available(iOS 15.0, watchOS 8.0, *)
public final class MagnetometerObservable: ObservableObject {
    @Published public var data: MagneticFieldData = .zero
    @Published public var heading: Double = 0
    @Published public var isActive: Bool = false

    private let magnetometer: Magnetometer

    public init(manager: MotionManager? = nil) {
        self.magnetometer = Magnetometer(manager: manager)
    }

    public func start(interval: TimeInterval = 0.05) {
        isActive = true
        magnetometer.start(interval: interval) { [weak self] newData in
            DispatchQueue.main.async {
                self?.data = newData
                self?.heading = self?.magnetometer.estimatedHeading ?? 0
            }
        }
    }

    public func stop() {
        magnetometer.stop()
        isActive = false
    }
}

// MARK: - Device Motion Observable

/// Observable object that publishes fused device motion data for SwiftUI.
///
/// ```swift
/// struct AttitudeView: View {
///     @StateObject var motion = DeviceMotionObservable()
///
///     var body: some View {
///         VStack {
///             Text("Pitch: \(motion.data.attitude.pitch, specifier: "%.2f")")
///             Text("Roll: \(motion.data.attitude.roll, specifier: "%.2f")")
///             Text("Yaw: \(motion.data.attitude.yaw, specifier: "%.2f")")
///         }
///         .onAppear { motion.start() }
///         .onDisappear { motion.stop() }
///     }
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, *)
public final class DeviceMotionObservable: ObservableObject {
    @Published public var data: DeviceMotionData = .zero
    @Published public var isActive: Bool = false

    private let sensor: DeviceMotionSensor

    public init(manager: MotionManager? = nil) {
        self.sensor = DeviceMotionSensor(manager: manager)
    }

    public func start(interval: TimeInterval = 0.05) {
        isActive = true
        sensor.start(interval: interval) { [weak self] newData in
            DispatchQueue.main.async {
                self?.data = newData
            }
        }
    }

    public func stop() {
        sensor.stop()
        isActive = false
    }
}

// MARK: - Activity Observable

/// Observable object that publishes activity recognition data for SwiftUI.
///
/// ```swift
/// struct ActivityView: View {
///     @StateObject var activity = ActivityObservable()
///
///     var body: some View {
///         if let snapshot = activity.current {
///             Label(snapshot.activity.description, systemImage: snapshot.activity.symbolName)
///         }
///     }
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, *)
public final class ActivityObservable: ObservableObject {
    @Published public var current: ActivitySnapshot?
    @Published public var isActive: Bool = false

    private let recognizer: ActivityRecognizer

    public init() {
        self.recognizer = ActivityRecognizer()
    }

    public func start() {
        isActive = true
        recognizer.startUpdates { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.current = snapshot
            }
        }
    }

    public func stop() {
        recognizer.stopUpdates()
        isActive = false
    }
}

// MARK: - Gesture Observable

/// Observable object that publishes detected motion gestures for SwiftUI.
///
/// ```swift
/// struct GestureView: View {
///     @StateObject var gestures = GestureObservable()
///
///     var body: some View {
///         Text(gestures.lastGesture?.type.rawValue ?? "None")
///             .onAppear { gestures.start() }
///     }
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, *)
public final class GestureObservable: ObservableObject {
    @Published public var lastGesture: DetectedGesture?
    @Published public var gestureHistory: [DetectedGesture] = []
    @Published public var isActive: Bool = false

    private let detector: GestureDetector

    /// Maximum number of gestures to keep in history.
    public var historyLimit: Int = 50

    public init(config: GestureDetectorConfig = .default) {
        self.detector = GestureDetector(config: config)
    }

    public func start() {
        isActive = true
        detector.onGesture = { [weak self] gesture in
            DispatchQueue.main.async {
                self?.lastGesture = gesture
                self?.gestureHistory.append(gesture)
                if let limit = self?.historyLimit,
                   let count = self?.gestureHistory.count,
                   count > limit {
                    self?.gestureHistory.removeFirst(count - limit)
                }
            }
        }
        detector.start()
    }

    public func stop() {
        detector.stop()
        isActive = false
    }
}

// MARK: - Sensor View Modifier

/// View modifier that starts/stops a sensor observable with the view lifecycle.
@available(iOS 15.0, watchOS 8.0, *)
struct SensorLifecycleModifier<T: ObservableObject>: ViewModifier {
    let observable: T
    let startAction: () -> Void
    let stopAction: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear { startAction() }
            .onDisappear { stopAction() }
    }
}

@available(iOS 15.0, watchOS 8.0, *)
public extension View {

    /// Automatically starts and stops accelerometer updates with the view lifecycle.
    func withAccelerometer(
        _ observable: AccelerometerObservable,
        interval: TimeInterval = 0.05
    ) -> some View {
        modifier(SensorLifecycleModifier(
            observable: observable,
            startAction: { observable.start(interval: interval) },
            stopAction: { observable.stop() }
        ))
    }

    /// Automatically starts and stops gyroscope updates with the view lifecycle.
    func withGyroscope(
        _ observable: GyroscopeObservable,
        interval: TimeInterval = 0.05
    ) -> some View {
        modifier(SensorLifecycleModifier(
            observable: observable,
            startAction: { observable.start(interval: interval) },
            stopAction: { observable.stop() }
        ))
    }

    /// Automatically starts and stops device motion updates with the view lifecycle.
    func withDeviceMotion(
        _ observable: DeviceMotionObservable,
        interval: TimeInterval = 0.05
    ) -> some View {
        modifier(SensorLifecycleModifier(
            observable: observable,
            startAction: { observable.start(interval: interval) },
            stopAction: { observable.stop() }
        ))
    }
}

#endif

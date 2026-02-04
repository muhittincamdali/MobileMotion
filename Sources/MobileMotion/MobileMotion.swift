import Foundation
import CoreMotion

/// MobileMotion - Motion and sensor management for iOS
public final class MobileMotion {
    public static let shared = MobileMotion()
    private let motionManager = CMMotionManager()
    
    private init() {}
    
    /// Start accelerometer updates
    public func startAccelerometer(interval: TimeInterval = 0.1, handler: @escaping (CMAccelerometerData?) -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = interval
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            handler(data)
        }
    }
    
    /// Stop accelerometer updates
    public func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }
    
    /// Start gyroscope updates
    public func startGyroscope(interval: TimeInterval = 0.1, handler: @escaping (CMGyroData?) -> Void) {
        guard motionManager.isGyroAvailable else { return }
        motionManager.gyroUpdateInterval = interval
        motionManager.startGyroUpdates(to: .main) { data, _ in
            handler(data)
        }
    }
    
    /// Stop gyroscope updates
    public func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }
}

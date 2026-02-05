import XCTest
@testable import MobileMotion

final class MobileMotionTests: XCTestCase {

    // MARK: - Version

    func testVersion() {
        XCTAssertFalse(MobileMotion.version.isEmpty)
    }

    // MARK: - Acceleration Data

    func testAccelerationDataMagnitude() {
        let data = AccelerationData(x: 3, y: 4, z: 0)
        XCTAssertEqual(data.magnitude, 5.0, accuracy: 0.001)
    }

    func testAccelerationDataZero() {
        let zero = AccelerationData.zero
        XCTAssertEqual(zero.x, 0)
        XCTAssertEqual(zero.y, 0)
        XCTAssertEqual(zero.z, 0)
    }

    // MARK: - Rotation Rate Data

    func testRotationRateDataMagnitude() {
        let data = RotationRateData(x: 1, y: 2, z: 2)
        XCTAssertEqual(data.magnitude, 3.0, accuracy: 0.001)
    }

    // MARK: - Magnetic Field Data

    func testMagneticFieldMagnitude() {
        let data = MagneticFieldData(x: 30, y: 40, z: 0)
        XCTAssertEqual(data.magnitude, 50.0, accuracy: 0.001)
    }

    // MARK: - Device Motion Data

    func testDeviceMotionDataZero() {
        let zero = DeviceMotionData.zero
        XCTAssertEqual(zero.attitude.pitch, 0)
        XCTAssertEqual(zero.gravity.magnitude, 0)
        XCTAssertEqual(zero.userAcceleration.magnitude, 0)
    }

    func testDeviceMotionVector3Magnitude() {
        let v = DeviceMotionData.Vector3(x: 1, y: 2, z: 2)
        XCTAssertEqual(v.magnitude, 3.0, accuracy: 0.001)
    }

    // MARK: - Activity Type

    func testActivityTypeSymbolNames() {
        for activity in ActivityType.allCases {
            XCTAssertFalse(activity.symbolName.isEmpty)
        }
    }

    func testActivitySnapshot() {
        let snapshot = ActivitySnapshot(activity: .walking, confidence: 2)
        XCTAssertTrue(snapshot.isHighConfidence)
        XCTAssertEqual(snapshot.activity, .walking)
    }

    // MARK: - Gesture Detector Config

    func testDefaultConfig() {
        let config = GestureDetectorConfig.default
        XCTAssertGreaterThan(config.shakeThreshold, 0)
        XCTAssertGreaterThan(config.impactThreshold, 0)
    }

    func testSensitiveConfig() {
        let sensitive = GestureDetectorConfig.sensitive
        let normal = GestureDetectorConfig.default
        XCTAssertLessThan(sensitive.shakeThreshold, normal.shakeThreshold)
    }

    // MARK: - Detected Gesture

    func testDetectedGesture() {
        let gesture = DetectedGesture(type: .shake, intensity: 1.5)
        XCTAssertEqual(gesture.type, .shake)
        XCTAssertEqual(gesture.intensity, 1.5)
    }

    func testMotionGestureTypes() {
        XCTAssertFalse(MotionGestureType.allCases.isEmpty)
        XCTAssertTrue(MotionGestureType.allCases.contains(.shake))
        XCTAssertTrue(MotionGestureType.allCases.contains(.faceDown))
    }

    // MARK: - Spring Animation

    func testSpringAnimationStep() {
        let spring = SpringAnimation(
            mass: 1.0,
            stiffness: 100.0,
            damping: 10.0
        )

        spring.currentValue = 0
        spring.targetValue = 100
        spring.velocity = 0
        spring.isAnimating = true

        // Step forward
        let value = spring.step(dt: 1.0 / 60.0)
        XCTAssertGreaterThan(value, 0, "Spring should move toward target")
        XCTAssertLessThan(value, 100, "Spring should not overshoot immediately")
    }

    func testSpringAnimationPresets() {
        let gentle = SpringAnimation.gentle
        let snappy = SpringAnimation.snappy
        let bouncy = SpringAnimation.bouncy
        let smooth = SpringAnimation.smooth

        XCTAssertLessThan(gentle.stiffness, snappy.stiffness)
        XCTAssertLessThan(bouncy.damping, smooth.damping)
    }

    func testSpringAnimationAtRest() {
        let spring = SpringAnimation()
        spring.currentValue = 100
        spring.targetValue = 100
        spring.velocity = 0

        XCTAssertTrue(spring.isAtRest())
    }

    // MARK: - Friction Animation

    func testFrictionDecelerates() {
        let friction = FrictionAnimation(friction: 0.05)
        friction.currentValue = 0
        friction.velocity = 100

        let _ = friction.step(dt: 1.0 / 60.0)
        XCTAssertLessThan(friction.velocity, 100, "Velocity should decrease")
    }

    func testFrictionPredictedRest() {
        let friction = FrictionAnimation(friction: 0.05)
        friction.currentValue = 0
        friction.velocity = 100

        let rest = friction.predictedRestPosition()
        XCTAssertGreaterThan(rest, 0, "Should predict forward movement")
    }

    // MARK: - Gravity Animation

    func testGravityAccelerates() {
        let gravity = GravityAnimation(gravity: 980, floorY: 1000)
        gravity.currentValue = 0
        gravity.velocity = 0
        gravity.isAnimating = true

        let _ = gravity.step(dt: 1.0 / 60.0)
        XCTAssertGreaterThan(gravity.velocity, 0, "Should accelerate downward")
        XCTAssertGreaterThan(gravity.currentValue, 0, "Should move downward")
    }

    func testGravityBounce() {
        let gravity = GravityAnimation(gravity: 980, restitution: 0.5, floorY: 100)
        gravity.currentValue = 99
        gravity.velocity = 500
        gravity.isAnimating = true

        let _ = gravity.step(dt: 1.0 / 60.0)
        // After hitting floor, velocity should reverse and reduce
        XCTAssertEqual(gravity.bounceCount, 1)
    }

    // MARK: - Spring Parameters

    func testSpringParametersDampingRatio() {
        let params = SpringParameters.default
        XCTAssertGreaterThan(params.dampingRatio, 0)

        let smooth = SpringParameters.smooth
        XCTAssertEqual(smooth.dampingRatio, 1.0, accuracy: 0.01)
    }

    func testSpringParametersFrequency() {
        let params = SpringParameters(stiffness: 400, mass: 1)
        XCTAssertEqual(params.naturalFrequency, 20, accuracy: 0.001)
    }

    // MARK: - Motion Manager

    func testMotionManagerCreation() {
        let manager = MotionManager()
        XCTAssertNotNil(manager.coreMotionManager)
    }
}

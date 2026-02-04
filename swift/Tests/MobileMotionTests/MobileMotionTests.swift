import XCTest
@testable import MobileMotion

final class MobileMotionTests: XCTestCase {
    
    // MARK: - Animation Tests
    
    func testSpringAnimationConfiguration() {
        let spring = SpringAnimation(
            mass: 1.0,
            stiffness: 100.0,
            damping: 10.0
        )
        
        XCTAssertEqual(spring.mass, 1.0)
        XCTAssertEqual(spring.stiffness, 100.0)
        XCTAssertEqual(spring.damping, 10.0)
    }
    
    func testAnimationDuration() {
        let animation = Animation.easeInOut(duration: 0.5)
        XCTAssertEqual(animation.duration, 0.5)
    }
    
    func testAnimationTimingCurve() {
        let linear = TimingCurve.linear
        let easeIn = TimingCurve.easeIn
        let easeOut = TimingCurve.easeOut
        
        XCTAssertNotNil(linear)
        XCTAssertNotNil(easeIn)
        XCTAssertNotNil(easeOut)
    }
    
    // MARK: - Physics Tests
    
    func testGravitySimulation() {
        let gravity = GravitySimulation(acceleration: 9.8)
        let position = gravity.positionAt(time: 1.0)
        
        XCTAssertGreaterThan(position, 0)
    }
    
    func testFrictionSimulation() {
        let friction = FrictionSimulation(coefficient: 0.5)
        let velocity = friction.velocityAt(initialVelocity: 100, time: 1.0)
        
        XCTAssertLessThan(velocity, 100)
    }
    
    // MARK: - Gesture Tests
    
    func testDragGestureVelocity() {
        let drag = DragGesture()
        drag.updateVelocity(dx: 100, dy: 50)
        
        XCTAssertEqual(drag.velocity.dx, 100)
        XCTAssertEqual(drag.velocity.dy, 50)
    }
}

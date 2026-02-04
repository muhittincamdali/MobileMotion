import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_motion/mobile_motion.dart';

void main() {
  group('SpringAnimation', () {
    test('creates with default parameters', () {
      final spring = SpringAnimation();
      
      expect(spring.mass, 1.0);
      expect(spring.stiffness, 100.0);
      expect(spring.damping, 10.0);
    });

    test('calculates spring force correctly', () {
      final spring = SpringAnimation(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );
      
      final force = spring.forceAt(displacement: 1.0, velocity: 0.0);
      expect(force, -100.0);
    });
  });

  group('PhysicsSimulation', () {
    test('gravity simulation applies correct acceleration', () {
      final gravity = GravitySimulation(acceleration: 9.8);
      final position = gravity.positionAt(time: 1.0);
      
      expect(position, greaterThan(0));
    });

    test('friction reduces velocity over time', () {
      final friction = FrictionSimulation(coefficient: 0.5);
      final v1 = friction.velocityAt(initialVelocity: 100, time: 0.5);
      final v2 = friction.velocityAt(initialVelocity: 100, time: 1.0);
      
      expect(v2, lessThan(v1));
    });
  });

  group('TimingCurve', () {
    test('linear curve returns identity', () {
      final linear = TimingCurve.linear;
      expect(linear.transform(0.5), 0.5);
    });

    test('ease curves are bounded', () {
      final easeIn = TimingCurve.easeIn;
      
      expect(easeIn.transform(0.0), 0.0);
      expect(easeIn.transform(1.0), 1.0);
    });
  });
}

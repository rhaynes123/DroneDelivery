import Testing
import simd
@testable import DroneDelivery

@Suite struct KinematicMathTests {
    @Test func stepVelocityMovesTowardTarget() {
        let result = KinematicMath.stepVelocity(
            current: SIMD3(0, 0, 0),
            target: SIMD3(10, 0, 0),
            lerp: 0.5
        )
        #expect(result.x == 5)
    }

    @Test func stepVelocityHonorsLerpZero() {
        let result = KinematicMath.stepVelocity(
            current: SIMD3(3, 0, 0),
            target: SIMD3(10, 0, 0),
            lerp: 0
        )
        #expect(result == SIMD3(3, 0, 0))
    }

    @Test func drainIncreasesWithSpeed() {
        let still = KinematicMath.drainW(speedMS: 0, windKts: 0)
        let fast = KinematicMath.drainW(speedMS: 10, windKts: 0)
        #expect(fast > still)
    }

    @Test func drainIncreasesWithWind() {
        let calm = KinematicMath.drainW(speedMS: 5, windKts: 0)
        let windy = KinematicMath.drainW(speedMS: 5, windKts: 15)
        #expect(windy > calm)
    }
}

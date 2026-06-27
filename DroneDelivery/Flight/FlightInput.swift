import Foundation
import Observation
import simd

@Observable
public final class FlightInput {
    public var leftStick: SIMD2<Float> = .zero    // x = strafe, y = forward
    public var rightStick: SIMD2<Float> = .zero   // x = yaw, y = altitude

    public init() {}

    /// Map stick input to a target velocity in scene space.
    public func targetVelocity(maxSpeed: Float) -> SIMD3<Float> {
        let horizontal = SIMD3<Float>(leftStick.x, rightStick.y, -leftStick.y) * maxSpeed
        return horizontal
    }
}

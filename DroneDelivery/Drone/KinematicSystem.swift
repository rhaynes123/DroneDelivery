import RealityKit
import simd

public enum KinematicMath {
    public static func stepVelocity(current: SIMD3<Float>,
                                    target: SIMD3<Float>,
                                    lerp: Float) -> SIMD3<Float> {
        current + (target - current) * lerp
    }

    public static func drainW(speedMS: Float, windKts: Float) -> Double {
        PhysicsTuning.baseDrainW
            + Double(speedMS) * PhysicsTuning.perMSDrainW
            + Double(abs(windKts)) * PhysicsTuning.perKtWindFightDrainW
    }
}

public final class KinematicSystem: System {
    private static let droneQuery = EntityQuery(where: .has(KinematicComponent.self))
    private static let windQuery = EntityQuery(where: .has(WindComponent.self))

    public required init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)

        let wind: SIMD3<Float> = context.scene
            .performQuery(Self.windQuery)
            .compactMap { $0.components[WindComponent.self]?.vector }
            .first ?? .zero

        context.scene.performQuery(Self.droneQuery).forEach { entity in
            guard var kin = entity.components[KinematicComponent.self] else { return }

            // Velocity smoothing toward target.
            kin.velocity = KinematicMath.stepVelocity(
                current: kin.velocity,
                target: kin.targetVelocity,
                lerp: PhysicsTuning.velocityLerp
            )

            // Clamp to max speed.
            let speed = simd_length(kin.velocity)
            if speed > kin.maxSpeed {
                kin.velocity = (kin.velocity / speed) * kin.maxSpeed
            }

            // Integrate position, adding the wind transfer.
            let effective = kin.velocity + wind * PhysicsTuning.windCoupling
            entity.position += effective * dt

            entity.components.set(kin)

            // Altimeter (flat ground = y=0 in scene space).
            if var alt = entity.components[AltimeterComponent.self] {
                alt.aglFt = entity.position.y * PhysicsTuning.metresToFeet
                entity.components.set(alt)
            }

            // Battery drain.
            if var bat = entity.components[BatteryComponent.self] {
                let speedMS = simd_length(kin.velocity)
                let windKts = simd_length(wind) / PhysicsTuning.knotsToMS
                let drain = KinematicMath.drainW(speedMS: speedMS, windKts: windKts)
                bat.remainingWh = max(0, bat.remainingWh - drain * Double(dt) / 3600.0)
                entity.components.set(bat)
            }
        }
    }
}

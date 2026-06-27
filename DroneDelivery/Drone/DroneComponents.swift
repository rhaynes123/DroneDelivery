import RealityKit
import simd

public struct KinematicComponent: Component {
    public var velocity: SIMD3<Float>
    public var targetVelocity: SIMD3<Float>
    public var maxSpeed: Float
    public init(velocity: SIMD3<Float> = .zero,
                targetVelocity: SIMD3<Float> = .zero,
                maxSpeed: Float = PhysicsTuning.maxSpeedMS) {
        self.velocity = velocity
        self.targetVelocity = targetVelocity
        self.maxSpeed = maxSpeed
    }
}

public struct BatteryComponent: Component {
    public var remainingWh: Double
    public let capacityWh: Double
    public init(capacityWh: Double) {
        self.capacityWh = capacityWh
        self.remainingWh = capacityWh
    }
}

public struct AltimeterComponent: Component {
    public var aglFt: Float = 0
    public init() {}
}

public struct WindComponent: Component {
    public var vector: SIMD3<Float>
    public init(vector: SIMD3<Float> = .zero) { self.vector = vector }
}

public struct CargoComponent: Component {
    public let kind: CargoKind
    public var delivered: Bool
    public init(kind: CargoKind, delivered: Bool = false) {
        self.kind = kind
        self.delivered = delivered
    }
}

public enum DroneComponents {
    public static func registerAll() {
        KinematicComponent.registerComponent()
        BatteryComponent.registerComponent()
        AltimeterComponent.registerComponent()
        WindComponent.registerComponent()
        CargoComponent.registerComponent()
    }
}

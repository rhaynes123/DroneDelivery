import Foundation

/// Centralised tuning constants. Every value is a knob — real drones, wind,
/// and batteries need calibration that a minimal model can't see.
public enum PhysicsTuning {

    // CFR § 107.51(b): max altitude 400 ft AGL unless within 400 ft of a structure.
    public static let maxAltitudeAGLFt: Float = 400

    // Arcade drone top speed in m/s (~22 kts). DJI Mavic 3 is ~21 m/s in Sport mode.
    // ponytail: per-mission limits could override this; add a per-mission cap if missions need it.
    public static let maxSpeedMS: Float = 11

    // Velocity smoothing: fraction of (target - current) applied per frame at 60 fps.
    // 0.18 ≈ ~150 ms time-to-target, feels responsive but not twitchy.
    public static let velocityLerp: Float = 0.18

    // Wind transfer: how much of the wind vector adds to drone velocity.
    // ponytail: real coupling depends on attitude + mass; 0.6 is a one-knob approximation.
    public static let windCoupling: Float = 0.6

    // Battery drain in watts.
    // 80 Wh battery on a 200 W base draw = ~24 minutes hover. Real DJI Mavic 3: ~46 min.
    // Tighter on purpose: missions need to feel battery-constrained.
    public static let baseDrainW: Double = 200
    public static let perMSDrainW: Double = 12    // additional W per m/s of speed
    public static let perKtWindFightDrainW: Double = 6  // additional W per kt of wind being fought

    // Default battery if a mission doesn't specify (used by tests / previews).
    public static let defaultBatteryWh: Double = 80

    // Conversion: 1 m = 3.28084 ft.
    public static let metresToFeet: Float = 3.28084
    public static let knotsToMS: Float = 0.514444
}

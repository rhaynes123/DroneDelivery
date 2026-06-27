import Foundation
import simd

public enum AirspaceClass: String, Codable, Sendable {
    case b, c, d, e, g
}

public struct AirspaceZone: Codable, Identifiable, Sendable {
    public let id: String
    public let polygonName: String
    public let `class`: AirspaceClass
    public let polygon: [SIMD2<Float>]
    public let floorAGL: Float
    public let ceilingAGL: Float
    public let requiresAuthorization: Bool

    // Ray-casting point-in-polygon. Works for any simple polygon (no holes).
    public func contains(_ p: SIMD2<Float>) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let pi = polygon[i], pj = polygon[j]
            let intersects = ((pi.y > p.y) != (pj.y > p.y)) &&
                (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }
}

public struct NOTAM: Codable, Identifiable, Sendable {
    public let id: String
    public let reason: String
    public let polygon: [SIMD2<Float>]
    public let floorAGL: Float
    public let ceilingAGL: Float
    public let start: Date
    public let end: Date

    public func contains(_ p: SIMD2<Float>) -> Bool {
        // ponytail: shares polygon math with AirspaceZone; extract a free
        // function if a third polygon owner appears.
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let pi = polygon[i], pj = polygon[j]
            let intersects = ((pi.y > p.y) != (pj.y > p.y)) &&
                (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }
}

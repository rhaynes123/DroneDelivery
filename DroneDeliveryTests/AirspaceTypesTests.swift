import Testing
import simd
@testable import DroneDelivery

@Suite struct AirspaceTypesTests {
    @Test func zoneContainsPointInside() {
        let zone = AirspaceZone(
            id: "Z1", polygonName: "test", class: .g,
            polygon: [SIMD2(0,0), SIMD2(10,0), SIMD2(10,10), SIMD2(0,10)],
            floorAGL: 0, ceilingAGL: 400, requiresAuthorization: false
        )
        #expect(zone.contains(SIMD2(5, 5)))
    }

    @Test func zoneExcludesPointOutside() {
        let zone = AirspaceZone(
            id: "Z1", polygonName: "test", class: .g,
            polygon: [SIMD2(0,0), SIMD2(10,0), SIMD2(10,10), SIMD2(0,10)],
            floorAGL: 0, ceilingAGL: 400, requiresAuthorization: false
        )
        #expect(!zone.contains(SIMD2(15, 5)))
    }
}

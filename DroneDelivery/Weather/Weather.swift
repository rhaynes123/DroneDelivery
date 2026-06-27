import Foundation

public struct WeatherSpec: Codable, Sendable {
    public let windKts: Float
    public let windDir: Float        // degrees true
    public let visibilitySM: Float
    public let ceilingFtAGL: Float
    public let temperatureC: Float
    public let densityAltitudeFt: Float
}

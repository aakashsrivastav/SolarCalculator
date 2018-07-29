import Foundation

// Type aliases
public typealias AzimuthCoordinate = (azimuth: Double, altitude: Double)
public typealias EclipticCoordinate = (rightAscension: Double, declination: Double)
public typealias MoonPosition = (azimuth: Double, altitude: Double, distance: Double, parallacticAngle: Double)
public typealias MoonCoordinate = (rightAscension: Double, declination: Double, distance: Double)
public typealias MoonIllumination = (fraction: Double, phase: Double, angle: Double)

// Solar Events
public enum SolarEvent {
    case sunrise
    case sunset
    case sunriseEnd
    case sunsetEnd
    case dawn
    case dusk
    case nauticalDawn
    case nauticalDusk
    case astronomicalDawn
    case astronomicalDusk
    case goldenHourEnd
    case goldenHour
    case noon
    case nadir

    var solarAngle: Double {
        switch self {
        case .sunrise, .sunset: return -0.833
        case .sunriseEnd, .sunsetEnd: return -0.3
        case .dawn, .dusk: return -6.0
        case .nauticalDawn, .nauticalDusk: return -12.0
        case .astronomicalDawn, .astronomicalDusk: return -18.0
        case .goldenHourEnd, .goldenHour: return 6.0
        case .noon: return 90.0 // Just for reference
        case .nadir: return -90.0 // Just for reference
        }
    }
}

// Main implementation
public class SunCalc {

    // Location Structure
    public struct Location {
        var latitude: Double
        var longitude: Double
    }

    // Errors
    public enum SolarEventError: Error {
        case sunNeverRise
        case sunNeverSet
    }

    public enum LunarEventError: Error {
        case moonNeverRise(Date?)
        case moonNeverSet(Date?)
    }

    private static let e = 23.4397 * Double.radPerDegree

    private func rightAscension(l: Double, b: Double) -> Double {
        return atan2(sin(l) * cos(SunCalc.e) - tan(b) * sin(SunCalc.e), cos(l))
    }

    private func declination(l: Double, b: Double) -> Double {
        return asin(sin(b) * cos(SunCalc.e) + cos(b) * sin(SunCalc.e) * sin(l))
    }

    private func azimuth(h: Double, phi: Double, dec: Double) -> Double {
        return atan2(sin(h), cos(h) * sin(phi) - tan(dec) * cos(phi))
    }

    private func altitude(h: Double, phi: Double, dec: Double) -> Double {
        return asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(h))
    }

    private func siderealTime(d: Double, lw: Double) -> Double {
        return Double.radPerDegree * (280.16 + 360.9856235 * d) - lw
    }

    private func astroRefraction(_ aH: Double) -> Double {
        let h = aH < 0 ? 0 : aH
        return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179))
    }

    private func solarMeanAnomaly(_ d: Double) -> Double {
        return Double.radPerDegree * (357.5291 + 0.98560028 * d)
    }

    private func eclipticLongitude(_ m: Double) -> Double {
        let c = Double.radPerDegree * (1.9148 * sin(m) + 0.02 * sin(2.0 * m) + 0.0003 * sin(3.0 * m))
        let p = Double.radPerDegree * 102.9372
        return m + c + p + Double.pi
    }

    private func sunCoordinates(_ d: Double) -> EclipticCoordinate {
        let m = solarMeanAnomaly(d)
        let l = eclipticLongitude(m)
        return (rightAscension(l: l, b: 0.0), declination(l: l, b: 0.0))
    }

    private func julianCycle(d: Double, lw: Double) -> Double {
        let v = (d - Date.j0) - (lw / (2.0 * Double.pi))
        return v.rounded()
    }

    private func approximateTransit(hT: Double, lw: Double, n: Double) -> Double {
        return Date.j0 + (hT + lw) / (2.0 * Double.pi) + n
    }

    private func solarTransitJ(ds: Double, m: Double, l: Double) -> Double {
        return Date.j2000 + ds + 0.0053 * sin(m) - 0.0069 * sin(2.0 * l)
    }

    private func hourAngle(h: Double, phi: Double, d: Double) throws -> Double {
        let cosH = (sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))
        if cosH > 1 {
            throw SolarEventError.sunNeverRise
        }
        if cosH < -1 {
            throw SolarEventError.sunNeverSet
        }
        //print(cosH)
        return acos(cosH)
    }

    private func getSetJ(h: Double, lw: Double, phi: Double, dec: Double, n: Double, m: Double, l:Double) throws -> Double {
        let w = try hourAngle(h: h, phi: phi, d: dec)
        let a = approximateTransit(hT: w, lw: lw, n: n)
        return solarTransitJ(ds: a, m: m, l: l)
    }

    private func moonCoordinates(_ d: Double) -> MoonCoordinate {
        let l = Double.radPerDegree * (218.316 + 13.176396 * d)
        let m = Double.radPerDegree * (134.963 + 13.064993 * d)
        let f = Double.radPerDegree * (93.272 + 13.229350 * d)
        let altL = l + Double.radPerDegree * 6.289 * sin(m)
        let b = Double.radPerDegree * 5.128 * sin(f)
        let dt = 385001.0 - 20905.0 * cos(m)
        return (rightAscension(l: altL, b: b), declination(l: altL, b: b), dt)
    }

    public func sunPosition(date: Date, location: Location) -> AzimuthCoordinate {
        let lw = Double.radPerDegree * location.longitude * -1.0
        let phi = Double.radPerDegree * location.latitude
        let d = date.daysSince2000
        let c = sunCoordinates(d)
        let h = siderealTime(d: d, lw: lw) - c.rightAscension

        return (azimuth(h: h, phi: phi, dec: c.declination), altitude(h: h, phi: phi, dec: c.declination))
    }

    public func moonPosition(date: Date, location: Location) -> MoonPosition {
        let lw = Double.radPerDegree * location.longitude * -1.0
        let phi = Double.radPerDegree * location.latitude
        let d = date.daysSince2000
        let c = moonCoordinates(d)
        let h = siderealTime(d: d, lw: lw) - c.rightAscension
        var h1 = altitude(h: h, phi: phi, dec: c.declination)
        let pa = atan2(sin(h), tan(phi) * cos(c.declination) - sin(c.declination) * cos(h))
        h1 += astroRefraction(h1)

        return (azimuth(h: h, phi: phi, dec: c.declination), h1, c.distance, pa)
    }

    public func moonIllumination(date: Date = Date()) -> MoonIllumination {
        let d = date.daysSince2000
        let s = sunCoordinates(d)
        let m = moonCoordinates(d)
        let sDist = 149598000.0 // Distance from earth to sun
        let phi = acos(sin(s.declination) * sin(m.declination) + cos(s.declination) * cos(m.declination) * cos(s.rightAscension - m.rightAscension))
        let inc = atan2(sDist * sin(phi), m.distance - sDist * cos(phi))
        let angle = atan2(cos(s.declination) * sin(s.rightAscension - m.rightAscension), sin(s.declination) * cos(m.declination) - cos(s.declination) * sin(m.declination) * cos(s.rightAscension - m.rightAscension))
        return ((1.0 + cos(inc)) / 2.0, 0.5 + 0.5 * inc * (angle < 0.0 ? -1.0 : 1.0) / Double.pi, angle)
    }

    public func time(ofDate date: Date, forSolarEvent event: SolarEvent, atLocation location: Location) throws -> Date {
        let lw = Double.radPerDegree * location.longitude * -1.0
        let phi = Double.radPerDegree * location.latitude
        let d = date.daysSince2000
        let n = julianCycle(d: d, lw: lw)
        let ds = approximateTransit(hT: 0.0, lw: lw, n: n)
        let m = solarMeanAnomaly(ds)
        let l = eclipticLongitude(m)
        let dec = declination(l: l, b: 0.0)
        let jNoon = solarTransitJ(ds: ds, m: m, l: l)
        let noon = Date(julianDays: jNoon)

        let angle = event.solarAngle
        let jSet = try getSetJ(h: angle * Double.radPerDegree, lw: lw, phi: phi, dec: dec, n: n, m: m, l: l)

        switch event {
        case .noon: return noon
        case .nadir:
            let nadir = Date(julianDays: jNoon - 0.5)
            return nadir
        case .sunset, .dusk, .goldenHour, .astronomicalDusk, .nauticalDusk:
            return Date(julianDays: jSet)
        case .sunrise, .dawn, .goldenHourEnd, .astronomicalDawn, .nauticalDawn:
            let jRise = jNoon - (jSet - jNoon)
            return Date(julianDays: jRise)
        default:
            return Date()
        }
    }

    public func moonTimes(date: Date, location: Location) throws -> (moonRiseTime: Date, moonSetTime: Date) {
        let date = date.beginning()
        let hc = 0.133 * Double.radPerDegree
        var h0 = moonPosition(date: date, location: location).altitude - hc

        var riseHour: Double?
        var setHour: Double?
        var ye: Double = 0.0

        for i in 1...24 {
            if i % 2 == 0 { continue }
            let h1 = moonPosition(date: date.hoursLater(Double(i)), location: location).altitude - hc
            let h2 = moonPosition(date: date.hoursLater(Double(i) + 1.0), location: location).altitude - hc
            let a = (h0 + h2) / 2.0 - h1
            let b = (h2 - h0) / 2.0
            let xe = -b / (2.0 * a)
            ye = (a * xe + b) * xe + h1
            let d = b * b - 4.0 * a * h1

            if d >= 0 {
                let dx = sqrt(d) / (fabs(a) * 2.0)
                var roots = 0
                var x1 = xe - dx
                let x2 = xe + dx
                if fabs(x1) < 1.0 { roots += 1 }
                if fabs(x2) < 1.0 { roots += 1 }
                if x1 < -1.0 { x1 = x2 }

                if roots == 1 {
                    if h0 < 0.0 {
                        riseHour = Double(i) + x1
                    }
                    else {
                        setHour = Double(i) + x1
                    }
                }
                else if roots == 2 {
                    riseHour = Double(i) + (ye < 0 ? x2 : x1)
                    setHour = Double(i) + (ye < 0 ? x1 : x2)
                }

                if riseHour != nil && setHour != nil {
                    break
                }
            }

            h0 = h2
        }

        if let riseHour = riseHour, let setHour = setHour {
            return (moonRiseTime: date.hoursLater(riseHour), moonSetTime: date.hoursLater(setHour))
        }
        else {
            if ye > 0 {
                let rise = (riseHour == nil) ? nil : date.hoursLater(riseHour!)
                throw LunarEventError.moonNeverSet(rise)
            }
            else {
                let set = (setHour == nil) ? nil : date.hoursLater(setHour!)
                throw LunarEventError.moonNeverRise(set)
            }
        }
    }
}


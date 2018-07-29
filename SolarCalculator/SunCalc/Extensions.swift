import Foundation

extension Double {
    static let radPerDegree = Double.pi / 180.0
}

extension Date {
    static let j0: Double = 0.0009
    static let j1970: Double = 2440588.0
    static let j2000: Double = 2451545.0
    static let secondsPerDay: Double = 86400.0

    init(julianDays days: Double) {
        let timeInterval = (days + 0.5 - Date.j1970) * Date.secondsPerDay
        self.init(timeIntervalSince1970: timeInterval)
    }

    var julianDays: Double {
        return timeIntervalSince1970 / Date.secondsPerDay - 0.5 + Date.j1970
    }

    var daysSince2000: Double {
        return julianDays - Date.j2000
    }

    func hoursLater(_ h: Double) -> Date {
        return addingTimeInterval(h * 3600.0)
    }

    // Beginning time of a day, aka. 0:00 or midnight in GMT.
    func beginning() -> Date {
        let calender = Calendar.init(identifier: .gregorian)
        var comp = calender.dateComponents(in: TimeZone(identifier: "GMT")!, from: self)
        comp.hour = 0
        comp.minute = 0
        comp.second = 0
        return calender.date(from: comp)!
    }
}

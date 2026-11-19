import Foundation

enum BusDirection: String, CaseIterable {
    case toStation = "to_station"
    case toUniv = "to_univ"

    var shortTitle: String {
        switch self {
        case .toStation:
            return "大学 → 姫路駅"
        case .toUniv:
            return "姫路駅 → 大学"
        }
    }

    var fromStopName: String {
        switch self {
        case .toStation:
            return "県立大工学部"
        case .toUniv:
            return "姫路駅(北口)"
        }
    }

    var toStopName: String {
        switch self {
        case .toStation:
            return "姫路駅(北口)"
        case .toUniv:
            return "県立大工学部"
        }
    }

    var fromStopCode: String {
        switch self {
        case .toStation:
            return "20240"
        case .toUniv:
            return "20000"
        }
    }

    var toStopCode: String {
        switch self {
        case .toStation:
            return "20000"
        case .toUniv:
            return "20240"
        }
    }

    var officialFromStopName: String {
        switch self {
        case .toStation:
            return "県立大工学部"
        case .toUniv:
            return "姫路駅（北口）"
        }
    }

    var officialToStopName: String {
        switch self {
        case .toStation:
            return "姫路駅（北口）"
        case .toUniv:
            return "県立大工学部"
        }
    }

    var toggled: BusDirection {
        self == .toStation ? .toUniv : .toStation
    }
}

enum DayTypeMode: String, CaseIterable {
    case auto
    case weekday
    case weekend

    var next: DayTypeMode {
        switch self {
        case .auto:
            return .weekday
        case .weekday:
            return .weekend
        case .weekend:
            return .auto
        }
    }

    var modeBadge: String {
        switch self {
        case .auto:
            return "自動"
        case .weekday:
            return "平日固定"
        case .weekend:
            return "土日祝固定"
        }
    }
}

enum ResolvedDayType: String {
    case weekday
    case weekend

    var shortLabel: String {
        self == .weekday ? "平日" : "土日祝"
    }
}

struct StopPoint: Hashable {
    let name: String
    let offsetMin: Int
}

struct TimetableEntry: Hashable {
    let time: String
    let arrivalTime: String
    let scheduledMinutes: Int
    let arrivalMinutes: Int
    let routeNo: String
    let destination: String
    let origin: String
    let rideMinutes: Int
    let note: String

    var routeLabel: String {
        routeNo == "直行" ? "直行" : "\(routeNo)系統"
    }

    var shortDestination: String {
        if let range = destination.range(of: "（") {
            let trimmed = String(destination[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return destination
    }
}

struct LiveBusInfo {
    let depTime: String
    let statusText: String
    let delayMinutes: Int
    let isRunning: Bool
    let gpsStationCode: String?
    let gpsStationName: String?
}

struct BusPositionSummary: Equatable {
    let headline: String
    let detail: String
    let progress: Double
    let isGPS: Bool
}

enum BusState: String {
    case upcoming
    case inTransit = "in_transit"
    case tomorrow
}

struct BusItem: Identifiable, Equatable {
    let id: String
    let state: BusState
    let routeNo: String
    let routeLabel: String
    let shortDestination: String
    let origin: String
    let scheduledTime: String
    let expectedTime: String
    let expectedArrivalTime: String
    let minutesUntilDeparture: Int
    let minutesUntilArrival: Int
    let delayMinutes: Int
    let note: String
    let location: BusPositionSummary
}

struct BusStatusSnapshot {
    let updatedAt: String
    let dayType: ResolvedDayType
    let isLiveConnected: Bool
    let isTomorrow: Bool
    let inTransitBuses: [BusItem]
    let upcomingBuses: [BusItem]
}

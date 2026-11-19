import Foundation
import SwiftUI

private enum JSTClock {
    static let timeZone: TimeZone = TimeZone(identifier: "Asia/Tokyo") ?? TimeZone(secondsFromGMT: 9 * 3600)!

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }
}

final class ShinkiNaviLiveClient {
    private static let baseURL = "https://navi.shinkibus.jp"
    private static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    func fetchLive(direction: BusDirection, now: Date = Date()) async -> (ok: Bool, items: [String: LiveBusInfo]) {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage()
        config.timeoutIntervalForRequest = 4.5
        config.timeoutIntervalForResource = 8.0

        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }

        do {
            guard let topURL = URL(string: "\(Self.baseURL)/") else {
                return (false, [:])
            }
            var topReq = URLRequest(url: topURL)
            topReq.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

            let (topData, _) = try await session.data(for: topReq)
            let topHTML = String(data: topData, encoding: .utf8) ?? ""
            guard let csrfToken = extractCSRFToken(from: topHTML), !csrfToken.isEmpty else {
                return (false, [:])
            }

            let queryDate = now.addingTimeInterval(-18 * 60)
            let comps = JSTClock.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: queryDate)

            let formPairs: [(String, String)] = [
                ("csrfmiddlewaretoken", csrfToken),
                ("from_busstop", direction.fromStopCode),
                ("from_busstop_name", direction.officialFromStopName),
                ("que_start_text", direction.officialFromStopName),
                ("to_busstop", direction.toStopCode),
                ("to_busstop_name", direction.officialToStopName),
                ("que_end_text", direction.officialToStopName),
                ("genjikoku_isset", "not"),
                ("date_year", String(comps.year ?? 2026)),
                ("date_month", String(comps.month ?? 1)),
                ("date_day", String(comps.day ?? 1)),
                ("date_hour", String(comps.hour ?? 0)),
                ("date_minute", String(comps.minute ?? 0)),
                ("this_time_is", "start")
            ]

            guard let unkohURL = URL(string: "\(Self.baseURL)/unkoh/") else {
                return (false, [:])
            }
            var unkohReq = URLRequest(url: unkohURL)
            unkohReq.httpMethod = "POST"
            unkohReq.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
            unkohReq.setValue("\(Self.baseURL)/", forHTTPHeaderField: "Referer")
            unkohReq.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            unkohReq.httpBody = formEncode(formPairs).data(using: .utf8)

            let (unkohData, _) = try await session.data(for: unkohReq)
            let unkohHTML = String(data: unkohData, encoding: .utf8) ?? ""

            var liveByTime: [String: LiveBusInfo] = [:]
            var proxyParams: [(hhmm: String, x: String, y: String, z: String, t: String, u: String)] = []

            for cardHTML in extractResultCards(from: unkohHTML) {
                let depRaw = extractTagText(in: cardHTML, classKeyword: "res_hatsu")
                guard let hhmm = extractNormalizedHHMM(from: depRaw) else {
                    continue
                }

                let statusRaw = extractTagText(in: cardHTML, classKeyword: "info_unkou")
                let statusText = statusRaw.isEmpty ? "定刻運行" : statusRaw

                var delayMin = 0
                if let matchStr = firstCapture(in: statusText, pattern: #"(\d+)\s*分遅れ"#),
                   let parsed = Int(matchStr) {
                    delayMin = parsed
                } else if statusText.contains("少し遅れ") {
                    delayMin = 1
                }

                if let stepwellToken = firstCapture(in: cardHTML, pattern: #"(stepwell_[^"'\s>]+)"#) {
                    let parts = stepwellToken.split(separator: "_", omittingEmptySubsequences: false).map(String.init)
                    if parts.count >= 6 && parts[0] == "stepwell" {
                        proxyParams.append((hhmm, parts[1], parts[2], parts[3], parts[4], parts[5]))
                    }
                }

                liveByTime[hhmm] = LiveBusInfo(
                    depTime: hhmm,
                    statusText: statusText,
                    delayMinutes: delayMin,
                    isRunning: !statusText.contains("運行前"),
                    gpsStationCode: nil,
                    gpsStationName: nil
                )
            }

            if !proxyParams.isEmpty {
                let xs = proxyParams.map(\.x).joined(separator: ",")
                let ys = proxyParams.map(\.y).joined(separator: ",")
                let zs = proxyParams.map(\.z).joined(separator: ",")
                let ts = proxyParams.map(\.t).joined(separator: ",")
                let us = proxyParams.map(\.u).joined(separator: ",")

                var components = URLComponents(string: "\(Self.baseURL)/bus_proxy/")
                components?.queryItems = [
                    URLQueryItem(name: "x", value: xs),
                    URLQueryItem(name: "y", value: ys),
                    URLQueryItem(name: "z", value: zs),
                    URLQueryItem(name: "t", value: ts),
                    URLQueryItem(name: "u", value: us)
                ]

                if let proxyURL = components?.url {
                    var proxyReq = URLRequest(url: proxyURL)
                    proxyReq.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
                    proxyReq.setValue("\(Self.baseURL)/unkoh/", forHTTPHeaderField: "Referer")

                    let (proxyData, _) = try await session.data(for: proxyReq)
                    if let proxyArray = try JSONSerialization.jsonObject(with: proxyData) as? [[String: Any]] {
                        for (idx, item) in proxyArray.enumerated() {
                            guard idx < proxyParams.count else { break }
                            let hhmm = proxyParams[idx].hhmm
                            guard let existing = liveByTime[hhmm] else { continue }

                            let unkyu = stringValue(item["unkyu_info"]) ?? ""
                            let delayVal = intValue(item["delay_time"]) ?? 0
                            let lastCd = stringValue(item["last_station_cd"]) ?? ""
                            let gpsName = lastCd.isEmpty ? nil : TimetableData.stationCodeMap[lastCd]

                            liveByTime[hhmm] = LiveBusInfo(
                                depTime: existing.depTime,
                                statusText: existing.statusText,
                                delayMinutes: max(existing.delayMinutes, delayVal),
                                isRunning: unkyu == "運行",
                                gpsStationCode: lastCd.isEmpty ? nil : lastCd,
                                gpsStationName: gpsName
                            )
                        }
                    }
                }
            }

            return (!liveByTime.isEmpty, liveByTime)
        } catch {
            return (false, [:])
        }
    }

    private func formEncode(_ pairs: [(String, String)]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return pairs.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
    }

    private func extractCSRFToken(from html: String) -> String? {
        let patterns = [
            #"<input[^>]*name=["']csrfmiddlewaretoken["'][^>]*value=["']([^"']+)["']"#,
            #"<input[^>]*value=["']([^"']+)["'][^>]*name=["']csrfmiddlewaretoken["']"#
        ]
        for pattern in patterns {
            if let token = firstCapture(in: html, pattern: pattern) {
                return token
            }
        }
        return nil
    }

    private func extractResultCards(from html: String) -> [String] {
        guard let startRegex = try? NSRegularExpression(
            pattern: #"<div\b[^>]*\bclass=["'][^"']*\bkensaku_result\b[^"']*["'][^>]*>"#,
            options: [.caseInsensitive]
        ),
        let divTokenRegex = try? NSRegularExpression(
            pattern: #"<div\b|</div>"#,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let nsHTML = html as NSString
        let fullRange = NSRange(location: 0, length: nsHTML.length)
        let startMatches = startRegex.matches(in: html, range: fullRange)
        var cards: [String] = []

        for match in startMatches {
            let cardStart = match.range.location
            let scanStart = match.range.location + match.range.length
            var depth = 1
            var cardEnd = nsHTML.length

            let scanRange = NSRange(location: scanStart, length: nsHTML.length - scanStart)
            divTokenRegex.enumerateMatches(in: html, range: scanRange) { tokenMatch, _, stop in
                guard let tokenMatch = tokenMatch else { return }
                let token = nsHTML.substring(with: tokenMatch.range).lowercased()
                if token.hasPrefix("</div") {
                    depth -= 1
                } else {
                    depth += 1
                }
                if depth <= 0 {
                    cardEnd = tokenMatch.range.location + tokenMatch.range.length
                    stop.pointee = true
                }
            }

            let cardRange = NSRange(location: cardStart, length: max(0, cardEnd - cardStart))
            cards.append(nsHTML.substring(with: cardRange))
        }

        return cards
    }

    private func extractTagText(in html: String, classKeyword: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: classKeyword)
        let pattern = "<span\\b[^>]*class=[\"'][^\"']*\\b\(escaped)\\b[^\"']*[\"'][^>]*>(.*?)</span>"
        guard let inner = firstCapture(in: html, pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return ""
        }
        let stripped = inner.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        return stripped
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractNormalizedHHMM(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#) else {
            return nil
        }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)),
              match.numberOfRanges >= 3,
              let hour = Int(nsText.substring(with: match.range(at: 1))),
              let minute = Int(nsText.substring(with: match.range(at: 2))) else {
            return nil
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    private func firstCapture(
        in text: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)),
              match.numberOfRanges >= 2 else {
            return nil
        }
        return nsText.substring(with: match.range(at: 1))
    }

    private func stringValue(_ raw: Any?) -> String? {
        if let str = raw as? String {
            return str
        }
        if let num = raw as? NSNumber {
            return num.stringValue
        }
        return nil
    }

    private func intValue(_ raw: Any?) -> Int? {
        if let intVal = raw as? Int {
            return intVal
        }
        if let num = raw as? NSNumber {
            return num.intValue
        }
        if let str = raw as? String {
            return Int(str.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

enum BusStatusCalculator {
    static func resolveDayType(mode: DayTypeMode, now: Date = Date()) -> ResolvedDayType {
        switch mode {
        case .weekday:
            return .weekday
        case .weekend:
            return .weekend
        case .auto:
            // Foundation Calendar: Sunday = 1, Saturday = 7
            let weekday = JSTClock.calendar.component(.weekday, from: now)
            return (weekday == 1 || weekday == 7) ? .weekend : .weekday
        }
    }

    static func buildSnapshot(
        direction: BusDirection,
        dayTypeMode: DayTypeMode,
        liveItems: [String: LiveBusInfo],
        isLiveConnected: Bool,
        now: Date = Date()
    ) -> BusStatusSnapshot {
        let dayType = resolveDayType(mode: dayTypeMode, now: now)
        let scheduleList = TimetableData.schedule(direction: direction, dayType: dayType)

        let comps = JSTClock.calendar.dateComponents([.hour, .minute, .second], from: now)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let second = comps.second ?? 0
        let nowMinutes = hour * 60 + minute
        let nowMinutesFloat = Double(nowMinutes) + Double(second) / 60.0

        var inTransitBuses: [BusItem] = []
        var upcomingBuses: [BusItem] = []

        for entry in scheduleList {
            let liveInfo = liveItems[entry.time]
            let delayMin = liveInfo?.delayMinutes ?? 0
            let gpsStation = liveInfo?.gpsStationName

            let expectedMin = entry.scheduledMinutes + delayMin
            let minutesUntil = expectedMin - nowMinutes
            let expectedTimeStr = formatHHMM(expectedMin)

            var arrMin = entry.arrivalMinutes + delayMin
            if arrMin < expectedMin {
                arrMin += 24 * 60
            }
            let expectedArrivalStr = formatHHMM(arrMin)
            let minutesUntilArrival = arrMin - nowMinutes

            if minutesUntil < 0 && minutesUntilArrival > 0 {
                let elapsed = max(0.0, nowMinutesFloat - Double(expectedMin))
                let location = estimateInTransitPosition(
                    direction: direction,
                    elapsedSinceBoarding: elapsed,
                    rideMinutes: entry.rideMinutes,
                    delayMinutes: delayMin,
                    routeNo: entry.routeNo,
                    expectedArrival: expectedArrivalStr,
                    gpsStationName: gpsStation
                )
                inTransitBuses.append(
                    BusItem(
                        id: "in_transit:\(entry.time):\(entry.routeNo)",
                        state: .inTransit,
                        routeNo: entry.routeNo,
                        routeLabel: entry.routeLabel,
                        shortDestination: entry.shortDestination,
                        origin: entry.origin,
                        scheduledTime: entry.time,
                        expectedTime: expectedTimeStr,
                        expectedArrivalTime: expectedArrivalStr,
                        minutesUntilDeparture: minutesUntil,
                        minutesUntilArrival: minutesUntilArrival,
                        delayMinutes: delayMin,
                        note: entry.note,
                        location: location
                    )
                )
                continue
            }

            if minutesUntil < 0 {
                continue
            }

            let location = estimateUpcomingPosition(
                direction: direction,
                minutesUntilDeparture: minutesUntil,
                delayMinutes: delayMin,
                originLabel: entry.origin,
                routeNo: entry.routeNo,
                gpsStationName: gpsStation
            )
            upcomingBuses.append(
                BusItem(
                    id: "upcoming:\(entry.time):\(entry.routeNo)",
                    state: .upcoming,
                    routeNo: entry.routeNo,
                    routeLabel: entry.routeLabel,
                    shortDestination: entry.shortDestination,
                    origin: entry.origin,
                    scheduledTime: entry.time,
                    expectedTime: expectedTimeStr,
                    expectedArrivalTime: expectedArrivalStr,
                    minutesUntilDeparture: minutesUntil,
                    minutesUntilArrival: minutesUntilArrival,
                    delayMinutes: delayMin,
                    note: entry.note,
                    location: location
                )
            )
        }

        var isTomorrow = false
        if upcomingBuses.isEmpty && !scheduleList.isEmpty {
            isTomorrow = true
            for entry in scheduleList.prefix(5) {
                let schedTomorrow = entry.scheduledMinutes + 24 * 60
                let minutesUntil = schedTomorrow - nowMinutes
                upcomingBuses.append(
                    BusItem(
                        id: "tomorrow:\(entry.time):\(entry.routeNo)",
                        state: .tomorrow,
                        routeNo: entry.routeNo,
                        routeLabel: entry.routeLabel,
                        shortDestination: entry.shortDestination,
                        origin: entry.origin,
                        scheduledTime: entry.time,
                        expectedTime: entry.time,
                        expectedArrivalTime: entry.arrivalTime,
                        minutesUntilDeparture: minutesUntil,
                        minutesUntilArrival: minutesUntil + entry.rideMinutes,
                        delayMinutes: 0,
                        note: entry.note,
                        location: BusPositionSummary(
                            headline: "本日の運行終了",
                            detail: "翌朝 \(entry.time) 発の始発便",
                            progress: 0.0,
                            isGPS: false
                        )
                    )
                )
            }
        }

        return BusStatusSnapshot(
            updatedAt: String(format: "%02d:%02d", hour, minute),
            dayType: dayType,
            isLiveConnected: isLiveConnected,
            isTomorrow: isTomorrow,
            inTransitBuses: inTransitBuses,
            upcomingBuses: Array(upcomingBuses.prefix(6))
        )
    }

    private static func formatHHMM(_ totalMinutes: Int) -> String {
        let normalized = ((totalMinutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", normalized / 60, normalized % 60)
    }

    private static func estimateInTransitPosition(
        direction: BusDirection,
        elapsedSinceBoarding: Double,
        rideMinutes: Int,
        delayMinutes: Int,
        routeNo: String,
        expectedArrival: String,
        gpsStationName: String?
    ) -> BusPositionSummary {
        let remaining = max(1, Int((Double(rideMinutes) - elapsedSinceBoarding).rounded()))
        let delaySuffix = delayMinutes > 0 ? "・遅れ+\(delayMinutes)分" : ""

        if routeNo == "直行" {
            let prog = min(0.95, max(0.06, elapsedSinceBoarding / Double(max(1, rideMinutes))))
            return BusPositionSummary(
                headline: "直行便で走行中",
                detail: "\(expectedArrival)着見込 (あと約\(remaining)分\(delaySuffix))",
                progress: prog,
                isGPS: false
            )
        }

        let stops = direction == .toStation ? TimetableData.inboundToStationStops : TimetableData.outboundToUnivStops
        let stopNames = stops.map(\.name)

        if let gpsName = gpsStationName, let gIdx = stopNames.firstIndex(of: gpsName) {
            let currIdx = min(gIdx, max(0, stops.count - 2))
            let nextName = stops[min(currIdx + 1, stops.count - 1)].name
            let prog = Double(currIdx) / Double(max(1, stops.count - 1))
            let headline = gIdx >= stops.count - 1
                ? "\(gpsName) 付近へ到着"
                : "\(gpsName) → \(nextName)"
            return BusPositionSummary(
                headline: headline,
                detail: "\(expectedArrival)着見込 (あと約\(remaining)分\(delaySuffix))",
                progress: min(0.96, max(0.08, prog)),
                isGPS: true
            )
        }

        var currIdx = max(0, stops.count - 2)
        for i in 0..<max(0, stops.count - 1) {
            if Double(stops[i].offsetMin) <= elapsedSinceBoarding &&
                elapsedSinceBoarding < Double(stops[i + 1].offsetMin) {
                currIdx = i
                break
            }
        }
        let currStop = stops[currIdx]
        let nextStop = stops[min(currIdx + 1, stops.count - 1)]
        let prog = min(0.95, max(0.05, elapsedSinceBoarding / Double(max(1, rideMinutes))))

        return BusPositionSummary(
            headline: "\(currStop.name) → \(nextStop.name)",
            detail: "\(expectedArrival)着見込 (あと約\(remaining)分\(delaySuffix))",
            progress: prog,
            isGPS: false
        )
    }

    private static func estimateUpcomingPosition(
        direction: BusDirection,
        minutesUntilDeparture: Int,
        delayMinutes: Int,
        originLabel: String,
        routeNo: String,
        gpsStationName: String?
    ) -> BusPositionSummary {
        if direction == .toUniv {
            if minutesUntilDeparture > 5 {
                return BusPositionSummary(
                    headline: "姫路駅(北口) 待機中",
                    detail: "18番のりば 始発",
                    progress: 0.0,
                    isGPS: false
                )
            }
            return BusPositionSummary(
                headline: "18番のりば 乗車案内中",
                detail: "まもなく発車します",
                progress: 0.12,
                isGPS: false
            )
        }

        if originLabel.contains("県立大工学部始発") {
            if minutesUntilDeparture > 5 {
                return BusPositionSummary(
                    headline: "県立大工学部 待機中",
                    detail: routeNo == "直行" ? "当停留所始発・直行便" : "当停留所始発便",
                    progress: 0.0,
                    isGPS: false
                )
            }
            return BusPositionSummary(
                headline: "県立大工学部 乗車案内中",
                detail: "まもなく発車します",
                progress: 0.12,
                isGPS: false
            )
        }

        let upstream = TimetableData.upstreamStops(for: originLabel)
        let approach = upstream + [StopPoint(name: "県立大工学部", offsetMin: 0)]
        let approachNames = approach.map(\.name)

        if let gpsName = gpsStationName {
            if let idx = approachNames.firstIndex(of: gpsName) {
                if idx >= approach.count - 1 {
                    return BusPositionSummary(
                        headline: "まもなく大学に到着",
                        detail: "\(gpsName) 付近",
                        progress: 0.94,
                        isGPS: true
                    )
                }
                let nextName = approach[idx + 1].name
                let prog = Double(idx + 1) / Double(max(1, approach.count))
                return BusPositionSummary(
                    headline: "\(gpsName) → \(nextName)",
                    detail: delayMinutes > 0 ? "遅れ+\(delayMinutes)分反映" : "のりばへ接近中",
                    progress: min(0.92, max(0.15, prog)),
                    isGPS: true
                )
            }
        }

        let earliestOffset = upstream.first?.offsetMin ?? -10
        let relMin = -minutesUntilDeparture

        if relMin < earliestOffset {
            let waitToStart = abs(relMin - earliestOffset)
            let originClean = originLabel.replacingOccurrences(of: "発", with: "")
            return BusPositionSummary(
                headline: "\(originClean) 待機中",
                detail: "約\(waitToStart)分後に始発発車",
                progress: 0.05,
                isGPS: false
            )
        }

        var currIdx = 0
        for i in 0..<max(0, approach.count - 1) {
            if approach[i].offsetMin <= relMin && relMin <= approach[i + 1].offsetMin {
                currIdx = i
                break
            }
            if relMin > approach[i + 1].offsetMin {
                currIdx = i
            }
        }

        if relMin >= -1 {
            let prevName = approach[max(0, approach.count - 2)].name
            return BusPositionSummary(
                headline: "まもなく大学に到着",
                detail: "\(prevName) を通過済み",
                progress: 0.92,
                isGPS: false
            )
        }

        let currP = approach[currIdx]
        let nextP = approach[min(currIdx + 1, approach.count - 1)]
        let stopsAway = max(1, (approach.count - 1) - currIdx)
        let prog = Double(currIdx + 1) / Double(max(1, approach.count))

        return BusPositionSummary(
            headline: "\(currP.name) → \(nextP.name)",
            detail: "あと\(stopsAway)区間" + (delayMinutes > 0 ? "・遅れ+\(delayMinutes)分" : ""),
            progress: min(0.9, max(0.15, prog)),
            isGPS: false
        )
    }
}

@MainActor
final class BusViewModel: ObservableObject {
    @Published var direction: BusDirection = .toStation
    @Published var dayTypeMode: DayTypeMode = .auto
    @Published var snapshot: BusStatusSnapshot
    @Published var isLoadingLive: Bool = false
    @Published var viewingInTransit: Bool = false
    @Published var selectedBusID: String?

    private let liveClient = ShinkiNaviLiveClient()
    private var lastLiveItems: [String: LiveBusInfo] = [:]
    private var lastLiveConnected: Bool = false

    init() {
        self.snapshot = BusStatusCalculator.buildSnapshot(
            direction: .toStation,
            dayTypeMode: .auto,
            liveItems: [:],
            isLiveConnected: false,
            now: Date()
        )
    }

    var displayedBus: BusItem? {
        if let selectedBusID = selectedBusID {
            if let match = snapshot.inTransitBuses.first(where: { $0.id == selectedBusID }) {
                return match
            }
            if let match = snapshot.upcomingBuses.first(where: { $0.id == selectedBusID }) {
                return match
            }
        }
        if viewingInTransit, let latestTransit = snapshot.inTransitBuses.last {
            return latestTransit
        }
        return snapshot.upcomingBuses.first ?? snapshot.inTransitBuses.last
    }

    func refreshLive() async {
        if isLoadingLive {
            return
        }
        isLoadingLive = true
        let targetDirection = direction
        let now = Date()
        let result = await liveClient.fetchLive(direction: targetDirection, now: now)

        if direction == targetDirection {
            lastLiveItems = result.items
            lastLiveConnected = result.ok
            rebuildSnapshot(now: Date())
        }
        isLoadingLive = false
    }

    func recalculateNow() {
        rebuildSnapshot(now: Date())
    }

    func toggleDirection() {
        direction = direction.toggled
        selectedBusID = nil
        viewingInTransit = false
        lastLiveItems = [:]
        lastLiveConnected = false
        rebuildSnapshot(now: Date())
        Task {
            await refreshLive()
        }
    }

    func cycleDayTypeMode() {
        dayTypeMode = dayTypeMode.next
        selectedBusID = nil
        rebuildSnapshot(now: Date())
    }

    func selectBus(_ bus: BusItem) {
        selectedBusID = bus.id
        viewingInTransit = (bus.state == .inTransit)
    }

    func switchMode(inTransit: Bool) {
        viewingInTransit = inTransit
        if inTransit {
            selectedBusID = snapshot.inTransitBuses.last?.id
        } else {
            selectedBusID = snapshot.upcomingBuses.first?.id
        }
    }

    private func rebuildSnapshot(now: Date) {
        snapshot = BusStatusCalculator.buildSnapshot(
            direction: direction,
            dayTypeMode: dayTypeMode,
            liveItems: lastLiveItems,
            isLiveConnected: lastLiveConnected,
            now: now
        )
        if viewingInTransit && snapshot.inTransitBuses.isEmpty {
            viewingInTransit = false
        }
        if let currentID = selectedBusID {
            let exists = snapshot.inTransitBuses.contains(where: { $0.id == currentID }) ||
                snapshot.upcomingBuses.contains(where: { $0.id == currentID })
            if !exists {
                selectedBusID = nil
            }
        }
    }
}

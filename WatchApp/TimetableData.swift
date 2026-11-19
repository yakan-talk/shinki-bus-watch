import Foundation

enum TimetableData {
    static let stationCodeMap: [String: String] = [
        "20000": "姫路駅(北口)",
        "20001": "大手前通り",
        "20030": "船場元町",
        "20032": "白鷺橋",
        "20157": "姫路城大手門前",
        "20159": "六角",
        "20240": "県立大工学部",
        "20242": "床坂菅生台",
        "20246": "書写台１丁目",
        "20248": "集会所前",
        "20250": "書写西住宅",
        "20238": "西坂",
        "20236": "西坂口",
        "20234": "東洋大姫路高校",
        "20232": "書写東坂",
        "20230": "書写郵便局前",
        "22002": "好古園前",
        "22004": "市之橋・文学館前",
        "22006": "岡町",
        "22008": "岩端北口",
        "22010": "東辻井",
        "22012": "名古山北口",
        "22014": "辻井南口",
        "22016": "辻井",
        "22018": "田寺南口",
        "22020": "田寺",
        "22022": "四軒屋",
        "22023": "御立南口",
        "22024": "御立",
        "22026": "御立北口",
        "22028": "横関",
        "22130": "岩端",
        "22132": "岩端南口",
        "22133": "龍野町",
        "19161": "打越",
        "24168": "打越新田",
        "24170": "緑台口",
        "24175": "緑台"
    ]

    static let inboundToStationStops: [StopPoint] = [
        StopPoint(name: "県立大工学部", offsetMin: 0),
        StopPoint(name: "西坂", offsetMin: 1),
        StopPoint(name: "西坂口", offsetMin: 1),
        StopPoint(name: "東洋大姫路高校", offsetMin: 2),
        StopPoint(name: "書写東坂", offsetMin: 3),
        StopPoint(name: "書写郵便局前", offsetMin: 4),
        StopPoint(name: "横関", offsetMin: 5),
        StopPoint(name: "御立北口", offsetMin: 6),
        StopPoint(name: "御立", offsetMin: 6),
        StopPoint(name: "御立南口", offsetMin: 7),
        StopPoint(name: "四軒屋", offsetMin: 8),
        StopPoint(name: "田寺", offsetMin: 9),
        StopPoint(name: "田寺南口", offsetMin: 10),
        StopPoint(name: "辻井", offsetMin: 11),
        StopPoint(name: "辻井南口", offsetMin: 12),
        StopPoint(name: "名古山北口", offsetMin: 13),
        StopPoint(name: "東辻井", offsetMin: 14),
        StopPoint(name: "岩端北口", offsetMin: 16),
        StopPoint(name: "岩端", offsetMin: 17),
        StopPoint(name: "岩端南口", offsetMin: 18),
        StopPoint(name: "龍野町", offsetMin: 19),
        StopPoint(name: "船場元町", offsetMin: 21),
        StopPoint(name: "白鷺橋", offsetMin: 22),
        StopPoint(name: "大手前通り", offsetMin: 24),
        StopPoint(name: "姫路駅(北口)", offsetMin: 27)
    ]

    static let outboundToUnivStops: [StopPoint] = [
        StopPoint(name: "姫路駅(北口)", offsetMin: 0),
        StopPoint(name: "大手前通り", offsetMin: 2),
        StopPoint(name: "姫路城大手門前", offsetMin: 3),
        StopPoint(name: "好古園前", offsetMin: 4),
        StopPoint(name: "市之橋・文学館前", offsetMin: 5),
        StopPoint(name: "岡町", offsetMin: 7),
        StopPoint(name: "岩端北口", offsetMin: 8),
        StopPoint(name: "東辻井", offsetMin: 9),
        StopPoint(name: "名古山北口", offsetMin: 10),
        StopPoint(name: "辻井南口", offsetMin: 11),
        StopPoint(name: "辻井", offsetMin: 12),
        StopPoint(name: "田寺南口", offsetMin: 13),
        StopPoint(name: "田寺", offsetMin: 14),
        StopPoint(name: "四軒屋", offsetMin: 16),
        StopPoint(name: "御立南口", offsetMin: 17),
        StopPoint(name: "御立", offsetMin: 18),
        StopPoint(name: "御立北口", offsetMin: 19),
        StopPoint(name: "横関", offsetMin: 20),
        StopPoint(name: "書写郵便局前", offsetMin: 21),
        StopPoint(name: "書写東坂", offsetMin: 22),
        StopPoint(name: "東洋大姫路高校", offsetMin: 23),
        StopPoint(name: "西坂口", offsetMin: 24),
        StopPoint(name: "西坂", offsetMin: 25),
        StopPoint(name: "県立大工学部", offsetMin: 26)
    ]

    // 県立大工学部 (20240, pcode=2) → 姫路駅(北口) 公式平日ダイヤ
    private static let toStationWeekdayRaw: [Int: [String]] = [
        5: ["38", "山50"],
        6: ["11", "21", "山31", "41", "山46", "51"],
        7: ["緑01", "06", "10", "山14", "バ18", "22", "緑26", "山37", "47"],
        8: ["03", "12", "山19", "31", "41", "54"],
        9: ["バ02", "05", "15", "緑30", "40", "バ50"],
        10: ["05", "緑10", "20", "35", "50"],
        11: ["バ00", "10", "緑20", "35", "バ50"],
        12: ["05", "直▲15", "緑20", "25", "35", "バ50"],
        13: ["姫00", "05", "緑20", "35", "山50"],
        14: ["05", "緑20", "直▲33", "35", "45", "バ50"],
        15: ["05", "緑20", "35", "55"],
        16: ["05", "10", "緑14", "直▲18", "25", "バ31", "40", "山52"],
        17: ["姫00", "緑12", "24", "36", "45", "バ54", "55", "58"],
        18: ["山01", "05", "10", "緑20", "32", "44", "姫57"],
        19: ["山11", "25", "45"],
        20: ["10", "緑20", "40"],
        21: ["10", "緑20", "40"],
        22: ["05", "30", "44"]
    ]

    // 県立大工学部 (20240, pcode=2) → 姫路駅(北口) 公式土日祝ダイヤ
    private static let toStationWeekendRaw: [Int: [String]] = [
        6: ["山01", "16", "山31", "緑55"],
        7: ["05", "バ15", "25", "山35", "45", "55"],
        8: ["山05", "15", "25", "40"],
        9: ["00", "バ15", "30", "緑45"],
        10: ["05", "25", "緑45"],
        11: ["05", "バ15", "緑25", "35", "バ50"],
        12: ["05", "緑20", "35", "バ50"],
        13: ["05", "緑20", "35", "山50"],
        14: ["05", "緑20", "35", "バ50"],
        15: ["05", "緑20", "35", "バ50"],
        16: ["05", "緑20", "35", "山50"],
        17: ["05", "緑20", "35", "バ50"],
        18: ["05", "緑20", "35", "バ55"],
        19: ["16", "42"],
        20: ["07", "緑18", "35"],
        21: ["06", "49"]
    ]

    // 姫路駅（北口 18番のりば 20000-18）公式平日ダイヤ
    private static let fromStationWeekdayRaw: [String: [Int: [String]]] = [
        "45": [
            6: ["工35", "45"],
            7: ["00", "15", "工30", "55"],
            8: ["10", "20", "25", "55"],
            9: ["25", "55"],
            10: ["00", "25", "55"],
            11: ["25", "55"],
            12: ["25", "55"],
            13: ["25", "55"],
            14: ["25", "55"],
            15: ["25", "工40", "55"],
            16: ["30", "55"],
            17: ["工25", "40", "55"],
            18: ["25", "55"],
            19: ["25", "55"],
            20: ["30", "55"],
            21: ["30", "55"],
            22: ["工15", "45"],
            23: ["工00", "15"]
        ],
        "43": [
            8: ["05", "30"],
            9: ["10"],
            10: ["10"],
            11: ["10"],
            12: ["10"],
            13: ["10"],
            14: ["10"],
            15: ["10"],
            16: ["10"],
            17: ["10"],
            18: ["15"],
            19: ["15"],
            20: ["15"],
            21: ["15"]
        ],
        "41_42": [
            7: ["古45"],
            8: ["荒40"],
            9: ["バ40"],
            10: ["荒40"],
            11: ["荒40"],
            12: ["荒15", "山40"],
            13: ["荒40"],
            14: ["山40"],
            15: ["山45"],
            16: ["荒45"],
            17: ["◆45"],
            18: ["バ45"],
            19: ["山45"],
            20: ["山45"],
            21: ["荒45"],
            22: ["山30"]
        ],
        "直行": [
            8: ["▲05", "▲10", "▲15", "▲20", "▲25", "▲30"],
            9: ["▲50"],
            10: ["▲00", "▲05"],
            11: ["▲45"],
            12: ["▲25"],
            15: ["▲40"]
        ]
    ]

    // 姫路駅（北口 18番のりば 20000-18）公式土日祝ダイヤ
    private static let fromStationWeekendRaw: [String: [Int: [String]]] = [
        "45": [
            7: ["05", "15", "35", "45"],
            8: ["10", "50"],
            9: ["25", "45"],
            10: ["25", "55"],
            11: ["25", "55"],
            12: ["25", "55"],
            13: ["25", "55"],
            14: ["25", "55"],
            15: ["25", "55"],
            16: ["25", "55"],
            17: ["25", "55"],
            18: ["30"],
            19: ["00", "30"],
            20: ["00", "30"],
            21: ["15", "45"],
            22: ["工15", "横55"]
        ],
        "43": [
            7: ["25"],
            8: ["20", "30"],
            9: ["10"],
            10: ["10"],
            11: ["10"],
            12: ["10"],
            13: ["10"],
            14: ["10"],
            15: ["10"],
            16: ["10"],
            17: ["15"],
            18: ["15"],
            19: ["15"],
            20: ["15"],
            21: ["30"]
        ],
        "41_42": [
            9: ["バ55"],
            10: ["荒40"],
            11: ["荒40"],
            12: ["山40"],
            13: ["荒40"],
            14: ["山40"],
            15: ["山40"],
            16: ["荒40"],
            17: ["荒45"],
            18: ["バ45"],
            19: ["山45"],
            20: ["山45"],
            22: ["山35"]
        ]
    ]

    static let toStationWeekday: [TimetableEntry] = expandToStation(toStationWeekdayRaw)
    static let toStationWeekend: [TimetableEntry] = expandToStation(toStationWeekendRaw)
    static let toUnivWeekday: [TimetableEntry] = expandFromStation(fromStationWeekdayRaw)
    static let toUnivWeekend: [TimetableEntry] = expandFromStation(fromStationWeekendRaw)

    static func schedule(direction: BusDirection, dayType: ResolvedDayType) -> [TimetableEntry] {
        switch (direction, dayType) {
        case (.toStation, .weekday):
            return toStationWeekday
        case (.toStation, .weekend):
            return toStationWeekend
        case (.toUniv, .weekday):
            return toUnivWeekday
        case (.toUniv, .weekend):
            return toUnivWeekend
        }
    }

    static func upstreamStops(for originLabel: String) -> [StopPoint] {
        if originLabel.contains("書写西住宅") {
            return [
                StopPoint(name: "書写西住宅", offsetMin: -3),
                StopPoint(name: "集会所前", offsetMin: -2),
                StopPoint(name: "書写台１丁目", offsetMin: -1)
            ]
        }
        let originShort = originLabel
            .replacingOccurrences(of: "発", with: "")
            .replacingOccurrences(of: "・荒木", with: "")
        return [
            StopPoint(name: originShort, offsetMin: -10),
            StopPoint(name: "緑台口", offsetMin: -8),
            StopPoint(name: "打越新田", offsetMin: -7),
            StopPoint(name: "打越", offsetMin: -6),
            StopPoint(name: "六角", offsetMin: -5),
            StopPoint(name: "床坂菅生台", offsetMin: -3)
        ]
    }

    private static func splitToken(_ token: String) -> (prefix: String, minute: Int) {
        var prefixScalars: [UnicodeScalar] = []
        var digitScalars: [UnicodeScalar] = []
        for scalar in token.unicodeScalars {
            if CharacterSet.decimalDigits.contains(scalar) {
                digitScalars.append(scalar)
            } else {
                prefixScalars.append(scalar)
            }
        }
        let prefix = String(String.UnicodeScalarView(prefixScalars))
        let minute = Int(String(String.UnicodeScalarView(digitScalars))) ?? 0
        return (prefix, minute)
    }

    private static func formatTime(_ totalMinutes: Int) -> String {
        let hour = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private static func expandToStation(_ rawHours: [Int: [String]]) -> [TimetableEntry] {
        var results: [TimetableEntry] = []
        for hour in rawHours.keys.sorted() {
            for token in rawHours[hour] ?? [] {
                let (prefix, minute) = splitToken(token)
                let schedMin = hour * 60 + minute
                let timeStr = String(format: "%02d:%02d", hour, minute)

                let routeNo: String
                let origin: String
                let rideMin: Int

                if prefix.contains("直") {
                    routeNo = "直行"
                    origin = "県立大工学部始発"
                    rideMin = 22
                } else if prefix.contains("姫") {
                    routeNo = "7"
                    origin = "県立大工学部始発"
                    rideMin = 28
                } else if prefix.contains("緑") {
                    routeNo = "43"
                    origin = "緑台発"
                    rideMin = 27
                } else if prefix.contains("バ") {
                    routeNo = "41"
                    origin = "バーズタウン・荒木発"
                    rideMin = 27
                } else if prefix.contains("山") {
                    routeNo = "42"
                    origin = "山崎発"
                    rideMin = 27
                } else {
                    routeNo = "45"
                    origin = "書写西住宅発"
                    rideMin = 27
                }

                let note = prefix.contains("▲") ? "休講日運休" : ""
                let arrMin = schedMin + rideMin

                results.append(
                    TimetableEntry(
                        time: timeStr,
                        arrivalTime: formatTime(arrMin),
                        scheduledMinutes: schedMin,
                        arrivalMinutes: arrMin,
                        routeNo: routeNo,
                        destination: "姫路駅（北口）",
                        origin: origin,
                        rideMinutes: rideMin,
                        note: note
                    )
                )
            }
        }
        return results
    }

    private static func expandFromStation(_ byRouteHours: [String: [Int: [String]]]) -> [TimetableEntry] {
        var entries: [TimetableEntry] = []
        for (routeKey, hoursDict) in byRouteHours {
            for (hour, tokens) in hoursDict {
                for token in tokens {
                    let (prefix, minute) = splitToken(token)
                    let schedMin = hour * 60 + minute
                    let timeStr = String(format: "%02d:%02d", hour, minute)

                    let routeNo: String
                    let dest: String
                    let rideMin: Int
                    let note: String

                    if routeKey == "直行" {
                        routeNo = "直行"
                        dest = "県立大工学部（直行）"
                        rideMin = 22
                        note = prefix.contains("▲") ? "休講日運休" : ""
                    } else if routeKey == "45" {
                        routeNo = "45"
                        rideMin = 26
                        note = ""
                        if prefix.contains("工") {
                            dest = "県立大工学部"
                        } else if prefix.contains("横") {
                            dest = "横関（県立大工学部経由）"
                        } else {
                            dest = "書写西住宅（県立大工学部経由）"
                        }
                    } else if routeKey == "43" {
                        routeNo = "43"
                        dest = "緑台（県立大工学部経由）"
                        rideMin = 26
                        note = ""
                    } else {
                        rideMin = 26
                        note = ""
                        if prefix.contains("山") || prefix.contains("◆") {
                            routeNo = "42"
                            dest = "山崎（県立大工学部経由）"
                        } else if prefix.contains("古") {
                            routeNo = "41"
                            dest = "古瀬畑（県立大工学部経由）"
                        } else if prefix.contains("荒") {
                            routeNo = "41"
                            dest = "荒木（県立大工学部経由）"
                        } else {
                            routeNo = "41"
                            dest = "バーズタウン（県立大工学部経由）"
                        }
                    }

                    let arrMin = schedMin + rideMin
                    entries.append(
                        TimetableEntry(
                            time: timeStr,
                            arrivalTime: formatTime(arrMin),
                            scheduledMinutes: schedMin,
                            arrivalMinutes: arrMin,
                            routeNo: routeNo,
                            destination: dest,
                            origin: "姫路駅（北口 18番のりば）始発",
                            rideMinutes: rideMin,
                            note: note
                        )
                    )
                }
            }
        }
        return entries.sorted { lhs, rhs in
            if lhs.scheduledMinutes != rhs.scheduledMinutes {
                return lhs.scheduledMinutes < rhs.scheduledMinutes
            }
            return lhs.routeNo < rhs.routeNo
        }
    }
}

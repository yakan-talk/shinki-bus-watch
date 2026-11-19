import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BusViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var routeAccent: Color {
        viewModel.direction == .toStation ? .blue : .teal
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    directionButton

                    if !viewModel.snapshot.inTransitBuses.isEmpty {
                        modeSwitchBar
                    }

                    if let bus = viewModel.displayedBus {
                        heroCard(for: bus)
                    } else {
                        emptyCard
                    }

                    upcomingSection

                    footerSection
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 6)
            }
            .navigationTitle("神姫バス")
        }
        .sensoryFeedback(.selection, trigger: viewModel.direction)
        .task {
            await viewModel.refreshLive()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                if Task.isCancelled { break }
                if scenePhase == .active {
                    await viewModel.refreshLive()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.recalculateNow()
                Task {
                    await viewModel.refreshLive()
                }
            }
        }
    }

    private var directionButton: some View {
        Button {
            viewModel.toggleDirection()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.snapshot.isLiveConnected ? Color.green : Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                Text(viewModel.direction.shortTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(routeAccent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(routeAccent.opacity(0.22), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var modeSwitchBar: some View {
        let nextTime = viewModel.snapshot.upcomingBuses.first?.expectedTime ?? "--:--"
        let transitTime = viewModel.snapshot.inTransitBuses.last?.scheduledTime ?? "--:--"

        return HStack(spacing: 4) {
            modePillButton(
                title: "次発 \(nextTime)",
                isSelected: !viewModel.viewingInTransit
            ) {
                viewModel.switchMode(inTransit: false)
            }
            modePillButton(
                title: "乗車中 \(transitTime)",
                isSelected: viewModel.viewingInTransit
            ) {
                viewModel.switchMode(inTransit: true)
            }
        }
    }

    private func modePillButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    isSelected ? routeAccent.opacity(0.35) : Color.white.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func heroCard(for bus: BusItem) -> some View {
        let statusInfo = badgeInfo(for: bus)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(bus.routeLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(routeAccent.opacity(0.28), in: Capsule())
                    .foregroundStyle(routeAccent)

                if viewModel.direction == .toUniv && bus.shortDestination != "県立大工学部" {
                    Text(bus.shortDestination)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                Text(statusInfo.text)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusInfo.color.opacity(0.22), in: Capsule())
                    .foregroundStyle(statusInfo.color)
            }

            countdownView(for: bus)

            HStack(spacing: 4) {
                Text("\(bus.expectedTime) 発")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                Text("→")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(bus.expectedArrivalTime) 着")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                if bus.delayMinutes > 0 {
                    Spacer(minLength: 2)
                    Text("定刻 \(bus.scheduledTime)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: bus.location.isGPS ? "dot.radiowaves.left.and.right" : "bus.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(bus.location.isGPS ? .green : routeAccent)
                    Text(bus.location.headline)
                        .font(.caption2.weight(.medium))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 2)
                    if bus.location.isGPS {
                        Text("GPS")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.22), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                if !bus.location.detail.isEmpty {
                    Text(bus.location.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                ProgressView(value: min(max(bus.location.progress, 0.0), 1.0))
                    .tint(bus.delayMinutes > 0 ? .orange : routeAccent)
            }
            .padding(.top, 2)

            if !bus.note.isEmpty {
                Label(bus.note, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func countdownView(for bus: BusItem) -> some View {
        let minutes = bus.state == .inTransit
            ? max(1, bus.minutesUntilArrival)
            : max(0, bus.minutesUntilDeparture)

        VStack(alignment: .leading, spacing: 0) {
            Text(bus.state == .inTransit ? "目的地到着まで" : "発車まで")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            if bus.state != .inTransit && minutes == 0 {
                Text("まもなく")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.mint)
            } else if minutes >= 60 {
                let hours = minutes / 60
                let rem = minutes % 60
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("あと")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if rem == 0 {
                        Text("\(hours)時間")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    } else {
                        Text("\(hours)時間\(rem)分")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("あと")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(minutes)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(bus.delayMinutes > 0 ? .orange : .primary)
                    Text("分")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func badgeInfo(for bus: BusItem) -> (text: String, color: Color) {
        if bus.state == .tomorrow {
            return ("翌朝", .purple)
        }
        if bus.delayMinutes > 0 {
            return ("+\(bus.delayMinutes)分", .orange)
        }
        if bus.state == .inTransit {
            return ("走行中", .mint)
        }
        return ("定刻", .green)
    }

    private var emptyCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("本日の運行は終了しました")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var upcomingSection: some View {
        let buses = viewModel.snapshot.upcomingBuses
        let activeID = viewModel.displayedBus?.id

        return VStack(alignment: .leading, spacing: 4) {
            if !buses.isEmpty {
                Text(viewModel.snapshot.isTomorrow ? "翌朝の始発" : "これからのバス")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)

                ForEach(buses) { bus in
                    let isSelected = bus.id == activeID
                    Button {
                        viewModel.selectBus(bus)
                    } label: {
                        HStack(spacing: 6) {
                            Text(bus.expectedTime)
                                .font(.caption.weight(.bold))
                                .monospacedDigit()

                            Text(bus.routeLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(routeAccent.opacity(0.22), in: Capsule())
                                .foregroundStyle(routeAccent)

                            if !bus.note.isEmpty {
                                Text("休講運休")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                            }

                            Spacer(minLength: 2)

                            if bus.delayMinutes > 0 {
                                Text("+\(bus.delayMinutes)分")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.orange)
                            } else {
                                Text(shortCountdown(minutes: bus.minutesUntilDeparture))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            isSelected ? routeAccent.opacity(0.24) : Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? routeAccent.opacity(0.8) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shortCountdown(minutes: Int) -> String {
        let m = max(0, minutes)
        if m == 0 { return "まもなく" }
        if m >= 60 {
            let h = m / 60
            let rem = m % 60
            return rem == 0 ? "\(h)h" : "\(h)h\(rem)m"
        }
        return "あと\(m)分"
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    Task {
                        await viewModel.refreshLive()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.isLoadingLive {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                        }
                        Text("更新")
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.cycleDayTypeMode()
                } label: {
                    Text(dayButtonLabel)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("\(viewModel.snapshot.updatedAt)更新・\(viewModel.snapshot.isLiveConnected ? "Navi LIVE" : "内蔵時刻表")")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var dayButtonLabel: String {
        switch viewModel.dayTypeMode {
        case .auto:
            return "自動(\(viewModel.snapshot.dayType.shortLabel))"
        case .weekday:
            return "平日固定"
        case .weekend:
            return "土日祝固定"
        }
    }
}

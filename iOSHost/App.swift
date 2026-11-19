import SwiftUI

@main
struct WatchHostCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            CompanionGuideView()
        }
    }
}

private struct CompanionGuideView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 10) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        Text("ShinkiBusWatch")
                            .font(.title2.bold())
                        Text("県立大工学部前 ⇔ 姫路駅（北口）")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Apple Watch への導入手順", systemImage: "applewatch")
                            .font(.headline)

                        GuideStepRow(
                            number: "1",
                            title: "デベロッパモードを有効化",
                            detail: "iPhone と Apple Watch の両方で「設定」→「プライバシーとセキュリティ」→「デベロッパモード」をオンにします。"
                        )
                        GuideStepRow(
                            number: "2",
                            title: "Watch アプリからインストール",
                            detail: "iPhone の「Watch」アプリを開き、「利用可能なApp」から「神姫バス」の「インストール」をタップします。"
                        )
                        GuideStepRow(
                            number: "3",
                            title: "7日ごとの再署名について",
                            detail: "無料 Apple ID でサイドロードした場合、証明書の有効期限は7日間です。期限前に Sideloadly で同じ Apple ID から再転送してください。"
                        )
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    if let url = URL(string: "https://navi.shinkibus.jp/") {
                        Link(destination: url) {
                            Label("神姫バスNavi（公式）を開く", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("神姫バス Watch")
        }
    }
}

private struct GuideStepRow: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

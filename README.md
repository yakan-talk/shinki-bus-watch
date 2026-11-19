# ShinkiBusWatch（神姫バス Watch アプリ）

`shinki-bus-app`（県立大工学部前 ⇔ 姫路駅（北口））の時刻表・リアルタイム接近情報機能を **Apple Watch（watchOS 10+）向けに最適化したネイティブ SwiftUI アプリ**です。  
Mac を使わずに GitHub Actions（`macos-latest`）で自動ビルドして未署名 `.ipa` を生成し、Windows PC から **Sideloadly** を使って iPhone / Apple Watch 実機に転送できます。

## Watch 向けの最適化ポイント

- **1タップ方向切替**：画面最上部のカプセルボタンで「大学 → 姫路駅」と「姫路駅 → 大学」を即切替
- **大画面カウントダウン**：`あと N 分` / `まもなく` を大きく表示し、腕を上げて一目で確認可能
- **走行位置・到着予想の要約表示**：Web 版の25駅路線図バーを Watch 画面向けに「現在区間テキスト + 進捗バー + GPSバッジ」へ圧縮
- **乗車中モード自動切替**：出発済みで走行中のバスがある場合は `次発` / `乗車中` をワンタップで切替
- **オフライン耐性 + リアルタイム連携**：公式時刻表データをアプリに内蔵しつつ、通信可能時は `navi.shinkibus.jp` から遅延・GPS走行位置を直接取得（30秒自動更新＋手動更新）
- **祝日対応のダイヤ切替**：`自動(平日/土日祝)` → `平日固定` → `土日祝固定` をフッターから切替可能

## プロジェクト構成

```text
shinki-bus-watch/
├── .github/
│   └── workflows/
│       └── build-watchos.yml   # GitHub Actions ビルド＆IPA生成ワークフロー
├── iOSHost/
│   └── App.swift               # WatchHostApp（最小構成のiOSコンパニオン案内画面）
├── WatchApp/
│   ├── WatchApp.swift          # MyWatchApp エントリポイント
│   ├── BusModels.swift         # バスデータモデル
│   ├── TimetableData.swift     # 公式時刻表・停留所データ（平日/土日祝）
│   ├── BusService.swift        # navi.shinkibus.jp 通信・運行位置推定・ViewModel
│   └── ContentView.swift       # Apple Watch 最適化 UI
├── project.yml                 # XcodeGen 定義（GENERATE_INFOPLIST_FILE: YES）
├── .gitignore
└── README.md
```

## ターゲット構成（無料 Apple ID + Sideloadly 対応）

| 項目 | 親 iOS アプリ | watchOS アプリ（同梱） |
| :--- | :--- | :--- |
| ターゲット名 | `WatchHostApp` | `MyWatchApp` |
| 表示名 | `ShinkiBusWatch` | `神姫バス` |
| プラットフォーム | iOS 17.0+ | watchOS 10.0+ |
| Bundle ID | `com.local.mywatchapp` | `com.local.mywatchapp.watchkitapp` |
| Info.plist | `GENERATE_INFOPLIST_FILE: YES` で自動生成 | `GENERATE_INFOPLIST_FILE: YES` + `WKApplication` / `WKCompanionAppBundleIdentifier` |

## GitHub Actions での自動ビルド手順

1. `main` ブランチへ Push するか、GitHub リポジトリの **Actions** タブ → **Build watchOS IPA** → **Run workflow** を実行します。
2. ワークフロー上で `brew install xcodegen` → `xcodegen generate` → `xcodebuild archive`（署名なし）→ `Payload/WatchHostApp.app` の ZIP 圧縮が実行されます。
3. 完了後、ワークフロー実行結果ページの **Artifacts** セクションから **`MyWatchApp-ipa`** をダウンロードし、中の `MyWatchApp.ipa` を解凍します。

## Windows から Sideloadly で iPhone / Apple Watch 実機に転送する手順

### 事前準備
1. **Windows PC にインストールするもの**:
   - [Sideloadly](https://sideloadly.io/)（Windows版）
   - Apple デバイス認識用に Apple 公式の **iTunes（非 Microsoft Store 版推奨）** および **iCloud（非 Microsoft Store 版推奨）** をインストールし、USB 接続した iPhone で「このコンピュータを信頼」をタップしておきます。
2. **デベロッパモードの有効化（iPhone・Apple Watch 両方必須）**:
   - **iPhone**: `設定` → `プライバシーとセキュリティ` → `デベロッパモード` をオンにして再起動。
   - **Apple Watch**: `設定` → `プライバシーとセキュリティ` → `デベロッパモード` をオンにして再起動（Watch に表示されない場合は iPhone 側の Watch アプリ接続・再起動を確認）。

### Sideloadly での転送・インストール
1. iPhone を USB ケーブルで Windows PC に接続し、Sideloadly を起動します。
2. GitHub Actions からダウンロードした `MyWatchApp.ipa` を Sideloadly へドラッグ＆ドロップします。
3. **Apple ID** 欄に自分の無料 Apple ID（メールアドレス）を入力します。
   - ※ **Advanced options** は基本的にデフォルトのままで構いません（同梱されている Watch アプリと Bundle ID 構造を保つため、不要な ID 書き換え設定には注意してください）。
4. **Start** をクリックし、Apple ID のパスワード・2ファクタ認証コードを入力すると署名・転送が開始されます。
5. iPhone への転送が完了したら、iPhone 側で `設定` → `一般` → `VPNとデバイス管理` を開き、自分の Apple ID を選択して **「信頼」** をタップします。
6. iPhone で **Watch** アプリを開き、最下部の **「利用可能なApp」** に表示される **「神姫バス」** の **「インストール」** をタップして Apple Watch へ転送します。

### 運用・トラブルシューティング
- **7日間の有効期限**: 無料 Apple ID で署名したアプリは **7日間** で起動できなくなります。期限が切れる前（または切れた後）に、同じ Apple ID で Sideloadly から `MyWatchApp.ipa` を再転送すると上書き更新されます。
- **Watch 側で「インストール中」のまま進まない場合**:
  - iPhone と Apple Watch の両方で **デベロッパモードが ON** になっているか確認してください。
  - Apple Watch を充電器に載せ、iPhone と同じ Wi-Fi ネットワーク上で同期を試してください。
  - それでも Watch に同期されない場合、Windows 版 Sideloadly はネストされた `Watch/*.app` の再署名・転送に環境差が出る場合があるため、Sideloadly の最新版への更新、または Mac / AltStore 等の別手段での署名をお試しください。

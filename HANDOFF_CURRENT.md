# 星を聴く — CURRENT HANDOFF

更新日: 2026-09-06 (Asia/Tokyo)

## 1. 対象・コンセプト・現在工程

- 対象: 新規iPhoneアプリ「星を聴く / Hear the Stars」。
- 現在地・日時・恒星座標とiPhoneの真北方位/姿勢を端末内で照合し、選んだ星へ近づくほど音と振動が速く・明瞭になる体験。
- 現在工程: 主導線を `星を選ぶ → 探す → 方向一致` に簡素化し、操作モックとSwiftUI実装へ反映済み。次はmacOS/Xcodeと実機で確認する。

## 2. 確定済み要件・UI方針・ユーザー判断

- 進行は `星を選ぶ → 探す → 方向一致 → 次の星`。星名を押すと探索へ直行する。
- 「科学の目」からは配色でなく、全画面の主体験、状態ごとに一つの主操作、段階的開示、固定サンプルでのモック承認ゲートを継承する。
- 通常探索はカメラ画像認識に依存しない。「星を検出」ではなく「計算上の星の方向を捉えた」と表現する。
- 黒に近い背景、低輝度の生成り/灰緑/赤銅/琥珀、細線、余白、静かな同心波紋。青紫の宇宙背景、星雲、SF HUD、派手な発光は禁止。
- 主要画面は縦スクロールなし。観察面を画面の大半、下部にその状態専用の操作面を置く。
- 探索中は音と振動を常に同時に出す。近づくほどパルス間隔を短くし、音の輪郭と振動強度を上げる。画面は静かな補助に留める。
- 独立した安全確認・補正画面、3モード切替、角度診断、練習操作は主導線から外す。
- 歩行/走行/車移動を検出した時は裏側で音・振動・発見判定を停止する。方位精度不足は探索画面の短い8の字案内だけで示す。
- 地平線下または高度2°未満は探索を停止し、別の星を選ばせる。固定練習空への自動切替はしない。
- 権利判断の抽出: IAU公式サイト由来の少数の恒星名だけを、CC BY 4.0の帰属・変更表示・非支持表示・ロゴ不使用で採用候補とする。恒星座標のGaia由来データは商用再配布条件が確定するまで`conditional`扱い、Hipparcos/Tycho（CC BY-NC）は商用バイナリへ入れない。NASA/HEASARC等の派生カタログは書面確認前に使わない。
- 星座線、音、触覚、波紋などの表現はすべて自作または商用利用を証明できる素材のみ。出荷時は全データ・素材を台帳化し、`conditional`、不明、非商用限定を0件にしてから外部配布する。
- 日本語/英語、VoiceOver、Dynamic Type、Reduce Motion/Transparency対応。通信、ログイン、広告、外部解析SDKなし。

## 3. 作業場所・主要ファイル

- 正本予定: `C:\dev\fishing\hear-stars`
- 最新の簡素化モック（HTML fragment）: `C:\Users\81906\.codex\visualizations\2026\09\06\01a074b4-7cd8-7ff2-a45a-56ac639dce1f\hear-stars-simple-mock.html`
- 旧4画面モック: `C:\Users\81906\.codex\visualizations\2026\09\06\01a074b4-7cd8-7ff2-a45a-56ac639dce1f\hear-stars-mock.html`
- 表示確認用ラップ: `C:\Users\81906\.codex\visualizations\2026\09\06\01a074b4-7cd8-7ff2-a45a-56ac639dce1f\hear-stars-mock-preview.html`
- 最新の静止画方向性: `C:\Users\81906\.codex\visualizations\2026\09\06\01a074b4-7cd8-7ff2-a45a-56ac639dce1f\hear-stars-mock-direction-v2.png`
- 要件: [docs/01-requirements.md](docs/01-requirements.md)
- 画面遷移: [docs/02-screen-flow.md](docs/02-screen-flow.md)
- UI比較: [docs/03-ui-concepts.md](docs/03-ui-concepts.md)
- 受入条件: [docs/07-acceptance.md](docs/07-acceptance.md)
- 追加検証資料: [docs/UI-CONCEPTS.md](docs/UI-CONCEPTS.md)、[docs/REQUIREMENTS-AND-RIGHTS.md](docs/REQUIREMENTS-AND-RIGHTS.md)、[docs/ASTRONOMY-VALIDATION.md](docs/ASTRONOMY-VALIDATION.md)
- SwiftUI骨格: `HearStarsApp/`
- 天体/案内コア: `Sources/HearStarsCore/`
- テスト: `Tests/HearStarsCoreTests/`

## 4. バージョン・識別子

- Marketing Version: `0.1.0`（プロトタイプ設定）
- Build: `1`（プロトタイプ設定）
- Bundle ID: `com.example.HearStars`（プレースホルダー。リリース前に確定必須）
- Apple App ID / App Store Connect App ID: 未作成
- IAP / AdMob: 使わない。IDなし。
- 署名Team / 証明書 / Provisioning Profile: 未設定

## 5. IPA・公開・外部サービス

- 最新IPA: なし
- IPAダウンロードURL: なし
- 公開Web URL: なし
- App Store Connect: アプリレコード未作成、URLなし
- App Store公開ページ: なし
- Codemagic: 署名なしIPA用の codemagic.yaml を追加済み。GitHub接続・ビルド実行・具体的ビルドURLは未作成。
- Sideloadly: 未実施
- 試用用のジャイロWebプレビュー: スレッド専用visualizations領域に hear-stars-gyro-preview.zip を作成。これはIPAではなく、Safariで画面遷移とジャイロUIを確認するための単体HTML。

## 6. 完了済み・確認結果

- 「科学の目」Web/iOSの進め方とUI構造を読み取り確認。配色コピーではなく、モック承認ゲートと状態中心の全画面構造を採用。
- 3画面の簡素化モックを作成。星名を押すと探索へ直行し、`遠い / 近い / 一致` で音・振動の間隔が変わり、0.8秒一致後に結果へ進む。
- モックはJavaScript構文確認済み。Chrome/Playwrightで3画面遷移と結果到達を確認し、736px・360px・320pxで横あふれなし。
- SwiftUIは `TargetPickerView` を星名の直接選択へ、`FinderView` を波紋・短い方向文・音振動案内へ簡素化。
- `AppModel.startFinding` でセンサー開始後にFinderへ直行。探索パルスと一致時の星固有パターンは、音と触覚を常に両方再生する。
- Motion & Fitnessが未許可/未判定で探索全体を止める条件を外し、実際に移動を検出した時だけ安全停止する。
- 地平線下/高度2°未満の固定練習空への自動切替を外し、案内を停止する。
- 近づくほどパルス間隔が短く明瞭度が上がるコアテストを追加。
- 天体参照値のPythonスモークテストは `Reference fixtures: OK`。Swift/Xcodeテストは未実施。
- 構造・ローカライズ・AppIcon・Privacy Manifest監査は `Project structure: OK`。

## 7. 未解決・既知制約

- 簡素化モックは正本フォルダ外のスレッド専用visualizations領域にある。
- Windows環境のためSwiftUI/Xcodeコンパイル、VoiceOver、音、触覚、Core Motion、実機表示は未確認。
- Codemagicビルド実行、署名、IPA、実機検証は未完了。
- 星データの出典/商用再配布条件は最終確定前。Gaiaは`conditional`、Hipparcos/Tychoは商用不採用、星座線は独自作成方針。詳細な一次資料・クレジット文・台帳様式は`docs/REQUIREMENTS-AND-RIGHTS.md`を正本とする。
- `C:\dev\fishing\hear-stars` は独立Gitリポジトリだが、全ファイル未追跡・コミットなし。
- 旧Safety/Calibration/Practice/GuidanceModeコードはコンパイル互換のため残っているが、通常導線からは到達しない。Xcode確認後に整理可能。

## 8. 次の作業（優先順）

1. GitHubへ初回コミット・プッシュし、Codemagicで ios-debug-unsigned を実行してIPAを取得する。
2. Sideloadlyで実機へ導入し、北極星など現在見える1星で向き、音・振動、移動時停止、0.8秒一致を確認する。
3. 実機OK後に署名付きTestFlight配布を別工程で準備する。

## 9. 固定運用ルール

- アプリごとにチャットを分離し、他アプリを混ぜない。
- Codemagicでビルドし、Sideloadlyで実機デバッグする。
- 実機OK後にApp Store申請へ進む。
- 審査動画はAppleから明示的に要求された場合だけ作る。
- ユーザーには「どのリンクか」が分かる具体的なリンク名とURL/絶対パスを提示する。
- 通信/権限/素材を追加する場合は、プライバシーと商用利用条件を再確認する。

## 10. Codex / Git状態

- この旧チャットのcwd: `C:\Users\81906\.codex\worktrees\6404\fishing`
- cwd Git状態: detached HEAD、commit `d621d69`、確認時はclean。このアプリの正本ではなく変更していない。
- 正本予定リポジトリ: `C:\dev\fishing\hear-stars`
- 正本Git状態: `main`、コミットなし、全成果物が未追跡。
- 最新モックのみスレッド専用visualizations領域。SwiftUIとコア変更は正本予定リポジトリへ反映済み。
- 並行タスクが同じ正本へ書いた経緯があるため、削除/上書き前に必ず現ファイルを読み、統合する。

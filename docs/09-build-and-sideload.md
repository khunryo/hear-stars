# 09 GitHub の無料ビルドと iPhone での試用

## 現在地

ユーザー本人の実機試用用に、署名なし IPA を作る。Codemagic の無料枠を使い切ったため、2026-09-08 のユーザー承認により GitHub Actions を標準のビルド先に変更した。TestFlight / App Store 用の署名付き配布とは別工程であり、権利確認・屋外実機検証は引き続き必要。

## GitHub Actions

- 設定: [ios-unsigned.yml](../.github/workflows/ios-unsigned.yml)
- 実行結果: [このアプリの Actions](https://github.com/khunryo/hear-stars/actions)
- 公開リポジトリと標準 `macos-26` ランナーの組合せを使用。非公開へ変更された場合はジョブを実行しない。大型ランナーは使わない。
- Xcode 26.4 系を明示し、構造監査 → 全 Swift テスト → iPhone ビルド → ビルド済み翻訳の全13状態検証・文言部品PNG → IPA検査を実行する。
- 現在は `codex/readiness-return-flow` の対象ソース変更を push すると開始する。main は変更しない。既存ビルドの再実行も Actions 画面から可能。
- 成果物は IPA と日英の確認用 PNG のみ、合計20MiB以下、保持1日。キャッシュは保存しない。無料の実行時間と成果物保存容量は別条件なので、保存枠はビルド前に確認する。
- 成功した実行の Artifacts から ZIP を取得し、含まれる `HearStars-unsigned.ipa` を Sideloadly に渡す。取得後のローカルファイルは GitHub 上の保持期限に影響されない。
- Apple の証明書やアカウント秘密情報は GitHub へ追加しない。Codemagic の有料ビルドは起動しない（既存設定は履歴・代替用に残す）。

料金条件: [GitHub Actions 公式](https://docs.github.com/en/billing/concepts/product-billing/github-actions)。確認用PNGは本番の文言部品をmacOS上で描画したもので、iPhone全画面や実センサーの試験ではない。

## 屋外試験用のローカル実機ビルド

macOS、対応 Xcode、XcodeGen、Apple Developer の開発署名を用意する。

```sh
brew install xcodegen
xcodegen generate
open HearStars.xcodeproj
```

Xcode で一意な Bundle ID と自分の Team を選び、登録した試験用 iPhone を実行先にする。これは[屋外実機テスト](08-field-test.md)用の開発ビルドであり、第三者へ IPA として配布しない。

## 一般向け配布を開始できる条件

次をすべて満たすまで、一般向け・商用の配布を開始しない。本人の実機試用用 IPA を作れたことは、出荷条件の合格を意味しない。

1. [受入条件](07-acceptance.md)の数学、UI、プライバシー、安全の事前項目が合格。
2. [屋外実機テスト](08-field-test.md)が合格。
3. [MVP 要件とデータ権利判断](REQUIREMENTS-AND-RIGHTS.md)の権利ブロッカーが 0 件で、出荷対象すべてが商用利用可または書面許諾済み。
4. Bundle ID、署名主体、対象端末、証明書・プロビジョニングの管理者が確定。

通過後に署名付き配布の設定を別レビューで決める。実際に生成した IPA には SHA-256、生成日時、commit、署名方式、最小 iOS、取得先を記録する。存在しない IPA や予定 URL をダウンロード可能とは書かない。

## Sideloadly 確認

Sideloadly は実在する署名可能な IPA ができた後の導入確認にだけ使う。指定実機へ導入し、初回権限、再起動、音、触覚、VoiceOver、方位品質4状態、高度境界、オフライン動作を再確認する。導入可否は署名・端末登録・証明書条件に依存するため、成功前に保証しない。

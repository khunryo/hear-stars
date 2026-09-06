# 09 ローカルビルドと将来の IPA 配布

## 現在地

リポジトリには XcodeGen 用 `project.yml` があるが、Codemagic 設定、署名付き archive、IPA、ダウンロードリンクはない。この文書は順序を固定するもので、ビルド設定を新設するものではない。

## 屋外試験用のローカル実機ビルド

macOS、対応 Xcode、XcodeGen、Apple Developer の開発署名を用意する。

```sh
brew install xcodegen
xcodegen generate
open HearStars.xcodeproj
```

Xcode で一意な Bundle ID と自分の Team を選び、登録した試験用 iPhone を実行先にする。これは[屋外実機テスト](08-field-test.md)用の開発ビルドであり、第三者へ IPA として配布しない。

## 配布工程を開始できる条件

次をすべて満たすまで Codemagic 設定や配布用 IPA を作らない。

1. [受入条件](07-acceptance.md)の数学、UI、プライバシー、安全の事前項目が合格。
2. [屋外実機テスト](08-field-test.md)が合格。
3. [MVP 要件とデータ権利判断](REQUIREMENTS-AND-RIGHTS.md)の権利ブロッカーが 0 件で、出荷対象すべてが商用利用可または書面許諾済み。
4. Bundle ID、署名主体、対象端末、証明書・プロビジョニングの管理者が確定。

通過後に、Codemagic の採否と最小設定を別レビューで決める。実際に生成した IPA には SHA-256、生成日時、commit、署名方式、最小 iOS、取得先を記録する。存在しない IPA や予定 URL をダウンロード可能とは書かない。

## Sideloadly 確認

Sideloadly は実在する署名可能な IPA ができた後の導入確認にだけ使う。指定実機へ導入し、初回権限、再起動、音、触覚、VoiceOver、方位品質4状態、高度境界、オフライン動作を再確認する。導入可否は署名・端末登録・証明書条件に依存するため、成功前に保証しない。

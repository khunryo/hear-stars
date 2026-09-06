# 星を聴く / Hear the Stars

夜空へ iPhone を向け、音・触覚・画面のいずれかで星の方向を探す、通信不要の iPhone アプリです。

このリポジトリは少数星で技術成立性を確かめる Phase 1 プロトタイプです。カメラ画像認識は使わず、端末内の天体計算、現在地、真北方位、端末姿勢を中心にします。

## Phase 1 の対象

- 北極星、シリウス、ベガ、ベテルギウス、リゲル
- 「聴く」「触れる」「見る」を同格にした探索
- 地平線下判定と、昼・曇天向け練習モード
- 方位精度の明示、8 の字補正案内、磁気干渉警告
- 立ち止まる安全確認と、歩行・走行時のガイド停止
- 日本語・英語、VoiceOver、Reduce Motion
- SwiftUI / Core Location / Core Motion / AVAudioEngine / Core Haptics

## 開発状態

Windows 上で、設計、純粋計算コード、アプリコード、XcodeGen 定義を作成しています。現時点では Codemagic 設定、署名付き archive、配布可能な IPA、ダウンロードリンクはありません。まず macOS/Xcode から開発署名した実機ビルドで[屋外実機テスト](docs/08-field-test.md)を行い、精度・安全・権利のゲートを通過した後にだけ、クラウドビルドと配布用 IPA を準備します。屋外検証が終わるまでは「実際の星を発見できる」と断定しません。

## ドキュメント

1. [要件](docs/01-requirements.md)
2. [画面遷移](docs/02-screen-flow.md)
3. [UI コンセプト比較](docs/03-ui-concepts.md)
4. [UI コンセプト詳細](docs/UI-CONCEPTS.md)
5. [天体計算・センサー検証](docs/ASTRONOMY-VALIDATION.md)
   - [IAU SOFA 由来計算の明示](docs/SOFA-NOTICE.md)
6. [MVP 要件とデータ権利判断（出荷権利の正本）](docs/REQUIREMENTS-AND-RIGHTS.md)
7. [受入条件](docs/07-acceptance.md)
8. [屋外実機テスト](docs/08-field-test.md)
9. [ローカルビルドと将来の IPA 配布](docs/09-build-and-sideload.md)

## プロジェクト生成（macOS）

```sh
brew install xcodegen
xcodegen generate
open HearStars.xcodeproj
```

`project.yml` の `PRODUCT_BUNDLE_IDENTIFIER` と Team を、自分の Apple Developer アカウントの値に変更してから、Xcode の開発署名で試験用 iPhone へインストールします。配布用 archive/IPA の手順とは分けてください。

## プライバシー

通信、ログイン、広告、外部解析 SDK はありません。位置情報とモーション情報は端末内の現在セッションだけで使用し、保存・送信しません。

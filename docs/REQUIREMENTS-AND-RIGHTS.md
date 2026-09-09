# 「星を聴く」要件・受入条件・データ権利方針

- 文書版: 0.1（技術検証開始用）
- 基準日: 2026-09-06
- 対象: iPhone アプリ「星を聴く」だけ
- 作業境界: `C:\dev\fishing\hear-stars`
- 状態: MVP 技術検証の基準。屋外実機ゲートを通過するまで、星数・星座数・カメラ機能を拡張しない。

この文書は製品判断のための権利調査であり、個別法域における法律意見ではない。公開時点で利用条件が変わっていないことを再確認し、不明点は権利者への書面確認または専門家確認で解消する。

## 1. 製品の定義

### 1.1 一文での価値

利用者が安全な場所で立ち止まり、夜空へ iPhone の背面を向けると、選んだ星へ近づくほど立体音が明瞭になり、触覚の間隔が短くなり、方向が合った瞬間に星固有の音・触覚・画面演出で発見を伝える。

### 1.2 中核原則

1. 星の位置は、端末の現在地・日時と恒星の赤経赤緯から端末内で計算する。
2. 真北基準の方位は Core Location、三次元姿勢は Core Motion から得て照合する。
3. 暗所の画像認識を成立条件にしない。カメラ表示は、計算・センサー方式を補う任意モードに限る。
4. 「音あり」「触覚のみ」「画面ガイド」を同格に扱い、どれか一つだけでも探索を完了できるようにする。
5. 暗順応を妨げにくい全画面 UI とし、主要導線に不要な縦スクロールを入れない。
6. 正確さを過大に表現しない。端末コンパスは精密測量・安全誘導・緊急用途には使えないことを常に前提にする。
7. 通信、アカウント、広告、外部解析 SDK、バックグラウンド位置追跡を持たない。

### 1.3 成功の定義

初期成功は「星表を多く収録したこと」ではなく、少数の明るい星について、屋外の安全な開けた場所で利用者が実際の星へ端末を向け、誤発見を抑えながら発見フィードバックまで到達できることとする。

## 2. MVP の範囲

### 2.1 技術検証版 P0 に含めるもの

- iPhone、縦向き、前景動作を基準とする。対応 iOS バージョンは実装開始時に Xcode/Codemagic の利用可能 SDK と合わせて確定する。
- 必須対象は北極星（Polaris）とシリウス（Sirius）。季節差の検証用として最大 2 星（候補: ベガ、アークトゥルス）を追加できるが、P0 は合計 2〜4 星に留める。
- 星の選択、探索前チェック、探索、発見、練習、設定、安全説明、データ出典・ライセンス表示。
- 現在地・UTC 日時・恒星座標からの方位角/高度計算。
- Core Location の真方位と精度、Core Motion の姿勢、端末表示方向を考慮した指向ベクトル。
- 目標方向と端末方向の三次元角距離。
- 距離に応じて単調に変化する音、触覚、画面ガイド。
- 8 の字補正を含むコンパス再調整案内、地平線下判定、低高度警告。
- 昼間・曇天でも計算上の方向を探せる「練習」表示。実物を視認した、という表現はしない。
- 位置情報を許可しない場合にも使える、端末相対の合成ターゲット練習。
- 日本語・英語、VoiceOver、Dynamic Type、Reduce Motion。
- すべての効果音、触覚パターン、軌跡、波紋、発見演出を本アプリ用に新規制作する。

### 2.2 屋外実機ゲート通過後の MVP 候補

- 権利確認済みの明るい星を段階的に追加する。
- 3〜5 星程度を順番に発見する、短い「星座をたどる」体験を 1 件だけ追加する。
- 星座線は本アプリ独自の接続グラフと造形を使用する。
- センサー計算で投影した星点・独自星座線をカメラ映像に重ねる補助モードを追加する。
- カメラや AR の追跡品質が低いときは、直ちにセンサー中心の探索へ戻せるようにする。

### 2.3 MVP の非対象

- 全天の高密度星図、何千・何万件もの恒星カタログ。
- 惑星、月、太陽、人工衛星、流星、深宇宙天体の案内。
- カメラ画像から星・星座を必須認識する機械学習機能。
- カメラ映像、写真、位置履歴、センサーログの保存または送信。
- マイク入力、音声録音、写真ライブラリへの保存。
- ログイン、クラウド同期、共有、ランキング、広告、課金、外部解析 SDK。
- バックグラウンド位置情報、ジオフェンス、常時追跡。
- 歩行ナビゲーション、車載利用、精密方位計、緊急・救難・航法用途。
- Apple Watch、iPad、Android。
- Apple から明示的に求められていない審査動画。

## 3. 主要画面と遷移

```text
初回起動
  └─ 安全説明・方式説明
       └─ 星を選ぶ
            ├─ ライブ探索前チェック
            │    ├─ 権限/センサー/可視性 OK → 探す
            │    │                              └─ 発見
            │    │                                   ├─ 別の星
            │    │                                   └─ 星座をたどる（屋外ゲート後）
            │    ├─ 地平線下 → 理由表示 + 練習/別の星
            │    └─ 精度不足 → 補正案内 + 再確認/練習
            └─ 練習 → 計算上または合成ターゲットを探す

任意の画面 → 設定 → 音/触覚/画面、言語、安全、プライバシー、出典
```

### 3.1 画面要件

- **星を選ぶ**: 星名、現在の可視状態、方位の概略だけを表示する。数値情報を主役にしない。
- **探索前チェック**: 周囲が安全で立ち止まっていること、位置/方位/モーションの状態、星が地平線上かを一画面で示す。
- **探す**: 黒に近い夜空、低輝度色、細い軌跡、静かな波紋を中心にし、通常時のテキスト量を最小化する。
- **発見**: 派手なフラッシュを使わず、星固有の短い音・触覚・低輝度の収束演出を同期する。
- **練習**: 「練習」「実際に見えたことを示すものではない」を常時識別できるようにする。
- **星座をたどる**: 一度に一つの次目標だけを提示し、縦長リストを探索中に表示しない。
- **設定/法的表示**: 長文だけはスクロールを許容する。主要探索フローの全画面性を損なわない。

## 4. 機能要件

| ID | 要件 |
|---|---|
| F-01 | 利用者は探索前に対象星を明示的に選ぶ。勝手に別の星へ切り替えない。 |
| F-02 | 各星データは、固有 ID、IAU 名、日英表示名、座標値、座標系、元期/equinox、必要な固有運動、出典、利用条件を持つ。 |
| F-03 | 端末時刻と位置から、選択星の真北基準方位角と幾何学的高度を端末内計算する。 |
| F-04 | 幾何高度が 0°未満ならライブから自動で練習へ切り替え、地平線下であることを説明する。0°以上5°未満は低高度・遮蔽物・大気差の不確実帯として警告し、0°以上2°未満はライブ方向案内を許しても発見させない。ライブ発見は2°以上だけとする。 |
| F-05 | 真方位、方位精度、モーション利用可否、姿勢データ鮮度を探索前と探索中に監視する。 |
| F-06 | 有効方位精度は good（8°以下）、fair（8°超10°以下）、approximate（10°超25°以下）、unavailable（無効値または25°超）に分類する。good/fair は発見可、approximate は粗い案内だけ、unavailable・データ陳腐化・移動中は全方向案内と発見を停止する。磁北値へ無表示で切り替えない。 |
| F-07 | 端末が向く三次元方向と星方向を同じローカル水平座標系の単位ベクトルにし、内積から 0〜180° の角距離を求める。 |
| F-08 | 方位角差は 0/360° 境界をまたいでも最短差になるよう正規化する。高度差だけ、または方位差だけで発見判定しない。 |
| F-09 | 音の明瞭さ、触覚間隔、画面の収束度は、角距離が小さくなるほど単調に近接を示す。センサーの小さな揺れにはヒステリシス/平滑化を入れる。 |
| F-10 | 発見許容角は有効方位精度から `clamp(3 + 精度/3, 3, 6)` 度で求め、good/fair、ライブ幾何高度2°以上、センサー鮮度、静止をすべて満たしたまま許容角内に0.8秒連続した場合だけ一度確定する。瞬間的な1サンプルでは確定しない。練習は高度条件だけを免除できる。 |
| F-11 | 各星は識別可能な独自音と独自触覚を持つ。触覚を利用できない端末では視覚/音へ安全にフォールバックする。 |
| F-12 | 音のみ、触覚のみ、画面のみの各設定で、選択から発見まで完了できる。複数併用も許可する。 |
| F-13 | 昼・曇天練習はライブ天体計算を利用できるが、視認成功とは扱わない。位置拒否時は端末相対の合成ターゲットを提供する。 |
| F-14 | 方位精度が悪い場合、磁性体から離れる説明と 8 の字補正の案内を提示し、補正後の値を再評価する。改善したと断定するのは実測値が改善した場合だけとする。 |
| F-15 | カメラ補助は利用者が明示的に選んだ時だけ開始し、画像認識を必須にせず、撮影・保存・送信をしない。拒否されても中核探索は動く。 |
| F-16 | アプリが非アクティブになった時、探索終了時、画面離脱時に位置・方位・モーション・カメラ更新を停止する。 |
| F-17 | ネットワークが無い状態で、全対象星の選択、計算、探索、練習、出典表示が完了する。 |
| F-18 | 歩行を促す距離・進行ルート・「進んで」等の表現を使わない。「安全な場所で立ち止まる」を探索前に確認する。 |
| F-19 | データ出典、ライセンス、変更内容、非推奨用途をアプリ内から 2 操作以内で確認できる。 |

## 5. 天体計算とセンサーの基準

### 5.1 座標と時刻

- 内部角度は double precision、計算中はラジアン、入出力境界で度数法を使う。
- 恒星レコードごとに ICRS/J2000 等の座標系、equinox と観測元期を明記し、異なる元期の値を混在させない。
- 元データに固有運動がある場合は観測元期から対象日時へ伝播する。固有運動が無い場合はその制限を記録する。
- 少なくとも歳差を扱う。章動、年周光行差、極運動、UT1-UTC、大気差を省略する場合はモデル仕様と誤差上限をテスト資料に固定する。
- MVP の高度は幾何学的高度とする。大気差や地形・建物による実視可否を保証しない。
- 方位角は真北 0°、東 90°、南 180°、西 270° の右回りとする。
- 端末のタイムゾーン表示と天体計算用 UTC を分離する。夏時間や日付またぎでローカル時刻を二重変換しない。

### 5.2 Core Location

Apple は When In Use を可能な限り選ぶよう案内しており、同権限でもアプリ使用中はすべての位置サービスを利用できる。本アプリは `requestWhenInUseAuthorization()` だけを使い、Always 権限とバックグラウンド位置更新を持たない。[Apple: Choosing the Location Services Authorization to Request](https://developer.apple.com/documentation/bundleresources/choosing-the-location-services-authorization-to-request)

- ライブ探索を利用者が選んだ時に初めて位置許可を求める。
- MVP は reduced accuracy を受け入れ、Temporary Full Accuracy を要求しない。天体方向への影響をテストし、許容できない実測結果が出た場合だけ再設計する。
- `trueHeading` は現在位置があって初めて有効になり、負値は無効である。位置更新を有効にし、有効な `trueHeading` だけをライブ発見判定に使う。[Apple: CLHeading.trueHeading](https://developer.apple.com/documentation/corelocation/clheading/trueheading)
- `headingAccuracy` は報告方位の最大偏差を度で示す。負値は無効として破棄する。[Apple: CLHeading](https://developer.apple.com/documentation/corelocation/clheading)
- `headingOrientation` と実際の UI/端末向きを一致させる。P0 で縦向きに固定する場合も、回転ロック状態を含めて試験する。
- Phase 1 の有効方位精度は `good: 0°以上8°以下`、`fair: 8°超10°以下`、`approximate: 10°超25°以下`、`unavailable: 有効値なし、負値または25°超` とする。
- good/fair は発見判定に参加できる。approximate は「おおよその方向を案内しています」と表示して粗い方向案内だけを許し、発見を確定しない。unavailable は音・触覚・画面方向案内と発見をすべて停止し、状態説明と補正/練習への操作だけを残す。
- 真北不明、必要センサー欠落、センサーデータ陳腐化は unavailable 相当とする。歩行・走行・自転車・自動車移動中も方位値にかかわらず全案内と発見を停止する。
- 閾値を屋外試験後に変更する場合は、実装、単体試験、本書、画面遷移、受入条件を同じ変更で更新し、変更理由と結果を記録する。

Apple 自身も、コンパス精度は磁気的・環境的干渉を受け、正確な位置・近接・距離・方向の決定に依存すべきでないと説明している。[Apple Support: Use the compass on iPhone](https://support.apple.com/guide/iphone/use-the-compass-iph1ac0b663/ios)

### 5.3 Core Motion

- `CMMotionManager.isDeviceMotionAvailable` を確認し、利用不可なら中核ライブ探索を開始しない。
- 利用可能な姿勢基準を `availableAttitudeReferenceFrames()` で確認する。Apple はコンパス/ナビゲーション用途に `xMagneticNorthZVertical` または `xTrueNorthZVertical` を案内している。本アプリは真北基準を優先し、Core Location の真方位と照合する。[Apple: Getting processed device-motion data](https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data)
- センサーの座標軸から、「画面を利用者へ向けた状態で背面が指す方向」を明示的に変換する。UI 向きやカメラ光軸を暗黙に仮定しない。
- Core Location と Core Motion が大きく不一致の時は信頼度を下げ、どちらかへ無表示でスナップしない。
- 触覚振動はカメラ、ジャイロ等へ影響し得ると Apple が注意しているため、触覚発生前後の姿勢揺れ、平滑化、最短間隔を実機試験する。[Apple HIG: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)

### 5.4 補正と干渉

- Core Location は初回や磁場の大きな変化時に校正 UI の表示可否を delegate へ問い合わせる。必要時はシステム校正 UI を許可する。[Apple: locationManagerShouldDisplayHeadingCalibration](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/locationmanagershoulddisplayheadingcalibration%28_%3A%29)
- 独自の 8 の字案内は、有効な最新データで精度が unavailable の時に提示する（更新待ちは別表示とし、approximateでは8の字を要求しない）。ゆっくり端末を 8 の字に動かし、その後静止して再判定する手順とする。
- 車内、磁石付きケース/アクセサリ、スピーカー、鉄骨、金属机、送電設備付近から離れるよう案内する。
- 干渉は常に自動検出できるとは限らない。精度表示やセンサー間差分が正常でも誤差が残る可能性を安全説明に残す。

### 5.5 暗所カメラの位置づけ

- カメラはセンサー投影の背景に限り、星画像認識や ARKit のワールド追跡を成功条件にしない。
- ARKit を採用する場合、`limited(.insufficientFeatures)` は「カメラに識別可能な特徴が足りない」状態である。暗い空では起こり得る前提で、表示を弱め、センサー中心モードへの戻り方を示す。[Apple: ARCamera.TrackingState.Reason.insufficientFeatures](https://developer.apple.com/documentation/arkit/arcamera/trackingstate-swift.enum/reason/insufficientfeatures)
- カメラ補助が誤って精密な天体重畳に見えないよう、「目安」「センサー精度に依存」を画面で示す。

## 6. 音・触覚・画面マッピング

以下は Phase 1 実装の帯域契約である。`γ` は三次元角距離、`T = clamp(3 + 有効方位精度/3, 3, 6)` 度は発見許容角とする。屋外試験後に変更する場合も、近づくほど一貫して近接を示す関係は変更しない。

| 三次元角距離 | 音 | 触覚 | 画面 |
|---|---|---|---|
| `γ>45°` | 強くローパスした静かな星音。左右/上下方向は分かるが主張しすぎない。 | 1.50秒間隔。 | 広く薄い波紋、方向のみ。 |
| `20°<γ<=45°` | フィルタを徐々に開き、定位を明瞭にする。 | 0.90秒間隔。 | 軌跡が細く収束する。 |
| `8°<γ<=20°` | 星固有音の特徴が認識できる。 | 0.45秒間隔。 | 波紋中心が明瞭になる。 |
| `T<γ<=8°` | 明瞭な近接音。 | 0.22秒間隔。 | 中央近くへ収束する。 |
| `γ<=T` | good/fair かつ他のゲートを満たす間だけ整合状態。 | 0.12秒間隔。0.8秒継続後は探索パルスを止め、星固有の短い発見パターンを1回。 | 0.8秒継続後に低輝度の収束演出と星名。 |

- 距離値には平滑化を適用し、帯域境界にはヒステリシスを設ける。
- 整合中の最短反復間隔0.12秒は短時間の保持確認に限り、過熱、疲労、センサー振動の実測で長くできる。
- 発見後に連続して音・触覚を鳴らし続けない。再発見には明示的な再開操作を必要とする。
- 背後の目標を単純な左右定位だけで前方に見せない。「後ろ方向」用の音色/触覚/VoiceOver 表現を用意する。
- 音は音量だけで距離を表さず、フィルタ、倍音、ノイズ量等の明瞭さを主に使う。急激な大音量化を避ける。
- 音・触覚は設定から個別に停止できる。Apple は触覚を他のフィードバックと組み合わせ、任意にし、過度に使わないよう案内している。[Apple HIG: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- 効果音は第三者サンプル、他アプリの音源、IAU サイトの音楽を使わず、ソースとなる合成設定または録音原本と制作者の権利移転記録を保存する。

## 7. 安全要件

### 7.1 必須表示

探索開始前に、短く読み上げ可能な形で次を示す。

- 安全な場所で立ち止まって使用する。
- 道路、階段、崖、水辺、線路、私有地、車両内では使用しない。
- まず周囲を目で確認し、画面を見続けない。
- ヘッドホン利用時も周囲の音を遮断しない。危険がある場所では音を使わない。
- 磁石、車、鉄骨、金属設備の近くでは方向がずれる。
- 本アプリは精密測量、航法、緊急・救難用ではない。
- 星が計算上地平線上でも、雲、建物、地形、光害、昼光により見えないことがある。

### 7.2 動作上の安全

- 探索中に移動距離や歩数を測らず、歩行を促さない。
- デバイスの course（移動方向）を端末の heading（向き）の代用にしない。
- 方位や姿勢が不安定な時は、発見の演出より先に中断を通知する。
- カメラ補助で前方視界が見えていても、安全確認済みとは扱わない。
- 画面点滅、白フラッシュ、急な全画面拡大を使わない。
- 長時間の上向き姿勢を強制せず、一時停止と終了を常に一操作で行えるようにする。

## 8. プライバシーと権限

Apple の定義では、端末内だけで処理しサーバーへ送らないデータは App Store のプライバシー回答上「収集」に当たらない。[Apple: App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) したがって、以下を実装どおり維持できる限り、申告候補は “Data Not Collected” である。ただし最終バイナリとすべての依存関係を検査してから確定する。

| データ/機能 | 方針 | 保存 | 送信 | 権限を求める時点 |
|---|---|---:|---:|---|
| 現在地 | 星の方位/高度と真方位計算だけ。When In Use、reduced accuracy を許容。 | しない | しない | ライブ探索を初めて選んだ直後 |
| 方位 | 目標と端末方向の比較だけ。 | しない | しない | ライブ探索中だけ更新 |
| モーション | 端末姿勢の算出だけ。 | しない | しない | 探索/練習の開始時だけ更新 |
| カメラ | 任意の補助背景だけ。フレームを保存・解析・送信しない。 | しない | しない | 利用者がカメラ補助を選んだ時だけ |
| 選択星/設定 | 端末内の操作継続に必要な最小設定。位置と結びつけない。 | 必要最小限 | しない | 権限不要 |
| 診断 | リリース版に外部ログ、解析、クラッシュ送信を入れない。 | しない | しない | 該当なし |

### 8.1 権限方針

- 位置: `NSLocationWhenInUseUsageDescription` のみ。Always 用キー、Background Modes の Location updates を追加しない。
- モーション: Core Motion 利用を明示する `NSMotionUsageDescription` を日英で用意する。OS/機種により実際の許可 UI が異なる可能性があるため、実機の初回・拒否・再許可を試験する。[Apple: NSMotionUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription)
- カメラ: 補助モードを実装する段階だけ `NSCameraUsageDescription` を追加する。Apple はカメラ API を使うアプリに同キーを必須としている。[Apple: Requesting authorization to capture media](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- マイク、写真、トラッキング、Bluetooth、連絡先等の不要な purpose key と entitlement を入れない。
- 権限を拒否してもクラッシュ、空白画面、繰り返し要求にならない。星の閲覧と合成ターゲット練習は利用できる。
- カメラ拒否時は設定へ強制誘導せず、「カメラなしで続ける」を主要操作にする。

Apple は、必要なデータだけを、必要な機能を利用者が選んだ文脈で要求し、可能なら端末内処理することを案内している。[Apple HIG: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy) App Review Guidelines 5.1.1 は明確な purpose string、データ最小化、権限選択の尊重を求め、5.1.5 は位置利用が機能へ直接関係することと目的説明を求める。[Apple: App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### 8.2 purpose string 草案

`InfoPlist.strings` で完全にローカライズし、実装と異なる表現にしない。

| Key | 日本語 | English |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | 現在地と日時から、選んだ星の空の方向をこの iPhone 内で計算するために使用します。位置情報は送信・保存しません。 | Your location is used on this iPhone to calculate where the selected star is in the sky. It isn’t transmitted or stored. |
| `NSMotionUsageDescription` | iPhone が空のどちらを向いているかを判定し、選んだ星の方向を案内するために使用します。モーション情報は送信・保存しません。 | Motion data is used to determine where your iPhone is pointing and guide you toward the selected star. It isn’t transmitted or stored. |
| `NSCameraUsageDescription` | 任意のカメラガイドに星と独自の星座線の目安を重ねるために使用します。映像は撮影・保存・送信しません。 | The optional camera guide uses the camera to overlay approximate star positions and original constellation lines. Video isn’t recorded, stored, or transmitted. |

### 8.3 App Store 出荷時の確認

- 全アプリに求められるプライバシーポリシー URL を App Store Connect とアプリ内へ掲載する。ポリシーには「収集なし」、端末内処理、保存なし、権限解除方法を明記する。[Apple: App Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/)
- Xcode の Privacy Report と最終 IPA の依存関係/通信を確認し、App Privacy 回答と一致させる。
- Required Reason API を利用する場合は、実際の理由を `PrivacyInfo.xcprivacy` に記載する。Apple は未申告の Required Reason API を含む提出を受け付けない。[Apple: Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- Phase 1 はセンサー更新間隔の経過時間だけを測るため `ProcessInfo.systemUptime` を使い、`NSPrivacyAccessedAPICategorySystemBootTime` の理由 `35F9.1` を宣言する。この値や派生値は保存・送信しない。
- `UserDefaults` を設定保存に使う場合は、Apple が示す app-only の理由コード等、提出時点の現行一覧を再確認する。推測した理由コードをコピーしない。
- 機内モードと通信監視下で、アプリ自身から外部ドメインへの要求がないことを確認する。

## 9. ローカライズ要件

- 対応言語は日本語と英語。キー欠落時は英語へフォールバックし、画面にキー文字列を露出しない。
- UI、VoiceOver、通知的アナウンス、安全説明、エラー、権限前説明、`InfoPlist.strings`、出典・ライセンスを両言語化する。
- IAU 固有名の標準綴りは改変せず保持し、日本語 UI には一般的な日本語名またはカタカナ表記を別フィールドで持つ。
- 日本語の説明文は本アプリ用に執筆し、第三者の星解説を翻訳転載しない。
- 方位、角度、時刻、単位は `Locale` を考慮する。VoiceOver では `123°` の記号読み任せにせず、意味のある読み上げ文を用意する。
- 星名の発音は日英で実機確認し、必要なら表示名とアクセシビリティ読みを分離する。
- レイアウトは英語の長い文字列、最大 Dynamic Type、日英切替後の切れ/重なりを許さない。

## 10. アクセシビリティ要件

### 10.1 同格の三モード

- **音あり**: 三次元定位と明瞭さで探索できる。重要状態は触覚/画面にも同時提示できる。
- **触覚のみ**: 消音・聴覚特性にかかわらず、パルス間隔と固有パターンだけで探索・発見できる。
- **画面ガイド**: 音や触覚を使わなくても、方向、距離帯、精度状態、発見を認識できる。色だけに依存しない。

Apple は音の手掛かりを触覚と組み合わせ、音による方向案内には視覚表示も加えるよう案内している。[Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

### 10.2 VoiceOver

- 全操作要素に、内容、値、状態、ヒントを付ける。装飾波紋は読み上げ対象から外す。
- 星カードは「星名、地平線上/下、探索可能状態」を一つの理解可能な要素として読む。
- 探索画面には、選択星、現在の方向指示、距離帯、センサー精度、停止ボタンを論理順で置く。
- 連続更新を毎フレーム読み上げない。距離帯が変わった時の節度ある通知と、利用者が任意に押せる「現在の方向を読む」操作を提供する。
- 発見時は音だけでなく Accessibility announcement と触覚/画面状態を同期する。
- 標準コントロールを優先し、独自描画には `accessibilityLabel`、`accessibilityValue`、必要な action を付ける。[Apple: SwiftUI accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)

### 10.3 動き・視認性・操作

- `accessibilityReduceMotion` を監視し、有効時は軌跡移動、回転、ズーム、奥行き移動、反復波紋を停止またはクロスフェード/静止表示へ置換する。[Apple: EnvironmentValues.accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues)
- 発見演出は点滅せず、Reduce Motion 時にも情報量を失わない。
- 暗順応向け低輝度テーマと、読みやすさを上げる高視認モードを両立する。重要情報は色相差だけでなく形、線、ラベルでも示す。
- 本文と操作ラベルは Dynamic Type に対応する。最大サイズ時に探索の停止操作が画面外へ出ない。
- 主要タップ領域は 44×44 pt を標準とし、少なくとも Apple が示す iOS 最小 28×28 pt を下回らない。[Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- VoiceOver、Switch Control、音なし、触覚なし、Reduce Motion、Increase Contrast、Differentiate Without Color を組み合わせて試験する。

## 11. 受入条件

### 11.1 計算

| ID | 合格条件 |
|---|---|
| A-CALC-01 | 2〜4 星 × 2 地点以上 × 3 日時以上、合計 24 ケース以上の固定テストベクトルを用意する。季節、日付またぎ、0/360°近傍、地平線上下を含む。 |
| A-CALC-02 | 同じ座標モデル/大気差条件の独立した一次資料準拠計算との方位角・高度差が、地平線から 5°以上で各 0.25°以内。参照値、生成日、ツール/式、入力を保存する。 |
| A-CALC-03 | 方位 359° と 1° の差を 2° とし、180°超の誤った差を返さない。 |
| A-CALC-04 | 既知の同一ベクトルで角距離 0°、反対ベクトルで 180°、直交で 90°を 0.001°以内で返す。 |
| A-CALC-05 | 幾何高度0°未満で自動練習へ切替、0°以上5°未満で低高度警告、0°以上2°未満でライブ発見不可、2°境界でライブ発見可、5°境界で警告解除を再現する。0〜5°の境界結果は通常の屋外成功率へ混ぜない。 |
| A-CALC-06 | 端末タイムゾーンを変更しても、同じ UTC と位置への計算結果が変わらない。 |

### 11.2 センサーとフィードバック

| ID | 合格条件 |
|---|---|
| A-SEN-01 | 有効方位精度の境界値と直前直後を注入し、`<=8° good`、`>8°..<=10° fair`、`>10°..<=25° approximate`、無効値/`>25° unavailable` となる。unavailable、モーション利用不可、データ停止/陳腐化では全方向案内と発見を停止する。 |
| A-SEN-02 | 8 の字補正案内の前後値を再取得し、good/fairへ改善時だけ通常探索へ戻る。改善しない場合は粗い案内または安全な移動/練習を案内する。 |
| A-SEN-03 | 磁石付きケース、金属机、車内または鉄骨付近の少なくとも 2 条件で挙動を観察し、approximate/unavailable時に警告し、制限説明へ到達できる。自動検出できなかった干渉も試験記録へ残す。 |
| A-SEN-04 | 角距離を 90°から 0°へ単調に減らす合成入力で、音の明瞭さ、触覚間隔、画面収束度が逆行しない。 |
| A-SEN-05 | 許容角が有効方位精度に応じて3〜6°となる境界を検証する。good/fair、ライブ高度2°以上、静止、データ新鮮の全条件下でも0.8秒未満の通過では発見せず、許容角内で0.8秒連続した場合だけ一度発見する。approximate/unavailableでは一致しても発見しない。 |
| A-SEN-06 | 最短間隔の触覚を 2 分使用しても、発見判定が振動起因で連続誤作動せず、端末温度/快適性に明らかな問題がない。 |
| A-SEN-07 | 音のみ、触覚のみ、画面のみで、合成ターゲットの選択から発見まで各 3 回連続で完了する。 |

### 11.3 権限・プライバシー

| ID | 合格条件 |
|---|---|
| A-PRV-01 | 初回起動だけでは位置・カメラ許可を要求しない。該当機能を選んだ文脈で一度だけ要求する。 |
| A-PRV-02 | 位置の Allow Once/When In Use/拒否/reduced accuracy、カメラの許可/拒否、モーションの利用可/不可でクラッシュしない。 |
| A-PRV-03 | カメラ拒否後もセンサー中心ライブ探索、位置拒否後も合成ターゲット練習を完了できる。 |
| A-PRV-04 | アプリを背景化または探索終了後、位置・方位・モーション・カメラ更新が停止する。 |
| A-PRV-05 | 機内モードで全機能が動き、通信監視でアプリ起因の外向き接続がない。 |
| A-PRV-06 | 最終 IPA に広告、解析、ログイン、外部クラッシュ送信 SDK がなく、App Privacy 回答、privacy manifest、purpose string、プライバシーポリシーが実装と一致する。 |

### 11.4 UI・ローカライズ・アクセシビリティ

| ID | 合格条件 |
|---|---|
| A-UI-01 | 実装前に「暗闇の中の聴覚星図」を満たす最低 2 案を、主要 5 状態（選択、探索前、遠い、近い、発見）で比較し、採否理由を記録する。 |
| A-UI-02 | 主要フローは全画面中心で、星を選ぶ→探す→発見に不要な縦スクロールがない。 |
| A-UI-03 | 日英すべての画面と purpose string に欠落、切れ、重なり、未翻訳キーがない。 |
| A-UI-04 | VoiceOver だけで星選択、探索状態確認、一時停止、発見、終了、設定変更ができる。連続値が読み上げを占有しない。 |
| A-UI-05 | 最大 Dynamic Type でも停止/戻る操作が到達可能で、Accessibility Inspector に重大なラベル/操作問題がない。 |
| A-UI-06 | Reduce Motion で反復波紋、ズーム、回転、奥行き移動が停止/置換され、発見情報は保持される。 |
| A-UI-07 | 音なし、触覚なし、画面を見ない利用の各ケースに等価な主要フィードバックがある。 |

### 11.5 屋外実機ゲート

安全な開けた場所で静止し、磁性体から可能な限り離れて実施する。リリース版へ診断ログ機能を残さず、検証担当者が日時、場所の粗い地域、端末機種、OS、星、方位精度、成否、所要時間を別の検証記録へ手動記入する。

| ID | 合格条件 |
|---|---|
| A-FIELD-01 | 別日に 2 セッション以上。北極星と、当日高度 15°以上のシリウスまたは別の検証星を用いる。 |
| A-FIELD-02 | 2 星 × 各 4 回以上、計 8 回以上の探索で、60 秒以内の発見が 6/8 回以上。失敗理由を精度、遮蔽物、UI、計算、操作へ分類する。 |
| A-FIELD-03 | 実星から意図的に 20°以上外した状態を 8 回以上保持し、誤った発見が 0 回。 |
| A-FIELD-04 | 星へ目視で合わせた時のアプリ角距離の中央値が 10°以下、80 パーセンタイルが 15°以下。達しない場合、星数を増やさずセンサー/校正/UIを修正する。 |
| A-FIELD-05 | good/fairだけで発見を確定する。approximateでは粗い案内を継続でき、unavailableでは全方向案内を停止して補正/練習へ移れる。 |
| A-FIELD-06 | 昼または曇天で練習を 3 回完了し、すべての画面・読み上げが「練習」であることを誤認させない。 |
| A-FIELD-07 | 0°未満、0°、2°直前/境界、5°直前/境界の人工または時間変化ケースで、自動練習、低高度警告、ライブ発見可否が仕様通り。2°以上5°未満の実空結果を通常成功率から分離して記録する。 |

このゲートを通るまで、星・星座の追加、カメラ補助、ストア用素材制作を行わない。

## 12. 段階ゲート

| Gate | 完了物 | 通過条件 | 通過前にしないこと |
|---|---|---|---|
| G0 要件・権利 | 本書、画面遷移、データ台帳様式 | P0 星数、非対象、安全、権限、受入条件を合意。各 P0 星に商用利用可能な出典候補がある。 | 本実装、第三者素材取り込み |
| G1 天体計算 | 座標変換仕様、固定テストベクトル、単体テスト | A-CALC 全件合格 | センサー UX の精緻化 |
| G2 センサー/練習 | 真方位・姿勢照合、角距離、合成練習、精度 UI | A-SEN-01〜05 と地平線判定合格 | 星数追加 |
| G3 UI 比較 | 最低 2 案のデザインプロトタイプと比較記録 | A-UI-01、日英/VoiceOver/Reduce Motion の設計レビュー合格 | 一案へ全面実装 |
| G4 屋外実機 | Xcode開発署名の実機ビルド、手動検証記録 | A-FIELD 全件合格 | Codemagic設定、配布用IPA、星座、カメラ補助、収録星拡大 |
| G5 星/星座拡張 | 権利確認済み星データ、独自星座線 1 件 | 追加行ごとの provenance と権利レビュー、三モード試験合格 | 大規模星表投入 |
| G6 カメラ補助 | 任意カメラ画面、拒否/暗所フォールバック | カメラ権限、AR limited、暗所、センサーのみ復帰を実機確認 | カメラを中核機能と表現 |
| G7 リリース品質 | 日英、全アクセシビリティ、privacy/rights 表示、テスト一式、最終データ台帳 | 11章の対象全件、出荷対象全行が商用利用可/書面許諾済み、権利ブロッカー 0 件 | 外部配布、配布用IPA |
| G8 配布検証 | G4/G7通過後に作るCodemagic署名IPA、実在する具体的ダウンロードリンク、チェックサム | リンクから取得でき、Sideloadlyで対象実機へ導入・起動・権限・探索を確認 | App Store申請、存在しないIPA/URLの告知 |
| G9 App Store | メタデータ、スクリーンショット、プライバシー回答、審査メモ | 最終 IPA と申告一致。審査動画は Apple が明示要求した場合だけ制作 | 未要求の審査動画制作 |

G8 は G4 と G7 の両方を通過するまで開始しない。したがって、屋外実機試験前に Codemagic 設定や配布用 IPA を作らず、権利ブロッカーが残るビルドをテスト担当外へ配布しない。

## 13. 恒星データ・固有名・星座線の権利判断

### 13.1 表記

- **事実**: 権利者または配布主体の一次資料に明記された内容。
- **判断**: 本プロジェクトでの採用可否。法的保証ではない。
- **推奨**: リスクを下げ、後から再検証できる運用。
- **ブロッカー**: 解消するまで商用バイナリへ同梱しない条件。

### 13.2 候補と判断

| 対象 | 一次資料と事実 | 商用判断 | 本プロジェクトの推奨 |
|---|---|---|---|
| Gaia DR3 の Gaia 由来恒星データ | ESA/Gaia/DPAC の公式 DR3 文書は、Gaia データを「open and free to use」とし、`ESA/Gaia/DPAC` のクレジットを条件にしている。ただし同ページには CC 等の名前付きライセンスや「commercial」の明記がない。[Gaia DR3: Credit and citation instructions](https://gea.esac.esa.int/archive/documentation/GDR3/Miscellaneous/sec_credit_and_citation_instructions/) | **条件付き採用候補**。非商用限定とは書かれていないが、名前付き許諾がないため商用再配布の確実性は CC BY より弱い。Gaia Archive 内の外部カタログまで同じ条件とはみなさない。 | `gaiadr3.gaia_source` 等の Gaia 由来表だけを使い、ADQL、source_id、列、取得日、文書版、チェックサムを保存する。アプリ内へ規定クレジットを表示する。出荷前に条件ページを保存し、必要なら Gaia Helpdesk から商用バイナリ内の少数行再配布について書面確認を得る。明るすぎる星の欠落/品質も行単位で確認する。 |
| IAU の恒星固有名 | IAU Working Group on Star Names が IAU Catalog of Star Names を維持し、国際的な標準綴りを扱う。[IAU WGSN](https://www.iau.org/WG280/WG280/Home.aspx) IAU 公式サイトの web texts は CC BY 4.0 で、明瞭なクレジット、非推奨/非支持の扱い、ロゴ除外が条件。[IAU Public Licensing Policy](https://www.iau.org/IAU/IAU/Copyright.aspx) CC BY 4.0 は帰属等を守れば商用利用を許す。[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | **IAU-hosted の表/本文は採用可**。外部大学や個人サイトに置かれた mirror/download は、同じライセンスと自動的にみなさない。 | P0 の少数名だけを IAU-hosted の現行表/発表から手動で抽出し、取得日と元 URL を保存する。標準綴りを保持し、日本語表記を独自フィールドで追加する。クレジットに IAU WGSN、CC BY 4.0、変更内容、非支持を記す。IAU ロゴは使わない。 |
| IAU ページ上の座標値 | IAU の星名表/発表に座標値が含まれ、かつ IAU-hosted web text として配布される版は、上記 IAU 公開ライセンスの対象候補となる。一方、リンク先の外部ファイルや元カタログには別条件があり得る。 | **少数 P0 行の候補**。具体的な取得元が `iau.org` であることと、当該ページに個別例外がないことを保存時に確認する。 | Gaia で扱えない極端に明るい星は、IAU-hosted 座標または別の明示的商用許諾データを行単位で採用する。出典が曖昧なコピーは使わない。 |
| Hipparcos/Tycho | ESA 公式ページは Hipparcos/Tycho Catalogues を **CC BY-NC 3.0 IGO** で配布し、`Credit: ESA` を求める。[ESA: Hipparcos and Tycho Catalogues](https://www.cosmos.esa.int/web/hipparcos/catalogues) `NC` は非商用条件。 | **商用 App Store 版へは不採用**。閲覧・検証に使えることと、データ行を商用バイナリへ再配布できることは別。 | テスト参照に使った場合も出典を記録する。実データは同梱しない。必要なら ESA から別途商用許諾を書面取得し、その範囲を台帳へ添付する。VizieR/別ミラー経由でも原ライセンスは変わらない。 |
| NASA Open Data の SAO Star Catalog | NASA Open Data のデータセットメタデータは `license: https://www.usa.gov/government-works` とし、NASA HEASARC が SAO カタログの電子版を提供している。[NASA Open Data: SAO Star Catalog](https://data.nasa.gov/dataset/smithsonian-astrophysical-observatory-star-catalog) 一方、説明上は Smithsonian/ADC/CDS を経た派生データである。 | **予備候補、要個別確認**。政府著作物メタデータは商用面で有利だが、派生元すべての権利と科学的鮮度を一つのメタデータだけで断定しない。 | Gaia/IAU で P0 星を賄えない場合だけ、NASA HEASARC に当該行の再配布範囲を確認する。古い座標は元期・固有運動・精度を評価し、現代方位計算へ無検証で使わない。 |
| 星座名・3文字略号 | IAU は 88 星座とその領域/名称を標準化しており、公式 FAQ から星座情報へ案内している。[IAU FAQ](https://www.iau.org/IAU/IAU/Astronomy-FAQs/FAQs.aspx) IAU web texts の CC BY 4.0 方針が適用される。 | **採用可**。帰属と変更表示を行う。 | 必要な星座名/略号だけを採用し、独自説明文を作る。文化由来の説明をコピーしない。 |
| 星座線 | IAU の公式教育資料は、IAU が星座を座標境界で定義し、線のパターンでは定義せず、同じ星座に複数の表現があると説明している。[IAU astroEDU: Make a Star Lantern, p.3](https://astroedu.iau.org/documents/779/astroedu-1613-en.pdf) | **第三者線データは不採用**。Stellarium、既存アプリ、市販星図、Web 画像の接続順・造形をコピーしない。IAU 公認線であるかのように表現しない。 | 権利確認済み星 ID を頂点に、本アプリの目的（聴覚で順にたどりやすいこと）から接続グラフを新規設計する。作者、作成日、設計根拠、差分履歴を保存し、「星座線は本アプリ独自のガイド」と表示する。 |
| IAU の星座境界 | IAU が標準化した境界は星座線とは別。MVP の星探し/短いトレースには境界ポリゴンを必要としない。 | **MVP 不使用**。将来利用時は数値境界データの配布元と個別ライセンスを改めて確認する。 | 境界を使わず、星と独自接続線だけで構成する。 |
| 効果音・触覚・星図ビジュアル | IAU の公開ライセンスはサイト上の音楽を CC BY 4.0 の対象外としている。[IAU Public Licensing Policy](https://www.iau.org/IAU/IAU/Copyright.aspx) | **第三者素材を流用しない**。 | 音は独自合成または権利処理済み新規録音、触覚は独自パラメータ、波紋/軌跡/星点は独自描画とする。制作ソースと権利者を台帳化する。 |

### 13.3 現時点の採用方針

1. **固有名**: IAU WGSN の IAU-hosted 資料を正本とし、CC BY 4.0 の帰属を行う。
2. **座標**: まず Gaia DR3 の Gaia 由来表で対象行と品質を確認する。対象の極端に明るい星がない/不適切なら、IAU-hosted の座標値または明示的に商用利用可能な一次データへ切り替える。
3. **Hipparcos/Tycho**: 別許諾がない限り、商用バイナリのデータ元にしない。
4. **星座線**: 公開データを探して移植するのではなく、屋外ゲート後にゼロから設計する。
5. **説明文・和名**: 標準固有名以外の説明は本アプリ用に執筆する。専門的な文化名を追加する場合は、その文化的使用条件も個別確認する。

### 13.4 必須クレジット草案

実際に採用したものだけを表示し、未使用データのクレジットは載せない。

**IAU 固有名を使う場合**

> Star proper names are based on material maintained by the International Astronomical Union Working Group on Star Names, licensed under CC BY 4.0. This app uses a selected subset and adds Japanese display labels. The IAU does not endorse this app.

日本語表示:

> 恒星の固有名は国際天文学連合（IAU）Working Group on Star Names が管理する資料を基にしています（CC BY 4.0）。本アプリは一部を選択し、日本語表示名を追加しています。IAU は本アプリを推奨・承認するものではありません。

**Gaia DR3 を使う場合**

公式文書が求める全文クレジットを英語のまま「出典とライセンス」に掲載する:

> This work has made use of data from the European Space Agency (ESA) mission Gaia (https://www.cosmos.esa.int/gaia), processed by the Gaia Data Processing and Analysis Consortium (DPAC, https://www.cosmos.esa.int/web/gaia/dpac/consortium). Funding for the DPAC has been provided by national institutions, in particular the institutions participating in the Gaia Multilateral Agreement.

加えて、最終採用データに応じて Gaia mission paper と DR3 release paper を記載する。[Gaia DR3 credit instructions](https://gea.esac.esa.int/archive/documentation/GDR3/Miscellaneous/sec_credit_and_citation_instructions/)

### 13.5 データ/素材台帳

各星、各文字列群、各音、各図形について、最低限次を記録する。

| 項目 | 内容 |
|---|---|
| internal_id | アプリ内で不変の ID |
| asset_or_record | 星データ、名称、星座線、音、触覚、画像等 |
| source_owner | ESA/Gaia/DPAC、IAU WGSN、アプリ制作者等 |
| source_url | 実際に取得した一次 URL。ミラーだけで済ませない |
| source_version | DR3、表の版、ページ更新日等 |
| retrieved_at | UTC 取得日時 |
| exact_fields | RA、Dec、proper motion、name 等、採用した列だけ |
| query_or_method | ADQL、手動抽出、独自作図、合成設定等 |
| license | 正式名称と URL。曖昧な “free” だけで終わらせない |
| commercial_status | yes / no / conditional / written permission |
| attribution | アプリに表示する完全な文面 |
| modifications | 元期伝播、丸め、和名追加、線接続等 |
| checksum | ダウンロード原本/生成原本の SHA-256 |
| evidence | 条件ページの PDF/スクリーンショットまたは書面許可の保管先 |
| reviewer/date | 権利確認者と確認日 |

### 13.6 権利リリースブロッカー

出荷可と判定できるのは、最終バイナリ内の各データ/素材行が `commercial_status = yes` または利用範囲を明記した `written permission` で、必要な帰属・変更表示・証拠が揃う場合だけである。`conditional`、不明、非商用限定は「たぶん使える」ではなく出荷不可として扱う。

次のいずれかが残る場合、G7を通過させず、G8の配布用IPA作成、外部配布、G9のApp Store申請を開始しない。

- P0/リリース対象星の座標または固有名に `commercial_status = conditional` のままの行がある。
- Gaia の条件を根拠に再配布するのに、条件ページの保存、必要なクレジット、取得クエリ、取得日がない。
- `iau.org` 外の IAU-CSN mirror を、IAU の CC BY 4.0 と同一と推測しただけで使用している。
- Hipparcos/Tycho 由来行を、CC BY-NC のまま商用バイナリへ入れている。
- 星座線が第三者の接続グラフ/スクリーンショットからトレースされている、または独自制作記録がない。
- 効果音に出所不明サンプル、生成サービスの商用条件未確認素材、他アプリの模倣音が含まれる。
- アプリ内クレジット、ライセンス URL、変更表示、非支持表示が最終データと一致しない。
- 最終バイナリとデータ/素材台帳のチェックサム照合がなく、レビュー済み行だけが梱包されたと証明できない。

## 14. 公式一次資料一覧

### Apple — 位置・方位・モーション・カメラ・審査

- [Requesting authorization to use location services](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services)
- [Choosing the Location Services Authorization to Request](https://developer.apple.com/documentation/bundleresources/choosing-the-location-services-authorization-to-request)
- [CLLocationManager.requestWhenInUseAuthorization](https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization%28%29)
- [Getting heading and course information](https://developer.apple.com/documentation/corelocation/getting-heading-and-course-information)
- [CLHeading.trueHeading](https://developer.apple.com/documentation/corelocation/clheading/trueheading)
- [CLHeading](https://developer.apple.com/documentation/corelocation/clheading)
- [Heading calibration delegate method](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/locationmanagershoulddisplayheadingcalibration%28_%3A%29)
- [CMAttitudeReferenceFrame](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe)
- [Getting processed device-motion data](https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data)
- [NSMotionUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription)
- [Requesting authorization to capture and save media](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- [NSCameraUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription)
- [AR insufficient features](https://developer.apple.com/documentation/arkit/arcamera/trackingstate-swift.enum/reason/insufficientfeatures)
- [Use the compass on iPhone](https://support.apple.com/guide/iphone/use-the-compass-iph1ac0b663/ios)
- [Human Interface Guidelines — Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)
- [Human Interface Guidelines — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Human Interface Guidelines — Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### 恒星データ・名称・星座・ライセンス

- [Gaia DR3 — Credit and citation instructions](https://gea.esac.esa.int/archive/documentation/GDR3/Miscellaneous/sec_credit_and_citation_instructions/)
- [Gaia ESA Archive](https://gea.esac.esa.int/archive/)
- [IAU Working Group on Star Names](https://www.iau.org/WG280/WG280/Home.aspx)
- [IAU FAQ — official star names and constellations](https://www.iau.org/IAU/IAU/Astronomy-FAQs/FAQs.aspx)
- [IAU Public Licensing Policy](https://www.iau.org/IAU/IAU/Copyright.aspx)
- [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/)
- [IAU astroEDU — constellation boundaries vs. line patterns](https://astroedu.iau.org/documents/779/astroedu-1613-en.pdf)
- [ESA — Hipparcos and Tycho Catalogues license](https://www.cosmos.esa.int/web/hipparcos/catalogues)
- [NASA Open Data — SAO Star Catalog](https://data.nasa.gov/dataset/smithsonian-astrophysical-observatory-star-catalog)

## 15. 次の判断

G0 で直ちに行うのは次の三点である。

1. 北極星・シリウスと追加候補最大 2 星について、Gaia 収録/品質と IAU-hosted 座標の有無を確認し、商用出典を行単位で確定する。
2. 2 案の UI を、音・触覚・画面の各単独利用と安全停止を含む同じ 5 状態で比較する。
3. 固定天体テストベクトルと合成センサー入力を先に作り、計算と誤発見防止を通してから実機 UI を広げる。

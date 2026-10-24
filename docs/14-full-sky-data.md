# Build 8 全天データ — 2026-10-24

## 収録と生成

- 8,406恒星、88星座、743辺。V等級6.5以下を基本に、星座線端点と旧31星を保持。太陽系天体/星座イラスト/境界線は含めない。
- 原資料は `tools/sky-sources/` のgzipスナップショット。`manifest.json` に取得日時、commit固定URL、解凍後SHA256、bytesを保存。再生成は `python tools/import_full_sky.py`（通信なし）。再取得は明示の `--fetch` だけ。
- 生データ全件をチャットには出さない。生成物は `Sources/HearStarsCore/Resources/full-sky.json`、同梱帰属は同フォルダ `SkyDataNotices.txt`。

## 恒星

- Yale Bright Star Catalogue, 5th Revised Edition (Hoffleit & Warren, 1991)。[Bretton WadeのJSON輸出](https://github.com/brettonw/YaleBrightStarCatalog) の `bsc5-orig.json`。commit `abffb3b7223ae37e879b0a3ff5b49ad06aed5576`、MIT全文を同梱。
- 輸出側READMEが「元BSCのフィールド」と明示した版を選択。PPM表、HYG表、Hipparcos/Tycho恒星表は取得/同梱していない。
- J2000 RAh/RAm/RAsを15倍して度へ変換、DE符号/度分秒を変換、Vmagを使用。HR番号をIDとし、名前がある行はBayer/Flamsteed表記を使用。原文の説明文や画像は表示しない。
- 既存31星はJ2000の近傍照合（最大0.03度）で対応するHR行を置き換え、従来ID/名称/位置/固有運動/発見音を保持。同じHRを複数の旧星へ割り当てる場合は生成を停止。
- 新規恒星の固有運動は0近似。歳差・現時刻/場所への変換は既存計算。精密測定を保証しない。過去未来の長期間の精度は未検証。
- [NASA HEASARCのBSC5P説明](https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html) と [NASAデータポータル](https://data.nasa.gov/dataset/bright-star-catalog) も参照。実際に取得した数値の出典は上記の固定輸出であり、NASAから取得したデータと偽らない。

## 星座線と名称

- [Olaf Frohn / d3-celestial](https://github.com/ofrohn/d3-celestial)、commit `7e720a3de062059d4c5400a379146a601d9010e0` の `data/constellations.lines.json` と `data/constellations.json`。
- プロジェクトのBSD-3-Clause全文を同梱。READMEは線/名前をIAUの図、作者による位置/線修正、他言語名をWikipedia由来と記載。BSDの表示だけで原出典の権利まで全て確定したとは扱わない。
- 配布された線形状の端点から最大0.03度以内のYale恒星を球面距離で対応付け、実際の描画座標はYaleから計算。元の座標の恒星表への転載はしない。対応なしなら生成を失敗させる。全端点の対応を確認済み。
- Ser1/Ser2はへび座として統合。2領域があるため線形状が2群でも星座数は88。名前も「へび座 / Serpens」へ統一。
- 星座線はIAUが定義した公式境界線ではない。Build7の「すべて独自に作った線」という説明は今回のデータには適用しない。アプリ内の利用条件へ作者/資料/加工を表示し、IAUの支持を示唆しない。

## 安全と残るゲート

- 星座の案内先は現在の観測値で高度5度以上の最も明るい構成星。単独恒星は既存2度ゲート。地平線下の星/背面の星は投影しない。
- 音/振動と発見の閾値、磁気/重力/更新鮮度/移動の停止条件を変更しない。垂直時の警告問題は未解決。
- 日英、文字サイズ、静止星図、一覧による選択を用意。実機のラベル/タップ/VoiceOver/カメラ画角/センサー停止は要確認。
- 商用出荷は従来通り未許可。MIT/BSD輸出の原資料、IAU由来線、Wikipedia由来翻訳名、旧31星の全権利行のconditional/不明を解消し、署名と実機ゲートを満たすまで本人テスト以外へ配布しない。

## 検証証拠

- 変換テスト6件: 度分秒/負号、極、欠損拒否、0/360度近傍、遠方端点拒否、へび座統合。stub時4失敗→実装後6成功。
- 88星座/多数星/選択/更新間隔のSwiftテストも未実装時の失敗を確認後実装。基礎版40e56f3の標準公開Mac CIで全84件成功、iPhoneビルドと同梱データを使った日英描画成功。
- 最終の全文字タップ範囲テストは、背後の星を選ぶ失敗をCI40046545929で確認後修正。最終UI/Build8の検証はCURRENTとCI記録を参照。
- 全体レビューの重要2点（案内前の選択/戻る、方角に依存しない地平線上の静止星図）は、CI40047566655で7期待失敗→修正f1f6b82/CI40047769360でSwift89件成功。Python6件、iPhoneRelease、日英341項目、IPA内データ/利用条件も成功。ダウンロード・PNG目視・実機操作は未実施。
- 軽微な保留: センサー停止後に手動位置合わせの表示が残る。位置合わせの再確認方法/表示は別途検討し、今回解消したとは扱わない。

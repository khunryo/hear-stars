# Build 7 — 星図データと限界（2026-10-11）

## 由来

- 既存5星は `StarCatalog.swift` と `ASTRONOMY-VALIDATION.md` の出典・固有運動を維持。
- 新規25星の名称、J2000赤経/赤緯（度）、V等級は [IAU WGSN / IAU Catalog of Star Names](https://iauarchive.eso.org/public/themes/naming_stars/) の各同名行。2026-10-11取得。行単位の値は `SkyCatalog.swift` に固定。
- 対象行: Kochab, Pherkad, Yildun, Dubhe, Merak, Phecda, Megrez, Alioth, Mizar, Alkaid, Caph, Schedar, Ruchbah, Segin, Sheliak, Sulafat, Bellatrix, Saiph, Alnitak, Alnilam, Mintaka, Mirzam, Wezen, Adhara, Aludra。
- γ Cas は IAU命名表の承認名ではなく Bayer名を表示。[Wikidata Q13584の構造化データ](https://www.wikidata.org/wiki/Special:EntityData/Q13584.json) の P6257/P6258（度）から取得。等級2.2は可変星の描画重みであり測定値ではない。元データにepoch指定がないため、J2000扱いは未検証の仮定。精密観測用途では使わない。

## 権利・表示

- [IAU公開方針](https://iauarchive.eso.org/copyright/) はウェブテキスト等に CC BY 4.0 を示す。表/旧5星の全権利範囲まで確定とはしない。商用配布前のconditional解消ゲートは維持。
- [Wikidata構造化データはCC0](https://www.wikidata.org/wiki/Wikidata:Licensing)。記事本文・画像・ロゴは使用していない。
- アプリ内「星図の出典」に作成者、資料、取得日、選択/計算/独自線への加工とライセンスリンクを掲載。
- 星座線は本アプリで独自に端点を指定。既存製品の図・イラスト・線データを複製していない。
- こぐま座4星、こと座3星などは意図的に疎なガイド。完全な輪郭やIAU公式の線とは主張しない。

## 計算・実機確認

- 新規26星の固有運動は0の近似。既存歳差/恒星時計算を通し、現在地・時刻の方位高度へ変換する。屈折・光行差等の既存近似も維持。
- 端末背面の前方向と画面上方向をENU座標へ変換。内積による透視投影で傾き/ロールに追従。地平線以下と背面の星は表示しない。
- 任意カメラは背面広角1倍、縦向き90°、aspect-fill。activeFormatの画角と縦横比で切抜きを補正。録画・静止画・マイク・画像認識・送信なし。
- 手動位置合わせは25°以内の回転だけ。姿勢と画面上方向を同じ回転で補正。次の星/再確認/離脱/背景移行/北基準変更で解除。センサー品質や発見判定は変更しない。
- 実機で画角/向き、権限拒否、背景復帰、明るい星での補正、音/振動後の遷移を要確認。カメラ画像に星が写ることは保証しない。
- 2026-10-11ユーザー承認のテスト機能拡張。実機安全ゲート・署名・権利ゲート未通過でストア/商用出荷不可。

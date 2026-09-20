# i-mac-key

iPhoneのブラウザからMacへキー入力を送る、ローカル専用の9マスリモコンです。iPhone用アプリは不要です。

## 使い方

1. Xcodeで`Package.swift`を開くか、ターミナルで`swift run --disable-sandbox`を実行します。
2. Macアプリの「キー入力を許可」を押し、macOSの「システム設定 > プライバシーとセキュリティ > アクセシビリティ」で許可します。
3. iPhoneをMacと同じWi-Fiに接続し、表示されたQRコードをカメラで読み取ります。
4. アプリ上で9セルそれぞれのタップ・長押し（0.5秒）に送るキーを設定します。

初期設定では、中央左が`←`、中央右が`→`です。設定はMacのユーザー設定として保存されます。

## セキュリティと制約

- リモコンのURLには起動ごとに変わる接続トークンを含めます。URLを知らない端末は操作できません。
- 通信は同一ローカルネットワークで完結します。外部サーバーやiPhoneアプリは使いません。
- キー入力にはmacOSのアクセシビリティ権限が必要です。
- この開発版は署名・公証済みの`.app`ではありません。配布する版はDeveloper IDで署名・公証します。

## 検証

```sh
task_cache="$(mktemp -d /private/tmp/i-mac-key-build.XXXXXX)"
CLANG_MODULE_CACHE_PATH="$task_cache" SWIFTPM_MODULECACHE_OVERRIDE="$task_cache" swift build --disable-sandbox
```

# Day 063: 受信メール一覧をExcelに書き出し（Outlook VBA）

Outlookの受信トレイのメールを**新しい順**に読み取り、新しいExcelブックへ「受信日時／差出人／差出人アドレス／件名／未読」を一覧で書き出すマクロです。メールの棚卸しや、対応漏れチェックに使えます。

## 必要なもの
- Microsoft Outlook（デスクトップ版／VBAが使える）
- Microsoft Excel（書き出し先。参照設定は不要）

## 使い方
1. `Alt + F11` でVBE →「ファイル → ファイルのインポート」で `ExportInboxToExcel.bas` を取り込む
2. `Alt + F8` →「ExportInboxToExcel」を実行
3. 新しいExcelが開き、一覧が表示される（保存はExcel側で手動）

## 機能
- 受信トレイ（既定アカウント）を受信日時の新しい順に並べ替えて書き出し
- 件数が多いと重いので、**最新 `MAX_COUNT`（初期300）件まで**に制限
- 会議通知などは除き、メール（`Class = 43`）だけを対象
- 見出し行を太字＋ウィンドウ枠固定、列幅を自動調整
- Exchange内部形式の差出人は、できるだけSMTPアドレスに変換

## 使った技術
- Outlook VBA（GetNamespace / GetDefaultFolder / Items.Sort）
- Excelの遅延バインディング（`CreateObject("Excel.Application")`）

## 学び・ポイント
- 受信トレイは `GetDefaultFolder(6)`（6 = olFolderInbox）で取れる。`Items.Sort "[ReceivedTime]", True` で新しい順に並べ替えできる
- アイテムには会議通知・配信通知なども混ざるので、`item.Class = 43`（olMail）でメールだけに絞ると安全
- 社内メール（Exchange）の `SenderEmailAddress` は `/O=…` という内部形式のことがある。`Sender.GetExchangeUser.PrimarySmtpAddress` で通常のアドレスを取り直せる
- 他アプリ（Excel）は参照設定しなくても `CreateObject` で起動できる。定数（olMailなど）は数値で書けば参照設定不要

## 注意
- メールは**読み取るだけ**で、既読/未読や内容は変更しません。
- 件数が非常に多い受信トレイでは時間がかかります（上限件数を調整してください）。

---
100日100アプリチャレンジ Day 063 / 100

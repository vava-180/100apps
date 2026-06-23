Attribute VB_Name = "ExportInboxToExcel"
Option Explicit

' ============================================================
' 受信メール一覧を Excel に書き出すマクロ（Day 063 / Outlook VBA）
'
' 受信トレイのメールを新しい順に読み取り、新しい Excel ブックへ
' 「受信日時／差出人／差出人アドレス／件名／未読」を一覧で書き出します。
' メールの棚卸しや、対応漏れチェックに使えます。
'
' 仕様:
'   ・対象は受信トレイ（既定アカウント）
'   ・件数が多いと重いので、最新 MAX_COUNT 件までに制限
'   ・Excel が必要（参照設定は不要。CreateObject で起動）
'   ・メール自体は読み取るだけ（既読/未読・内容は変更しない）
'
' 使い方:
'   1) Alt+F11 でVBE → 本ファイルをインポート
'   2) Alt+F8 → ExportInboxToExcel を実行
'   3) 新しい Excel が開き、一覧が表示される（保存は手動で）
' ============================================================

' 書き出す最大件数（多すぎると時間がかかるため上限を設ける）
Private Const MAX_COUNT As Long = 300

Sub ExportInboxToExcel()
    Dim ns As Object               ' NameSpace
    Dim inbox As Object            ' MAPIFolder
    Dim items As Object            ' Items
    Dim mail As Object             ' MailItem ほか
    Dim xlApp As Object            ' Excel.Application
    Dim wb As Object, ws As Object
    Dim r As Long, written As Long
    Dim i As Long

    On Error GoTo CleanFail

    ' 受信トレイを取得（6 = olFolderInbox）
    Set ns = Application.GetNamespace("MAPI")
    Set inbox = ns.GetDefaultFolder(6)
    Set items = inbox.Items
    items.Sort "[ReceivedTime]", True   ' 受信日時の新しい順に並べ替え

    If items.Count = 0 Then
        MsgBox "受信トレイにメールがありません。", vbInformation
        Exit Sub
    End If

    ' Excel を起動して見出しを書く（書き終わるまでは画面を隠して高速化）
    Set xlApp = CreateObject("Excel.Application")
    Set wb = xlApp.Workbooks.Add
    Set ws = wb.Worksheets(1)
    ws.Range("A1").Value = "受信日時"
    ws.Range("B1").Value = "差出人"
    ws.Range("C1").Value = "差出人アドレス"
    ws.Range("D1").Value = "件名"
    ws.Range("E1").Value = "未読"

    ' 1行ずつ書き出す
    r = 2
    written = 0
    For i = 1 To items.Count
        Set mail = items.Item(i)
        ' メール（olMail = 43）だけを対象にする（会議通知などは除く）
        If mail.Class = 43 Then
            ws.Cells(r, 1).Value = mail.ReceivedTime
            ws.Cells(r, 2).Value = mail.SenderName
            ws.Cells(r, 3).Value = GetSenderAddress(mail)
            ws.Cells(r, 4).Value = mail.Subject
            ws.Cells(r, 5).Value = IIf(mail.UnRead, "未読", "")
            r = r + 1
            written = written + 1
            If written >= MAX_COUNT Then Exit For
        End If
    Next i

    ' 見た目を少し整える
    ws.Rows(1).Font.Bold = True
    ws.Columns("A:E").AutoFit
    ' 見出し行（1行目）を固定する。基準セルは A2（その上＝1行目が固定される）
    xlApp.Visible = True
    ws.Range("A2").Select
    xlApp.ActiveWindow.FreezePanes = True

    MsgBox written & " 件を書き出しました（最新順）。" & vbCrLf & _
           "保存は Excel 側で行ってください。", vbInformation, "完了"
    Exit Sub

CleanFail:
    ' 途中でエラーになったら、作りかけの Excel を閉じてメモリに残さない
    On Error Resume Next
    If Not wb Is Nothing Then wb.Close False        ' 保存せず閉じる
    If Not xlApp Is Nothing Then xlApp.Quit
    Set ws = Nothing
    Set wb = Nothing
    Set xlApp = Nothing
    On Error GoTo 0
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 差出人のメールアドレスを取り出す（社内Exchangeでも極力アドレスを得る）。
Private Function GetSenderAddress(ByVal mail As Object) As String
    On Error Resume Next
    Dim addr As String
    addr = mail.SenderEmailAddress
    ' Exchange の内部形式（/O=... ）のときは SMTP アドレスを取り直す
    If InStr(1, addr, "/O=", vbTextCompare) > 0 Then
        addr = mail.Sender.GetExchangeUser.PrimarySmtpAddress
    End If
    GetSenderAddress = addr
    On Error GoTo 0
End Function

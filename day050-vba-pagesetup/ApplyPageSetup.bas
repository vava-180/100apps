Attribute VB_Name = "ApplyPageSetup"
Option Explicit

' ============================================================
' 印刷範囲・ページ設定の一括適用マクロ（Day 050）
'
' ブックの中のすべてのワークシートに、同じ印刷設定をまとめて適用します。
'   - 用紙の向き（縦／横）
'   - 横1ページに収める（はみ出し防止。no なら通常倍率100%に戻す）
'   - 印刷範囲＝各シートの使用範囲（空シートは印刷範囲を解除）
'   - 横方向の中央寄せ
'   - フッターにページ番号（&P=現在ページ / &N=総ページ）
'
' 使い方:
'   1) 設定したいブックを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → ApplyPageSetup を実行
'   4) 用紙の向き・横1ページに収めるか を選ぶ
'
' 注意: 全ワークシートが対象です（グラフシートは対象外）。入力用・設定用シートも変わるので注意。
'       プリンタ設定により、少し時間がかかることがあります。
' ============================================================

Sub ApplyPageSetup()
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim orient As String, fitWideIn As String
    Dim orientation As Long, fitWide As Boolean
    Dim done As Long, failed As Long, skippedProtected As Long
    Dim failReport As String, res As String
    Dim oldScreenUpdating As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set wb = ActiveWorkbook

    orient = Trim$(InputBox("用紙の向きを選んでください。" & vbCrLf & _
                            "  1 = 縦" & vbCrLf & "  2 = 横", "ページ設定", "2"))
    Select Case orient
        Case "1": orientation = xlPortrait
        Case "2": orientation = xlLandscape
        Case Else
            If Len(orient) > 0 Then MsgBox "1 か 2 を入力してください。", vbExclamation
            Exit Sub
    End Select

    ' 横1ページに収めるか（yes/y のときだけ「収める」）
    fitWideIn = LCase$(Trim$(InputBox("横を1ページに収めますか？ (yes/no)", "ページ設定", "yes")))
    fitWide = (fitWideIn = "yes" Or fitWideIn = "y")

    If MsgBox("このブックの全ワークシート（" & wb.Worksheets.Count & " 枚）に印刷設定を適用します。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    ' PageSetupはプリンタと通信して遅くなるので、まとめて通信OFFにして高速化（Excel2010以降）
    On Error Resume Next
    Application.PrintCommunication = False
    On Error GoTo CleanFail

    done = 0: failed = 0: skippedProtected = 0: failReport = ""
    For Each ws In wb.Worksheets
        If ws.ProtectContents Then
            skippedProtected = skippedProtected + 1   ' 保護シートは飛ばす
        Else
            res = ApplyToSheet(ws, orientation, fitWide)
            If Len(res) = 0 Then
                done = done + 1
            Else
                failed = failed + 1
                failReport = failReport & vbCrLf & " - " & ws.Name & ": " & res
            End If
        End If
    Next ws

    On Error Resume Next
    Application.PrintCommunication = True   ' 通信を元に戻す（ここでまとめて適用される）
    On Error GoTo 0

    Application.ScreenUpdating = oldScreenUpdating
    Dim msg As String
    msg = "印刷設定を適用しました。" & vbCrLf & _
          "適用: " & done & " シート / 保護で飛ばした: " & skippedProtected & " シート / 失敗: " & failed & " シート"
    If Len(failReport) > 0 Then msg = msg & vbCrLf & "失敗したシート:" & failReport
    MsgBox msg, vbInformation, "結果"
    Exit Sub

CleanFail:
    On Error Resume Next
    Application.PrintCommunication = True
    On Error GoTo 0
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1つのシートに印刷設定を適用する。成功なら ""、失敗ならエラー内容を返す。
Private Function ApplyToSheet(ws As Worksheet, ByVal orientation As Long, ByVal fitWide As Boolean) As String
    On Error GoTo Failed
    With ws.PageSetup
        .Orientation = orientation
        .CenterHorizontally = True
        If fitWide Then
            .Zoom = False            ' 倍率指定をやめてページ数指定にする
            .FitToPagesWide = 1      ' 横は1ページに収める
            .FitToPagesTall = False  ' 縦は成り行き（複数ページOK）
        Else
            .Zoom = 100              ' 収めない＝通常倍率（過去のフィット設定を解除）
        End If
        .CenterFooter = "&P / &N"    ' &P=現在ページ / &N=総ページ
    End With

    ' 印刷範囲＝使用範囲。データが無いシートは印刷範囲を解除する
    If SheetHasData(ws) Then
        ws.PageSetup.PrintArea = ws.UsedRange.Address
    Else
        ws.PageSetup.PrintArea = ""
    End If

    ApplyToSheet = ""
    Exit Function
Failed:
    ApplyToSheet = Err.Description
End Function


' シートにデータが1つでもあるか
Private Function SheetHasData(ws As Worksheet) As Boolean
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlNext)
    SheetHasData = Not (f Is Nothing)
End Function

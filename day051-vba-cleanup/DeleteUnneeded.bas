Attribute VB_Name = "DeleteUnneeded"
Option Explicit

' ============================================================
' 不要シート・空白行の一括削除マクロ（Day 051）
'
' 次のどちらかをまとめて行います:
'   1) 空のシートを削除（中身が何も無いワークシートを消す）
'   2) アクティブシートの「空白行」を削除（全部の列が空の行を消す）
'
' 安全のための決まり:
'   - 空シート削除では、表示中のシートのうち最低1枚は必ず残します（非表示シートは対象外）
'   - 空白行削除は「行全体」を消します（表の右側に別データがあると一緒に消えるので注意）
'   - どちらも実行前に確認します（元に戻せません）
'
' 使い方:
'   1) ブック（空白行削除のときは対象シート）を開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → DeleteUnneeded を実行
'   4) 1（空シート削除）か 2（空白行削除）を選ぶ
' ============================================================

Sub DeleteUnneeded()
    Dim mode As String

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If

    mode = Trim$(InputBox("どちらをしますか？" & vbCrLf & _
                          "  1 = 空のシートを削除" & vbCrLf & _
                          "  2 = アクティブシートの空白行を削除", "不要なものを削除", "1"))
    Select Case mode
        Case "1": DeleteEmptySheets
        Case "2": DeleteBlankRows
        Case Else
            If Len(mode) > 0 Then MsgBox "1 か 2 を入力してください。", vbExclamation
    End Select
End Sub


' ===== 1) 空のシートを削除 =====
Private Sub DeleteEmptySheets()
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim emptyList As Collection
    Dim visibleCount As Long, deleted As Long
    Dim oldAlerts As Boolean

    Set wb = ActiveWorkbook
    Set emptyList = New Collection

    ' 表示中のシート数と、空の表示シートを数える
    visibleCount = 0
    For Each ws In wb.Worksheets
        If ws.Visible = xlSheetVisible Then
            visibleCount = visibleCount + 1
            If Not SheetHasData(ws) Then emptyList.Add ws
        End If
    Next ws

    If emptyList.Count = 0 Then
        MsgBox "空のシート（表示中）は見つかりませんでした。", vbInformation, "結果"
        Exit Sub
    End If

    ' 全部の表示シートが空だと、1枚も残らなくなる → 1枚は残す
    Dim deletable As Long
    deletable = emptyList.Count
    If deletable >= visibleCount Then deletable = visibleCount - 1
    If deletable <= 0 Then
        MsgBox "すべて空のため、削除すると1枚も残りません。中身を入れるか、手動でご確認ください。", vbExclamation
        Exit Sub
    End If

    If MsgBox("空のシートを " & deletable & " 枚削除します（最低1枚は残します）。よろしいですか？", _
              vbYesNo + vbExclamation, "削除の確認") <> vbYes Then Exit Sub

    oldAlerts = Application.DisplayAlerts
    Application.DisplayAlerts = False
    On Error GoTo CleanFail

    deleted = 0
    Dim i As Long
    For i = 1 To emptyList.Count
        If deleted >= deletable Then Exit For
        emptyList.Item(i).Delete
        deleted = deleted + 1
    Next i

    Application.DisplayAlerts = oldAlerts
    MsgBox "空のシートを削除しました。" & vbCrLf & "削除: " & deleted & " 枚", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.DisplayAlerts = oldAlerts
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' ===== 2) アクティブシートの空白行を削除 =====
Private Sub DeleteBlankRows()
    Dim ws As Worksheet
    Dim lastRow As Long, lastCol As Long, r As Long
    Dim delRange As Range
    Dim removed As Long
    Dim oldScreenUpdating As Boolean

    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    lastRow = SheetLastRow(ws)
    lastCol = SheetLastCol(ws)
    If lastRow < 1 Or lastCol < 1 Then
        MsgBox "データがありません。", vbInformation
        Exit Sub
    End If

    ' 空白行を集める（全列が空の行）
    removed = 0
    For r = 1 To lastRow
        If RowIsBlank(ws, r, lastCol) Then
            removed = removed + 1          ' 件数はここで数える（複数Areaでも正確）
            If delRange Is Nothing Then
                Set delRange = ws.Rows(r)
            Else
                Set delRange = Union(delRange, ws.Rows(r))
            End If
        End If
    Next r

    If delRange Is Nothing Then
        MsgBox "空白行は見つかりませんでした。", vbInformation, "結果"
        Exit Sub
    End If

    If MsgBox(removed & " 行の空白行を【行全体】で削除します。" & vbCrLf & _
              "表の右側に別のデータがある場合は一緒に消えます。よろしいですか？", _
              vbYesNo + vbExclamation, "削除の確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    delRange.Delete Shift:=xlUp   ' まとめて消して行ずれを防ぐ

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "空白行を削除しました。" & vbCrLf & "削除: " & removed & " 行", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' ===== 共通の小道具 =====

Private Function SheetHasData(ws As Worksheet) As Boolean
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlNext, SearchFormat:=False)
    SheetHasData = Not (f Is Nothing)
End Function


Private Function SheetLastRow(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlPrevious, MatchCase:=False, SearchFormat:=False)
    If f Is Nothing Then SheetLastRow = 0 Else SheetLastRow = f.Row
End Function


Private Function SheetLastCol(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByColumns, SearchDirection:=xlPrevious, MatchCase:=False, SearchFormat:=False)
    If f Is Nothing Then SheetLastCol = 0 Else SheetLastCol = f.Column
End Function


' その行が全列とも空か。数式セル（=""含む）・エラー値があれば「空でない」とみなす。
Private Function RowIsBlank(ws As Worksheet, ByVal r As Long, ByVal lastCol As Long) As Boolean
    Dim c As Long, v As Variant
    For c = 1 To lastCol
        If ws.Cells(r, c).HasFormula Then   ' 見た目が空でも数式があれば消さない
            RowIsBlank = False
            Exit Function
        End If
        v = ws.Cells(r, c).Value
        If IsError(v) Then
            RowIsBlank = False
            Exit Function
        End If
        If Len(CStr(v)) > 0 Then
            RowIsBlank = False
            Exit Function
        End If
    Next c
    RowIsBlank = True
End Function

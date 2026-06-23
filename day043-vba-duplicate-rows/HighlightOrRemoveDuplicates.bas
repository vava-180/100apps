Attribute VB_Name = "HighlightOrRemoveDuplicates"
Option Explicit

' ============================================================
' 重複行のハイライト／削除マクロ（Day 043）
'
' いま開いているシートの表（1行目＝見出し、2行目以降＝データ）から、
' 「全部の列が同じ」重複行を見つけて、次のどちらかをします:
'   1) 色を付ける（2件目以降を黄色にする。確認しながら消したいとき向け）
'   2) 削除する（1件目を残して、2件目以降を消す）
'
' しくみ:
'   - 比較する列は「1行目（見出し）の幅」ぶん。各行のその範囲の値をつないだ「キー」を作る
'   - そのキーをDictionaryで既出かを調べる（大文字小文字は区別しない＝"ABC"と"abc"は同じ）
'   - 中身が全部空の行は、重複の対象にしません
'   - 比べるのは「セルの値」です（数値の 1 と 文字の "1" は同じ扱い／表示形式は見ません）
'
' 注意（削除モード）: 重複行は「行全体」を削除します。
'   表の右側に別のデータやメモがある場合は、一緒に消えるのでご注意ください。
'
' 使い方:
'   1) 表のあるシートを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → HighlightOrRemoveDuplicates を実行
'   4) 1（色付け）か 2（削除）を選ぶ
' ============================================================

Sub HighlightOrRemoveDuplicates()
    Dim ws As Worksheet
    Dim lastRow As Long, lastCol As Long, r As Long
    Dim dict As Object
    Dim mode As String
    Dim key As String
    Dim dupCount As Long
    Dim delRange As Range
    Dim oldScreenUpdating As Boolean
    Dim curRow As Long

    ' 前提チェック：通常のワークシートが開いていること
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "表のある通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    lastRow = SheetLastRow(ws)
    lastCol = HeaderLastCol(ws)   ' 比較する列は「見出し行(1行目)の幅」に限定する
    If lastRow < 2 Or lastCol < 1 Then
        MsgBox "1行目に見出し、2行目以降にデータがある表を開いてください。", vbInformation
        Exit Sub
    End If

    ' モードを選んでもらう
    mode = Trim$(InputBox("重複行をどうしますか？" & vbCrLf & _
                          "  1 = 色を付ける（2件目以降を黄色に）" & vbCrLf & _
                          "  2 = 削除する（1件目を残して消す）", "重複行の処理", "1"))
    If mode <> "1" And mode <> "2" Then
        If Len(mode) > 0 Then MsgBox "1 か 2 を入力してください。", vbExclamation
        Exit Sub
    End If

    If mode = "2" Then
        If MsgBox("重複行（2件目以降）を【行全体】で削除します。元に戻せません。" & vbCrLf & _
                  "表の右側に別のデータがある場合は一緒に消えます。よろしいですか？", _
                  vbYesNo + vbQuestion, "削除の確認") <> vbYes Then Exit Sub
    End If

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    ' 大文字小文字を区別しないDictionary（既出キーの記録に使う）
    Set dict = CreateObject("Scripting.Dictionary")
    dict.CompareMode = vbTextCompare

    dupCount = 0
    For r = 2 To lastRow
        curRow = r
        If Not IsRowEmpty(ws, r, lastCol) Then
            key = RowKey(ws, r, lastCol)
            If dict.Exists(key) Then
                dupCount = dupCount + 1
                If mode = "1" Then
                    ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Interior.Color = vbYellow
                Else
                    ' 行ずれを避けるため、削除はまとめてから最後に一度だけ行う
                    If delRange Is Nothing Then
                        Set delRange = ws.Rows(r)
                    Else
                        Set delRange = Union(delRange, ws.Rows(r))
                    End If
                End If
            Else
                dict.Add key, 1
            End If
        End If
    Next r

    If mode = "2" And Not delRange Is Nothing Then
        delRange.Delete Shift:=xlUp   ' まとめて消すことで、上から消したときの行ずれを防ぐ
    End If

    Application.ScreenUpdating = oldScreenUpdating

    If mode = "1" Then
        MsgBox "重複行に色を付けました。" & vbCrLf & "重複（2件目以降）: " & dupCount & " 行", vbInformation, "結果"
    Else
        MsgBox "重複行を削除しました。" & vbCrLf & "削除した行: " & dupCount & " 行", vbInformation, "結果"
    End If
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました（処理中の行: " & curRow & "）。" & vbCrLf & _
           Err.Description, vbCritical, "エラー"
End Sub


' セルの値を安全に文字列にする。エラー値(#N/A など)でも落ちないようにする。
Private Function CellText(ws As Worksheet, r As Long, c As Long) As String
    Dim v As Variant
    v = ws.Cells(r, c).Value
    If IsError(v) Then
        CellText = "#ERR:" & CStr(ws.Cells(r, c).Text)  ' エラー値は通常値と区別する
    Else
        CellText = CStr(v)   ' 空セルは "" になる
    End If
End Function


' 1行分の値をつないだ「キー」を作る。各値の前に「長さ:」を付けて、
' 値の中に区切り文字が入っても別の行と取り違えない（衝突しにくい）ようにする。
Private Function RowKey(ws As Worksheet, r As Long, lastCol As Long) As String
    Dim c As Long, s As String, t As String
    For c = 1 To lastCol
        t = CellText(ws, r, c)
        s = s & Len(t) & ":" & t & Chr$(1)
    Next c
    RowKey = s
End Function


' その行が全列とも空かどうか
Private Function IsRowEmpty(ws As Worksheet, r As Long, lastCol As Long) As Boolean
    Dim c As Long
    For c = 1 To lastCol
        If Len(CellText(ws, r, c)) > 0 Then
            IsRowEmpty = False
            Exit Function
        End If
    Next c
    IsRowEmpty = True
End Function


' シート全体の最終行（どの列にデータがあっても拾う）。空なら 0。
Private Function SheetLastRow(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlPrevious, MatchCase:=False)
    If f Is Nothing Then SheetLastRow = 0 Else SheetLastRow = f.Row
End Function


' 見出し行（1行目）の最終列。比較する列の範囲をここで決める。空なら 0。
Private Function HeaderLastCol(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Rows(1).Find(What:="*", LookIn:=xlValues, LookAt:=xlPart, _
                            SearchOrder:=xlByColumns, SearchDirection:=xlPrevious, MatchCase:=False)
    If f Is Nothing Then HeaderLastCol = 0 Else HeaderLastCol = f.Column
End Function

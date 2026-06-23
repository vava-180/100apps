Attribute VB_Name = "GenerateCalendar"
Option Explicit

' ============================================================
' カレンダー自動生成マクロ（Day 055）
'
' 年と月を指定すると、新しいシートにその月のカレンダーを作ります。
'   - 1行目にタイトル（例: 2026年6月）
'   - 2行目に曜日（日 月 火 水 木 金 土）
'   - 3行目以降に日付を配置（日曜=赤、土曜=青、今日=黄色で強調）
'
' 使い方:
'   1) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   2) Alt+F8 → GenerateCalendar を実行
'   3) 年・月を入力（空Enterで今月）
' ============================================================

Sub GenerateCalendar()
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim yText As String, mText As String
    Dim yy As Long, mm As Long
    Dim firstDate As Date, dInMonth As Long
    Dim startCol As Long, d As Long, rowIdx As Long, colIdx As Long, lastRow As Long
    Dim oldScreenUpdating As Boolean
    Dim createdSheet As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set wb = ActiveWorkbook

    ' 年（空Enterで今年）。9999年は翌月計算であふれるので上限を9998にする
    yText = Trim$(InputBox("年を入力してください（例: 2026）。空Enterで今年。", "カレンダー作成", CStr(Year(Date))))
    If Len(yText) = 0 Then yy = Year(Date) Else yy = CLngSafe(yText)
    If yy < 1900 Or yy > 9998 Then
        MsgBox "年は 1900～9998 で入力してください。", vbExclamation
        Exit Sub
    End If

    ' 月（空Enterで今月）
    mText = Trim$(InputBox("月を入力してください（1～12）。空Enterで今月。", "カレンダー作成", CStr(Month(Date))))
    If Len(mText) = 0 Then mm = Month(Date) Else mm = CLngSafe(mText)
    If mm < 1 Or mm > 12 Then
        MsgBox "月は 1～12 で入力してください。", vbExclamation
        Exit Sub
    End If

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    firstDate = DateSerial(yy, mm, 1)
    dInMonth = Day(DateSerial(yy, mm + 1, 0))      ' 翌月0日＝当月末日
    startCol = Weekday(firstDate, vbSunday)         ' 1=日 … 7=土

    ' 新しいシート（YYYY-MM）
    Set ws = wb.Worksheets.Add(After:=wb.Worksheets(wb.Worksheets.Count))
    createdSheet = True
    ws.Name = UniqueSheetName(wb, Format$(firstDate, "yyyy-mm"))

    ' タイトル
    ws.Range(ws.Cells(1, 1), ws.Cells(1, 7)).Merge
    ws.Cells(1, 1).Value = Format$(firstDate, "yyyy年m月")
    ws.Cells(1, 1).HorizontalAlignment = xlCenter
    ws.Cells(1, 1).Font.Bold = True
    ws.Cells(1, 1).Font.Size = 14

    ' 曜日見出し
    Dim wdays As Variant, c As Long
    wdays = Array("日", "月", "火", "水", "木", "金", "土")
    For c = 0 To 6
        With ws.Cells(2, c + 1)
            .Value = wdays(c)
            .Font.Bold = True
            .HorizontalAlignment = xlCenter
            If c = 0 Then .Font.Color = vbRed        ' 日曜
            If c = 6 Then .Font.Color = vbBlue       ' 土曜
        End With
    Next c

    ' 日付を配置
    rowIdx = 3
    colIdx = startCol
    lastRow = 3
    For d = 1 To dInMonth
        With ws.Cells(rowIdx, colIdx)
            .Value = d
            .HorizontalAlignment = xlCenter
            If colIdx = 1 Then .Font.Color = vbRed       ' 日曜
            If colIdx = 7 Then .Font.Color = vbBlue      ' 土曜
            ' 今日を黄色で強調
            If DateSerial(yy, mm, d) = Date Then .Interior.Color = vbYellow
        End With
        lastRow = rowIdx                  ' 最後に日付を置いた行を覚える
        colIdx = colIdx + 1
        If colIdx > 7 Then                ' 土曜の次は翌週へ
            colIdx = 1
            rowIdx = rowIdx + 1
        End If
    Next d

    ' 見た目の調整（罫線は最終日の行までにして、余分な空行に引かない）
    ws.Range(ws.Columns(1), ws.Columns(7)).ColumnWidth = 6
    ws.Range(ws.Cells(2, 1), ws.Cells(lastRow, 7)).Borders.LineStyle = xlContinuous
    ws.Cells(1, 1).Select

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox Format$(firstDate, "yyyy年m月") & " のカレンダーを作りました。", vbInformation, "結果"
    Exit Sub

CleanFail:
    ' 途中で失敗したら、作りかけのシートを残さない
    If createdSheet And Not ws Is Nothing Then
        Dim oldAlerts As Boolean
        oldAlerts = Application.DisplayAlerts
        Application.DisplayAlerts = False
        ws.Delete
        Application.DisplayAlerts = oldAlerts
    End If
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 整数の数字だけを受け付けて返す。整数でなければ -1（範囲チェックで弾ける）。
Private Function CLngSafe(ByVal s As String) As Long
    Dim t As String, i As Long
    t = StrConv(Trim$(s), vbNarrow)   ' 全角数字を半角にそろえる
    If Len(t) = 0 Then
        CLngSafe = -1
        Exit Function
    End If
    For i = 1 To Len(t)                ' 1文字でも数字でなければ無効（小数・符号・指数を弾く）
        If Mid$(t, i, 1) < "0" Or Mid$(t, i, 1) > "9" Then
            CLngSafe = -1
            Exit Function
        End If
    Next i
    CLngSafe = CLng(t)
End Function


' 既存と重ならないシート名にする。
Private Function UniqueSheetName(wb As Workbook, ByVal baseName As String) As String
    Dim cand As String, n As Long
    cand = baseName
    n = 2
    Do While SheetExists(wb, cand)
        cand = baseName & "(" & n & ")"
        n = n + 1
    Loop
    UniqueSheetName = cand
End Function


Private Function SheetExists(wb As Workbook, ByVal nm As String) As Boolean
    Dim sh As Object
    On Error Resume Next
    Set sh = wb.Sheets(nm)   ' グラフシートなど全種類を確認（同名で命名失敗しないように）
    On Error GoTo 0
    SheetExists = Not (sh Is Nothing)
End Function

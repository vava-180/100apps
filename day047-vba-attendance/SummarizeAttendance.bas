Attribute VB_Name = "SummarizeAttendance"
Option Explicit

' ============================================================
' 勤怠集計マクロ（Day 047）
'
' 勤怠表から、各行の「実働時間」を計算して列に書き出し、合計を下に追記します。
'   必要な見出し: 「出勤」「退勤」（Excelの時刻として入力。例 9:00）
'   任意の見出し: 「休憩」（分。数値。例 60）
'   出力の見出し: 「実働」（無ければ右端に「実働(時間)」を作る）
'
' 計算: 実働時間 = （退勤 － 出勤）－ 休憩。退勤が出勤より早い場合は日をまたいだとみなします。
'   結果は「時間（小数）」で出します（例: 7.5 = 7時間30分）。
'
' 使い方:
'   1) 1行目に見出し、2行目以降にデータがある勤怠表を開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → SummarizeAttendance を実行
'
' 注意: 「休憩」は分（数値）で入力してください（1:00 のような時刻形式ではありません）。
'       見出しは完全一致で探します（「出勤」「出勤時刻」など、決まった名前のみ）。
' ============================================================

Sub SummarizeAttendance()
    Dim ws As Worksheet
    Dim cIn As Long, cOut As Long, cBreak As Long, cWork As Long
    Dim lastRow As Long, r As Long, labelCol As Long
    Dim startF As Double, endF As Double, worked As Double, hours As Double, br As Double
    Dim total As Double, rh As Double
    Dim done As Long, skipped As Long, anomaly As Long
    Dim oldScreenUpdating As Boolean

    ' 前提チェック
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "勤怠表のあるワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet
    If ws.ProtectContents Then
        MsgBox "シートが保護されています。保護を解除してから実行してください。", vbExclamation
        Exit Sub
    End If

    ' 見出し名（完全一致・候補リスト）から列を探す
    cIn = FindHeaderCol(ws, Array("出勤", "出勤時刻", "出勤時間"))
    cOut = FindHeaderCol(ws, Array("退勤", "退勤時刻", "退勤時間"))
    If cIn = 0 Or cOut = 0 Then
        MsgBox "見出しに「出勤」「退勤」のある勤怠表を開いてください。", vbExclamation
        Exit Sub
    End If
    cBreak = FindHeaderCol(ws, Array("休憩", "休憩(分)", "休憩時間(分)", "休憩分"))
    cWork = FindHeaderCol(ws, Array("実働", "実働時間", "実働(時間)", "実働時間(h)"))

    ' データの最終行は「出勤」列から判断する（下の合計行を巻き込まない）
    lastRow = ws.Cells(ws.Rows.Count, cIn).End(xlUp).Row
    If lastRow < 2 Then
        MsgBox "2行目以降にデータがありません。", vbInformation
        Exit Sub
    End If

    If MsgBox(lastRow - 1 & " 行ぶんの実働時間を計算します。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    ' 実働列が無ければ、ここ（確認の後）で右端に作る
    If cWork = 0 Then
        cWork = HeaderLastCol(ws) + 1
        ws.Cells(1, cWork).Value = "実働(時間)"
    End If

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    total = 0: done = 0: skipped = 0: anomaly = 0
    For r = 2 To lastRow
        startF = ToTimeFrac(ws.Cells(r, cIn).Value)
        endF = ToTimeFrac(ws.Cells(r, cOut).Value)
        If startF < 0 Or endF < 0 Then
            ws.Cells(r, cWork).ClearContents   ' 計算できない行は、古い実働値を残さない
            skipped = skipped + 1
        Else
            worked = endF - startF
            If worked < 0 Then worked = worked + 1   ' 日をまたいだ勤務
            br = 0
            If cBreak > 0 Then
                If IsNumeric(ws.Cells(r, cBreak).Value) Then br = CDbl(ws.Cells(r, cBreak).Value)
            End If
            If br < 0 Then br = 0                     ' マイナスの休憩は0扱い
            hours = worked * 24 - br / 60             ' 時間（小数）に直し、休憩（分）を引く
            If hours < 0 Then
                hours = 0
                anomaly = anomaly + 1                 ' 休憩が実働より長いなど、おかしい行
            End If
            rh = Application.WorksheetFunction.Round(hours, 2)
            ws.Cells(r, cWork).Value = rh
            total = total + rh                        ' セルと同じ丸め済み値を合計する
            done = done + 1
        End If
    Next r

    ' 合計を1行あけた下に書く。ラベルは「出勤」列を汚さない場所に置く
    ws.Cells(lastRow + 2, cWork).Value = Application.WorksheetFunction.Round(total, 2)
    labelCol = cWork - 1
    If labelCol >= 1 And labelCol <> cIn Then
        ws.Cells(lastRow + 2, labelCol).Value = "合計"
    Else
        ws.Cells(lastRow + 1, cWork).Value = "合計"   ' 左に置けないときは数値の1つ上に
    End If

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "実働時間を計算しました。" & vbCrLf & _
           "計算した: " & done & " 行 / 合計: " & Application.WorksheetFunction.Round(total, 2) & " 時間" & vbCrLf & _
           "時刻が読めず飛ばした: " & skipped & " 行 / 要確認(マイナス→0): " & anomaly & " 行", _
           vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 値を「1日のうちの時刻（0～1の割合）」に直す。時刻として読めなければ -1。
' 日付＋時刻のシリアル値でも、整数部（日付）を取り除いて時刻部分だけを使う。
Private Function ToTimeFrac(ByVal v As Variant) As Double
    Dim d As Double
    On Error GoTo bad
    If IsError(v) Then GoTo bad
    If Len(CStr(v)) = 0 Then GoTo bad
    If IsNumeric(v) Then
        d = CDbl(v)
        ToTimeFrac = d - Int(d)
    Else
        ToTimeFrac = CDbl(TimeValue(CStr(v)))   ' "9:00" のような文字でもOK
    End If
    Exit Function
bad:
    ToTimeFrac = -1
End Function


' 見出し行（1行目）から、候補名のどれかと「完全一致」する列を探す。無ければ 0。
Private Function FindHeaderCol(ws As Worksheet, ByVal names As Variant) As Long
    Dim i As Long, f As Range
    For i = LBound(names) To UBound(names)
        Set f = ws.Rows(1).Find(What:=names(i), LookIn:=xlValues, LookAt:=xlWhole, _
                                SearchOrder:=xlByColumns, SearchDirection:=xlNext, MatchCase:=False)
        If Not f Is Nothing Then
            FindHeaderCol = f.Column
            Exit Function
        End If
    Next i
    FindHeaderCol = 0
End Function


' 見出し行（1行目）の最終列。空なら 0。
Private Function HeaderLastCol(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Rows(1).Find(What:="*", LookIn:=xlValues, LookAt:=xlPart, _
                            SearchOrder:=xlByColumns, SearchDirection:=xlPrevious, MatchCase:=False)
    If f Is Nothing Then HeaderLastCol = 0 Else HeaderLastCol = f.Column
End Function

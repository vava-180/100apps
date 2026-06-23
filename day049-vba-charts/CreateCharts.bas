Attribute VB_Name = "CreateCharts"
Option Explicit

' ============================================================
' グラフ一括作成マクロ（Day 049）
'
' いま開いているシートの表から、数値の列ごとにグラフを1つずつまとめて作ります。
'   - 1行目＝見出し、A列＝項目名（グラフの横軸）、B列以降＝数値（グラフの値）
'   - 数値の列の数だけグラフができ、表の下に並びます
'
' グラフの種類は 縦棒／折れ線／横棒 から選べます。
' 再実行すると、前回このマクロが作ったグラフ（名前が AutoChart_ で始まるもの）は消してから作り直します。
'
' 使い方:
'   1) 表のあるシートを開く（1行目に見出し、A列に項目名、B列以降に数値）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → CreateCharts を実行
'   4) 1（縦棒）／2（折れ線）／3（横棒）を選ぶ
'
' 前提: A列（項目名）は全行うめてください。データの行数はA列で数えます。
'       数値以外やエラー値が混じる列も、その列に数値が1つでもあればグラフ化します
'       （非数値のところは値が抜けて見えることがあります）。
' ============================================================

Private Const CHART_PREFIX As String = "AutoChart_"

Sub CreateCharts()
    Dim ws As Worksheet
    Dim lastRow As Long, lastCol As Long, c As Long
    Dim chartType As String, xlType As Long
    Dim made As Long
    Dim leftBase As Double, topBase As Double, chW As Double, chH As Double, gap As Double
    Dim co As ChartObject
    Dim oldScreenUpdating As Boolean

    ' 前提チェック
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "表のあるワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastCol < 2 Or lastRow < 2 Then
        MsgBox "1行目に見出し、A列に項目名、B列以降に数値のある表を開いてください。", vbInformation
        Exit Sub
    End If

    ' グラフの種類を選ぶ
    chartType = Trim$(InputBox("グラフの種類を選んでください。" & vbCrLf & _
                               "  1 = 縦棒" & vbCrLf & "  2 = 折れ線" & vbCrLf & "  3 = 横棒", _
                               "グラフの種類", "1"))
    Select Case chartType
        Case "1": xlType = xlColumnClustered
        Case "2": xlType = xlLine
        Case "3": xlType = xlBarClustered
        Case Else
            If Len(chartType) > 0 Then MsgBox "1～3 を入力してください。", vbExclamation
            Exit Sub
    End Select

    ' 表がシートの下端に近いと、グラフの置き場所（表の2行下）が作れない
    If lastRow > ws.Rows.Count - 2 Then
        MsgBox "表がシートの下端に近すぎて、グラフを置けません。表を上の方に置いてください。", vbExclamation
        Exit Sub
    End If

    ' グラフにできる数値列が1つでもあるか、先に確認する（無いのに既存グラフを消さないため）
    made = 0
    For c = 2 To lastCol
        If ColumnHasNumber(ws, c, lastRow) Then made = made + 1
    Next c
    If made = 0 Then
        MsgBox "数値の列が見つかりませんでした（B列以降に数値を入れてください）。", vbInformation
        Exit Sub
    End If

    If MsgBox(made & " 個のグラフを作ります（前回このマクロが作ったグラフは作り直します）。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    ' 前回このマクロが作ったグラフを消す（作り直しのため）
    DeleteAutoCharts ws

    ' グラフを並べる基準位置（表の下）とサイズ（ポイント単位）
    leftBase = ws.Cells(1, 1).Left
    topBase = ws.Cells(lastRow + 2, 1).Top
    chW = 320: chH = 200: gap = 15

    made = 0
    For c = 2 To lastCol
        If ColumnHasNumber(ws, c, lastRow) Then
            Set co = ws.ChartObjects.Add( _
                Left:=leftBase + (made Mod 2) * (chW + gap), _
                Top:=topBase + (made \ 2) * (chH + gap), _
                Width:=chW, Height:=chH)
            co.Name = CHART_PREFIX & made          ' 後で消せるよう、決まった名前を付ける
            BuildOneChart co.Chart, ws, c, lastRow, xlType
            made = made + 1
        End If
    Next c

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "グラフを作りました。" & vbCrLf & "作成: " & made & " 個（表の下に並べています）", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1つのグラフの中身を作る（X軸＝A列の項目、値＝c列、表題＝見出し）。
Private Sub BuildOneChart(ch As Chart, ws As Worksheet, ByVal c As Long, ByVal lastRow As Long, ByVal xlType As Long)
    Dim s As Series
    ch.ChartType = xlType
    ' 既定で付くかもしれない系列を消してから、1本だけ作る
    Do While ch.SeriesCollection.Count > 0
        ch.SeriesCollection(1).Delete
    Loop
    Set s = ch.SeriesCollection.NewSeries
    s.Values = ws.Range(ws.Cells(2, c), ws.Cells(lastRow, c))
    s.XValues = ws.Range(ws.Cells(2, 1), ws.Cells(lastRow, 1))
    s.Name = CStr(ws.Cells(1, c).Value)   ' 見出しの文字をそのまま系列名に（参照式にしない＝堅牢）
    ch.HasTitle = True
    ch.ChartTitle.Text = CStr(ws.Cells(1, c).Value)
    ch.HasLegend = False
End Sub


' c列の2～lastRowに、数値が1つでもあるか
Private Function ColumnHasNumber(ws As Worksheet, ByVal c As Long, ByVal lastRow As Long) As Boolean
    Dim r As Long, v As Variant
    For r = 2 To lastRow
        v = ws.Cells(r, c).Value
        If Not IsError(v) Then
            If IsNumeric(v) And Len(CStr(v)) > 0 Then
                ColumnHasNumber = True
                Exit Function
            End If
        End If
    Next r
    ColumnHasNumber = False
End Function


' このマクロが前に作ったグラフ（名前が AutoChart_ で始まる）を消す。
Private Sub DeleteAutoCharts(ws As Worksheet)
    Dim co As ChartObject
    Dim i As Long
    For i = ws.ChartObjects.Count To 1 Step -1   ' 消すので後ろから回す
        Set co = ws.ChartObjects(i)
        If Left$(co.Name, Len(CHART_PREFIX)) = CHART_PREFIX Then co.Delete
    Next i
End Sub

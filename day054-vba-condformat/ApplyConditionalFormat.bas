Attribute VB_Name = "ApplyConditionalFormat"
Option Explicit

' ============================================================
' 条件付き書式の一括設定マクロ（Day 054）
'
' 選んだ範囲（選んでいなければ使用範囲）に、条件付き書式をまとめて設定します。
'   1 = しきい値より大きいセルを色付け（黄）
'   2 = しきい値より小さいセルを色付け（黄）
'   3 = 重複している値を色付け（赤系）
'   4 = カラースケール（小さい=赤 ～ 大きい=緑）
'
' 既存の条件付き書式は、設定前にその範囲ぶんだけ消します（重ね掛けを防ぐため）。
'
' 使い方:
'   1) 設定したい範囲を選ぶ（選ばなければ使用範囲が対象）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → ApplyConditionalFormat を実行
'   4) 1～4 を選ぶ
' ============================================================

Sub ApplyConditionalFormat()
    Dim ws As Worksheet
    Dim target As Range
    Dim mode As String
    Dim thresholdText As String
    Dim oldScreenUpdating As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    ' 対象範囲（2つ以上のセルを選んでいればそれ、1セルだけ／未選択なら使用範囲）
    If TypeName(Selection) = "Range" Then
        If Selection.Cells.CountLarge > 1 Then
            Set target = Selection
        Else
            Set target = ws.UsedRange
        End If
    Else
        Set target = ws.UsedRange
    End If
    If target Is Nothing Then
        MsgBox "対象のセルがありません。", vbInformation
        Exit Sub
    End If
    ' バラバラ（非連続）選択は、条件付き書式の追加で失敗しやすいので断る
    If target.Areas.Count > 1 Then
        MsgBox "ひと続きの範囲を選んでください（バラバラ選択は不可）。", vbExclamation
        Exit Sub
    End If
    If Application.WorksheetFunction.CountA(target) = 0 Then
        MsgBox "対象にデータがありません。", vbInformation
        Exit Sub
    End If

    mode = Trim$(InputBox("条件付き書式の種類を選んでください。" & vbCrLf & _
                          "  1 = しきい値より大きいセルを色付け" & vbCrLf & _
                          "  2 = しきい値より小さいセルを色付け" & vbCrLf & _
                          "  3 = 重複している値を色付け" & vbCrLf & _
                          "  4 = カラースケール（小=赤～大=緑）", "条件付き書式", "1"))
    If mode <> "1" And mode <> "2" And mode <> "3" And mode <> "4" Then
        If Len(mode) > 0 Then MsgBox "1～4 を入力してください。", vbExclamation
        Exit Sub
    End If

    ' しきい値が必要なモード（1・2）は数値を聞く
    Dim threshold As Double
    If mode = "1" Or mode = "2" Then
        thresholdText = Trim$(InputBox("しきい値（数値）を入力してください。", "しきい値"))
        If Len(thresholdText) = 0 Then Exit Sub
        If Not IsNumeric(thresholdText) Then
            MsgBox "数値を入力してください。", vbExclamation
            Exit Sub
        End If
        threshold = CDbl(thresholdText)
    End If

    If MsgBox(target.Address & " に条件付き書式を設定します。" & vbCrLf & _
              "（この範囲の既存の条件付き書式は消します）よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    ' 既存の条件付き書式を消す（重ね掛け防止）
    target.FormatConditions.Delete

    Select Case mode
        Case "1": AddThreshold target, xlGreater, threshold
        Case "2": AddThreshold target, xlLess, threshold
        Case "3": AddDuplicate target
        Case "4": AddColorScale target
    End Select

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "条件付き書式を設定しました。", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' しきい値の大小で色付け（黄）。
Private Sub AddThreshold(target As Range, ByVal op As Long, ByVal threshold As Double)
    Dim fc As FormatCondition
    ' Formula1には数値をそのまま渡す（文字列にすると小数点の記号がロケール依存になり崩れる）
    Set fc = target.FormatConditions.Add(Type:=xlCellValue, Operator:=op, Formula1:=threshold)
    fc.Interior.Color = vbYellow
End Sub


' 重複している値を色付け（赤系）。
Private Sub AddDuplicate(target As Range)
    Dim uv As UniqueValues
    Set uv = target.FormatConditions.AddUniqueValues
    uv.DupeUnique = xlDuplicate
    uv.Interior.Color = RGB(255, 199, 206)   ' 薄い赤
    uv.Font.Color = RGB(156, 0, 6)
End Sub


' カラースケール（小さい=赤 ～ 中=黄 ～ 大きい=緑）。
Private Sub AddColorScale(target As Range)
    Dim cs As ColorScale
    Set cs = target.FormatConditions.AddColorScale(ColorScaleType:=3)
    With cs.ColorScaleCriteria(1)
        .Type = xlConditionValueLowestValue
        .FormatColor.Color = RGB(248, 105, 107)   ' 赤
    End With
    With cs.ColorScaleCriteria(2)
        .Type = xlConditionValuePercentile
        .Value = 50
        .FormatColor.Color = RGB(255, 235, 132)   ' 黄
    End With
    With cs.ColorScaleCriteria(3)
        .Type = xlConditionValueHighestValue
        .FormatColor.Color = RGB(99, 190, 123)    ' 緑
    End With
End Sub

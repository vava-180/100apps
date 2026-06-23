Attribute VB_Name = "UnifyFont"
Option Explicit

' ============================================================
' 全スライドのフォント統一マクロ（Day 058 / PowerPoint VBA）
'
' 今開いているプレゼンの、すべてのスライドの文字を、指定したフォントにそろえます。
'   - 図形・テキストボックス・プレースホルダ・表・グループの中まで対象
'   - 日本語用のフォント（NameFarEast）も同じフォントにそろえます
'
' 使い方:
'   1) PowerPointでプレゼンを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → UnifyFont を実行
'   4) フォント名を入力（例: メイリオ）
'
' 注意: フォント名はインストール済みのものを正確に入れてください（誤入力でも止まりません）。
'       元に戻せないので、必要なら先に保存してください。
' ============================================================

Private Const msoGroup As Long = 6
Private Const msoTrue As Long = -1

Dim gChanged As Long   ' フォントを変えられた箇所の数
Dim gFailed As Long    ' 変えられなかった（失敗した）箇所の数

Sub UnifyFont()
    Dim pres As Presentation
    Dim sld As Slide
    Dim shp As Object
    Dim fontName As String

    gChanged = 0
    gFailed = 0

    If Application.Presentations.Count = 0 Then
        MsgBox "プレゼンが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set pres = ActivePresentation

    fontName = Trim$(InputBox("そろえたいフォント名を入力してください（例: メイリオ）。", "フォント統一", "メイリオ"))
    If Len(fontName) = 0 Then Exit Sub

    If MsgBox("すべてのスライドの文字を「" & fontName & "」にそろえます。" & vbCrLf & _
              "元に戻せないので、必要なら先に保存してください。実行しますか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    On Error GoTo CleanFail

    For Each sld In pres.Slides
        For Each shp In sld.Shapes
            ApplyFontToShape shp, fontName
        Next shp
    Next sld

    MsgBox "フォントをそろえました。" & vbCrLf & _
           "変更: " & gChanged & " 箇所 / 変更できず: " & gFailed & " 箇所" & vbCrLf & _
           "※ フォント名が正しいかは確認していません（表示をご確認ください）。", vbInformation, "結果"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1つの図形にフォントを適用する。グループ・表の中まで入る。
Private Sub ApplyFontToShape(shp As Object, ByVal fontName As String)
    Dim subShp As Object
    Dim isGroup As Boolean, isTable As Boolean, hasTF As Boolean

    ' 種類の確認だけ、対応していない図形でも落ちないように囲う
    On Error Resume Next
    isGroup = (shp.Type = msoGroup)
    isTable = (shp.HasTable = msoTrue)
    hasTF = (shp.HasTextFrame = msoTrue)
    On Error GoTo 0

    If isGroup Then
        On Error Resume Next
        For Each subShp In shp.GroupItems   ' グループの中を1つずつ
            ApplyFontToShape subShp, fontName
        Next subShp
        On Error GoTo 0
    ElseIf isTable Then
        ApplyToTable shp, fontName
    ElseIf hasTF Then
        On Error Resume Next
        If shp.TextFrame.HasText = msoTrue Then SetFont shp.TextFrame.TextRange, fontName
        On Error GoTo 0
    End If
End Sub


' 表のセルのうち、文字が入っているものだけフォントを変える。
Private Sub ApplyToTable(shp As Object, ByVal fontName As String)
    Dim r As Long, c As Long, tf As Object
    On Error Resume Next
    With shp.Table
        For r = 1 To .Rows.Count
            For c = 1 To .Columns.Count
                Set tf = .Cell(r, c).Shape.TextFrame
                If tf.HasText = msoTrue Then SetFont tf.TextRange, fontName
            Next c
        Next r
    End With
    On Error GoTo 0
End Sub


' テキスト範囲のフォント（英数字用＋日本語用）をそろえる。成功時だけ数える。
Private Sub SetFont(rng As Object, ByVal fontName As String)
    On Error Resume Next
    Err.Clear
    rng.Font.Name = fontName            ' 英数字用
    rng.Font.NameFarEast = fontName     ' 日本語用
    If Err.Number = 0 Then
        gChanged = gChanged + 1
    Else
        gFailed = gFailed + 1
    End If
    On Error GoTo 0
End Sub

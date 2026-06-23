Attribute VB_Name = "ReplaceTextInSlides"
Option Explicit

' ============================================================
' スライドの文字を一括差し替えマクロ（Day 060 / PowerPoint VBA）
'
' 開いているプレゼン全体のスライドを巡り、指定した「検索文字」を
' 「置換文字」へまとめて置き換えます。フォントや色などの書式は
' 保ったまま、文字だけを差し替えます。
'
' 対象:
'   ・通常のテキストボックス／図形（プレースホルダ含む）の文字
'   ・表（テーブル）のセルの文字
'   ・グループ化された図形の中の文字（入れ子のグループも対応）
' 対象外:
'   ・ノート（発表者メモ）、SmartArt、画像内の文字 は触りません
'
' 使い方:
'   1) 差し替えたいプレゼンを開く
'   2) Alt+F11 でVBE → 「ファイル → ファイルのインポート」で本ファイルを取り込む
'   3) Alt+F8 → ReplaceTextInSlides を実行
'   4) 「検索する文字」「置き換える文字」を入力（置換は空欄なら検索文字を削除）
' ============================================================

' 置換した件数を数えるためのモジュール変数（再帰処理で共有する）
Private mReplaced As Long

Sub ReplaceTextInSlides()
    Dim findStr As String, replStr As String
    Dim sld As Slide
    Dim shp As Shape

    ' 前提チェック：プレゼンが開かれていること
    If Presentations.Count = 0 Then
        MsgBox "プレゼンテーションが開かれていません。", vbExclamation
        Exit Sub
    End If

    ' 検索する文字（空ならキャンセル扱いで終了）
    findStr = InputBox("検索する文字を入力してください。", "一括差し替え（1/2）")
    If Len(findStr) = 0 Then Exit Sub

    ' 置き換える文字（空欄でもOK＝その場合は検索文字を削除する）
    replStr = InputBox("「" & findStr & "」を何に置き換えますか？" & vbCrLf & _
                       "（空欄のままOKを押すと、検索文字を削除します）", "一括差し替え（2/2）")

    ' 実行前の確認（元に戻せないため）
    If MsgBox("「" & findStr & "」を「" & replStr & "」に置き換えます。" & vbCrLf & _
              "元に戻せないので、必要なら先に保存してください。実行しますか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    mReplaced = 0
    On Error GoTo CleanFail

    ' すべてのスライドの、すべての図形を処理する
    For Each sld In ActivePresentation.Slides
        For Each shp In sld.Shapes
            ProcessShape shp, findStr, replStr
        Next shp
    Next sld

    MsgBox "置き換えが完了しました。" & vbCrLf & "置換した箇所: " & mReplaced & " 件", _
           vbInformation, "完了"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1つの図形を処理する。グループ・表は中まで入って再帰的に処理する。
Private Sub ProcessShape(ByVal shp As Shape, ByVal findStr As String, ByVal replStr As String)
    Dim subShp As Shape
    Dim r As Long, c As Long
    Dim tbl As Table

    ' グループ図形 … 中の図形を1つずつ処理（入れ子のグループも再帰で対応）
    If shp.Type = msoGroup Then
        For Each subShp In shp.GroupItems
            ProcessShape subShp, findStr, replStr
        Next subShp
        Exit Sub
    End If

    ' 表（テーブル）… セルごとに文字を置き換える
    If shp.HasTable = msoTrue Then
        Set tbl = shp.Table
        For r = 1 To tbl.Rows.Count
            For c = 1 To tbl.Columns.Count
                ReplaceInShapeText tbl.Cell(r, c).Shape, findStr, replStr
            Next c
        Next r
        Exit Sub
    End If

    ' 通常の文字を持つ図形
    ReplaceInShapeText shp, findStr, replStr
End Sub


' 図形（または表のセル図形）が文字を持っていれば置換する。
Private Sub ReplaceInShapeText(ByVal shp As Shape, ByVal findStr As String, ByVal replStr As String)
    If shp.HasTextFrame <> msoTrue Then Exit Sub
    If shp.TextFrame.HasText <> msoTrue Then Exit Sub
    ReplaceInTextRange shp.TextFrame.TextRange, findStr, replStr
End Sub


' TextRange の中の文字を、書式を保ったまますべて置き換える。
Private Sub ReplaceInTextRange(ByVal rng As TextRange, ByVal findStr As String, ByVal replStr As String)
    Dim found As TextRange
    Dim afterPos As Long

    afterPos = 0   ' この位置より後ろを検索（0＝先頭から）
    Do
        Set found = rng.Replace(FindWhat:=findStr, ReplaceWhat:=replStr, _
                                After:=afterPos, MatchCase:=True, WholeWords:=False)
        If found Is Nothing Then Exit Do
        mReplaced = mReplaced + 1
        ' 置き換えた文字の直後から続きを検索する
        ' （置換文字が検索文字を含んでいても無限ループしないようにするため）
        afterPos = found.Start + Len(replStr) - 1
    Loop
End Sub

Attribute VB_Name = "ExportSlidesToMarkdown"
Option Explicit

' ============================================================
' スライド内容を Markdown に書き出すマクロ（Day 061 / PowerPoint VBA）
'
' 開いているプレゼンの各スライドを巡り、タイトル・本文・表を
' Markdown テキストに変換して、プレゼンと同じフォルダに .md として保存します。
' 議事録や資料の内容を、テキスト（Markdown）で再利用したいときに便利です。
'
' 書き出す内容:
'   ・スライドのタイトル → 見出し（## スライドN: タイトル）
'   ・本文の各段落      → 箇条書き（- 文章）。インデントの深さも段差にする
'   ・表（テーブル）    → Markdown の表
' 対象外:
'   ・ノート、SmartArt、画像内の文字、グラフ は書き出しません
'
' 使い方:
'   1) 書き出したいプレゼンを開いて、一度保存しておく（保存先にmdを作るため）
'   2) Alt+F11 でVBE → 「ファイル → ファイルのインポート」で本ファイルを取り込む
'   3) Alt+F8 → ExportSlidesToMarkdown を実行
'   4) 同じフォルダに「（プレゼン名）.md」ができる
' ============================================================

Sub ExportSlidesToMarkdown()
    Dim pres As Presentation
    Dim sld As Slide
    Dim md As String
    Dim i As Long
    Dim outPath As String

    ' 前提チェック：プレゼンが開かれていて、保存済みであること
    If Presentations.Count = 0 Then
        MsgBox "プレゼンテーションが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set pres = ActivePresentation
    If Len(pres.Path) = 0 Then
        MsgBox "先にプレゼンを保存してから実行してください。" & vbCrLf & _
               "（保存先と同じフォルダに Markdown を書き出します）", vbExclamation
        Exit Sub
    End If

    On Error GoTo CleanFail

    ' 見出し（プレゼン名）から組み立て開始
    md = "# " & BaseName(pres.Name) & vbCrLf & vbCrLf

    i = 0
    For Each sld In pres.Slides
        i = i + 1
        md = md & SlideToMarkdown(sld, i) & vbCrLf
    Next sld

    ' プレゼンと同じフォルダに UTF-8 で保存
    outPath = pres.Path & "\" & BaseName(pres.Name) & ".md"
    SaveUtf8 outPath, md

    MsgBox "Markdown を書き出しました。" & vbCrLf & outPath, vbInformation, "完了"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1枚のスライドを Markdown 文字列に変換する。
Private Function SlideToMarkdown(ByVal sld As Slide, ByVal idx As Long) As String
    Dim shp As Shape
    Dim s As String
    Dim titleText As String

    ' タイトルは見出しに使う
    titleText = GetSlideTitle(sld)
    If Len(titleText) > 0 Then
        s = "## スライド " & idx & ": " & titleText & vbCrLf & vbCrLf
    Else
        s = "## スライド " & idx & vbCrLf & vbCrLf
    End If

    ' 各図形を本文として書き出す（タイトルは見出しで使ったので飛ばす）
    For Each shp In sld.Shapes
        If Not IsTitlePlaceholder(shp) Then
            If shp.HasTable = msoTrue Then
                s = s & TableToMarkdown(shp.Table) & vbCrLf
            ElseIf shp.HasTextFrame = msoTrue Then
                If shp.TextFrame.HasText = msoTrue Then
                    s = s & TextFrameToMarkdown(shp.TextFrame.TextRange) & vbCrLf
                End If
            End If
        End If
    Next shp

    SlideToMarkdown = s
End Function


' スライドのタイトル文字を取り出す（無ければ空文字）。
Private Function GetSlideTitle(ByVal sld As Slide) As String
    On Error Resume Next
    If sld.Shapes.HasTitle = msoTrue Then
        GetSlideTitle = Trim$(CleanText(sld.Shapes.Title.TextFrame.TextRange.Text))
    End If
    On Error GoTo 0
End Function


' その図形がタイトル用のプレースホルダかどうか。
Private Function IsTitlePlaceholder(ByVal shp As Shape) As Boolean
    On Error Resume Next
    If shp.Type = msoPlaceholder Then
        Select Case shp.PlaceholderFormat.Type
            Case ppPlaceholderTitle, ppPlaceholderCenterTitle
                IsTitlePlaceholder = True
        End Select
    End If
    On Error GoTo 0
End Function


' テキストフレームの段落を、箇条書き（インデント段差つき）にする。
Private Function TextFrameToMarkdown(ByVal rng As TextRange) As String
    Dim i As Long, lvl As Long
    Dim para As TextRange
    Dim line As String
    Dim s As String

    For i = 1 To rng.Paragraphs.Count
        Set para = rng.Paragraphs(i, 1)
        line = Trim$(CleanText(para.Text))
        If Len(line) > 0 Then
            lvl = para.IndentLevel              ' 1?5（段落の階層）
            If lvl < 1 Then lvl = 1
            s = s & Space$((lvl - 1) * 2) & "- " & line & vbCrLf
        End If
    Next i

    TextFrameToMarkdown = s
End Function


' 表を Markdown の表に変換する（1行目をヘッダ扱い）。
Private Function TableToMarkdown(ByVal tbl As Table) As String
    Dim r As Long, c As Long
    Dim s As String
    Dim cellText As String

    For r = 1 To tbl.Rows.Count
        s = s & "|"
        For c = 1 To tbl.Columns.Count
            cellText = ""
            If tbl.Cell(r, c).Shape.TextFrame.HasText = msoTrue Then
                cellText = tbl.Cell(r, c).Shape.TextFrame.TextRange.Text
            End If
            cellText = Trim$(CleanText(cellText))
            cellText = Replace(cellText, "|", "\|")   ' 表の区切りと混ざらないように
            s = s & " " & cellText & " |"
        Next c
        s = s & vbCrLf
        ' 1行目の下に区切り線を入れる（Markdownの表のヘッダ区切り）
        If r = 1 Then
            s = s & "|"
            For c = 1 To tbl.Columns.Count
                s = s & " --- |"
            Next c
            s = s & vbCrLf
        End If
    Next r

    TableToMarkdown = s
End Function


' 文字の中の改行（CR/LF/縦タブ）を半角スペースにそろえる。
Private Function CleanText(ByVal s As String) As String
    s = Replace(s, vbCr, " ")
    s = Replace(s, vbLf, " ")
    s = Replace(s, Chr$(11), " ")   ' 行内改行（ソフトリターン）
    CleanText = s
End Function


' ファイル名から拡張子を取り除く。
Private Function BaseName(ByVal fileName As String) As String
    Dim p As Long
    p = InStrRev(fileName, ".")
    If p > 0 Then
        BaseName = Left$(fileName, p - 1)
    Else
        BaseName = fileName
    End If
End Function


' UTF-8 でテキストファイルを保存する（日本語が文字化けしないように）。
Private Sub SaveUtf8(ByVal path As String, ByVal text As String)
    Dim stm As Object
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2                ' 2 = テキスト
    stm.Charset = "UTF-8"
    stm.Open
    stm.WriteText text
    stm.SaveToFile path, 2      ' 2 = 上書き保存
    stm.Close
End Sub

Attribute VB_Name = "CreateTocSlide"
Option Explicit

' ============================================================
' PowerPoint 目次スライド自動生成マクロ（Day 057 / PowerPoint VBA）
'
' 今開いているプレゼンの各スライドのタイトルを集めて、先頭に「目次」スライドを作ります。
'   - 目次には「2. タイトル」のように、スライド番号付きで並びます
'   - すでに先頭に目次スライドがあれば、作り直します
'
' 使い方:
'   1) PowerPointでプレゼンを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → CreateTocSlide を実行
'
' 注意: タイトルが無いスライドは「（無題のスライド）」と表示します。
' ============================================================

Private Const ppLayoutText As Long = 2                 ' タイトル＋本文のレイアウト
Private Const ppPlaceholderBody As Long = 2            ' 本文プレースホルダの種類
Private Const msoTextOrientationHorizontal As Long = 1 ' 横書きテキスト
Private Const TOC_TITLE As String = "目次"
Private Const TOC_TAG As String = "GeneratedBy"        ' このマクロが作った目印
Private Const TOC_TAG_VALUE As String = "CreateTocSlide"

Sub CreateTocSlide()
    Dim pres As Presentation
    Dim toc As Slide
    Dim body As String
    Dim i As Long

    If Application.Presentations.Count = 0 Then
        MsgBox "プレゼンが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set pres = ActivePresentation

    If pres.Slides.Count = 0 Then
        MsgBox "スライドがありません。", vbExclamation
        Exit Sub
    End If

    If MsgBox("先頭に「" & TOC_TITLE & "」スライドを作ります。" & vbCrLf & _
              "（すでに先頭に目次があれば作り直します）よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    On Error GoTo CleanFail

    ' 先頭が「このマクロが作った目次」なら、いったん削除して作り直す
    ' （タイトルが偶然「目次」なだけの、ユーザー自作スライドは消さない）
    If pres.Slides.Count >= 1 Then
        If IsGeneratedToc(pres.Slides(1)) Then pres.Slides(1).Delete
    End If

    If pres.Slides.Count = 0 Then
        MsgBox "目次に並べるスライドがありません。", vbInformation
        Exit Sub
    End If

    ' 目次スライドを先頭に作る（あとで見分けられるよう目印タグを付ける）
    Set toc = pres.Slides.Add(1, ppLayoutText)
    toc.Tags.Add TOC_TAG, TOC_TAG_VALUE
    toc.Shapes.Title.TextFrame.TextRange.Text = TOC_TITLE

    ' 2枚目以降（＝もとのスライド）のタイトルを並べる
    body = ""
    For i = 2 To pres.Slides.Count
        body = body & i & ". " & GetSlideTitle(pres.Slides(i)) & vbCr
    Next i

    ' 本文プレースホルダに書き込む
    PutBodyText toc, body

    ' 目次へ移動（表示状態によっては動かないので、失敗しても成功扱いにする）
    On Error Resume Next
    Application.ActiveWindow.View.GotoSlide 1
    On Error GoTo 0
    MsgBox "目次スライドを作りました。" & vbCrLf & _
           "並べたスライド: " & (pres.Slides.Count - 1) & " 枚", vbInformation, "結果"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' このスライドが、このマクロで作った目次かどうか（タグで見分ける）。
Private Function IsGeneratedToc(sld As Slide) As Boolean
    On Error Resume Next
    IsGeneratedToc = (sld.Tags(TOC_TAG) = TOC_TAG_VALUE)
    On Error GoTo 0
End Function


' スライドのタイトル文字を返す。無ければ「（無題のスライド）」。
Private Function GetSlideTitle(sld As Slide) As String
    Dim t As String
    t = ""
    On Error Resume Next                       ' 壊れた図形でも落ちないように
    If sld.Shapes.HasTitle Then
        If sld.Shapes.Title.TextFrame.HasText Then
            t = Trim$(sld.Shapes.Title.TextFrame.TextRange.Text)
        End If
    End If
    On Error GoTo 0
    If Len(t) = 0 Then t = "（無題のスライド）"
    GetSlideTitle = t
End Function


' 目次スライドの本文プレースホルダに文字を入れる。
Private Sub PutBodyText(sld As Slide, ByVal text As String)
    Dim shp As Object, target As Object
    Set target = Nothing

    ' まず「本文」プレースホルダを探す
    For Each shp In sld.Shapes.Placeholders
        If shp.PlaceholderFormat.Type = ppPlaceholderBody Then
            Set target = shp
            Exit For
        End If
    Next shp

    ' 無ければ、タイトル以外で文字を入れられるプレースホルダ
    If target Is Nothing Then
        For Each shp In sld.Shapes.Placeholders
            If shp.Name <> sld.Shapes.Title.Name And shp.HasTextFrame Then
                Set target = shp
                Exit For
            End If
        Next shp
    End If

    If Not target Is Nothing Then
        target.TextFrame.TextRange.Text = text
    Else
        ' それも無ければテキストボックスを作って入れる
        With sld.Shapes.AddTextbox(msoTextOrientationHorizontal, 40, 120, 640, 360)
            .TextFrame.TextRange.Text = text
        End With
    End If
End Sub

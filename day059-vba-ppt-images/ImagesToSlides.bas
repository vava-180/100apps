Attribute VB_Name = "ImagesToSlides"
Option Explicit

' ============================================================
' 画像を一括でスライド化マクロ（Day 059 / PowerPoint VBA）
'
' 指定フォルダの中の画像（jpg / png / gif / bmp）を、名前順に1枚ずつスライドにします。
'   - 1画像＝1スライド（白紙レイアウト）
'   - 画像はスライドに収まるよう、縦横比を保って拡大縮小し、中央に配置
'
' 使い方:
'   1) PowerPointでプレゼンを開く（無ければ新規作成してから）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → ImagesToSlides を実行
'   4) 画像が入ったフォルダのパスを入力
' ============================================================

Private Const ppLayoutBlank As Long = 12
Private Const msoFalse As Long = 0
Private Const msoTrue As Long = -1
Private Const MARGIN_RATE As Double = 0.9   ' スライドの9割の大きさまでに収める

Sub ImagesToSlides()
    Dim pres As Presentation
    Dim folderPath As String
    Dim fileList As Collection
    Dim i As Long, added As Long, failed As Long
    Dim slideW As Single, slideH As Single

    If Application.Presentations.Count = 0 Then
        MsgBox "先にPowerPointでプレゼンを開いて（または新規作成して）ください。", vbExclamation
        Exit Sub
    End If
    Set pres = ActivePresentation

    folderPath = Trim$(InputBox("画像が入ったフォルダのパスを入力してください。", "画像をスライド化"))
    If Len(folderPath) = 0 Then Exit Sub
    If Right$(folderPath, 1) <> "\" Then folderPath = folderPath & "\"
    If Dir$(folderPath, vbDirectory) = "" Then
        MsgBox "フォルダが見つかりません。", vbExclamation
        Exit Sub
    End If

    ' 画像ファイルを集める（名前順）
    Set fileList = CollectImages(folderPath)
    If fileList.Count = 0 Then
        MsgBox "画像ファイル（jpg / png / gif / bmp）が見つかりませんでした。", vbInformation
        Exit Sub
    End If

    If MsgBox(fileList.Count & " 枚の画像をスライドにします。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    On Error GoTo CleanFail
    slideW = pres.PageSetup.SlideWidth
    slideH = pres.PageSetup.SlideHeight

    added = 0
    failed = 0
    For i = 1 To fileList.Count
        If AddImageSlide(pres, CStr(fileList.Item(i)), slideW, slideH) Then
            added = added + 1
        Else
            failed = failed + 1
        End If
    Next i

    MsgBox "画像をスライドにしました。" & vbCrLf & _
           "作成: " & added & " 枚 / 読めず飛ばした: " & failed & " 枚", vbInformation, "結果"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1枚の画像を新しいスライドに挿入し、収まるように拡縮＆中央配置。成功なら True。
Private Function AddImageSlide(pres As Presentation, ByVal imgPath As String, _
                               ByVal slideW As Single, ByVal slideH As Single) As Boolean
    Dim sld As Slide, shp As Object
    Dim factor As Double, maxW As Single, maxH As Single

    On Error GoTo Failed
    Set sld = pres.Slides.Add(pres.Slides.Count + 1, ppLayoutBlank)

    ' 画像を元の大きさで挿入（Width/Height に -1 を指定）
    Set shp = sld.Shapes.AddPicture(FileName:=imgPath, LinkToFile:=msoFalse, _
                                    SaveWithDocument:=msoTrue, Left:=0, Top:=0, Width:=-1, Height:=-1)
    If shp.Width <= 0 Or shp.Height <= 0 Then Err.Raise vbObjectError + 1, , "画像の大きさが取れません。"
    shp.LockAspectRatio = msoTrue   ' 縦横比を保つ（幅を変えると高さも比例する）

    ' スライドの9割に収まるよう倍率を決める（大きすぎる画像も小さすぎる画像もそろう）
    maxW = slideW * MARGIN_RATE
    maxH = slideH * MARGIN_RATE
    factor = maxW / shp.Width
    If maxH / shp.Height < factor Then factor = maxH / shp.Height
    shp.Width = shp.Width * factor   ' 高さは縦横比固定で自動的に変わる

    ' 中央に配置
    shp.Left = (slideW - shp.Width) / 2
    shp.Top = (slideH - shp.Height) / 2

    AddImageSlide = True
    Exit Function
Failed:
    ' 失敗したら、追加した空スライドを残さない
    If Not sld Is Nothing Then
        On Error Resume Next
        sld.Delete
        On Error GoTo 0
    End If
    AddImageSlide = False
End Function


' フォルダ直下の画像ファイル（jpg/jpeg/png/gif/bmp）を集めて名前順に並べる。
Private Function CollectImages(ByVal folderPath As String) As Collection
    Dim arr() As String, n As Long
    Dim fileName As String, ext As String, dotPos As Long
    Dim i As Long, j As Long, tmp As String
    Dim coll As Collection

    ' 一度だけ全ファイルを列挙して拡張子で選ぶ（*.jpg と *.jpeg の二重取りを防ぐ）
    n = 0
    fileName = Dir$(folderPath & "*.*")
    Do While Len(fileName) > 0
        dotPos = InStrRev(fileName, ".")
        If dotPos > 0 Then
            ext = LCase$(Mid$(fileName, dotPos + 1))
            Select Case ext
                Case "jpg", "jpeg", "png", "gif", "bmp"
                    n = n + 1
                    ReDim Preserve arr(1 To n)
                    arr(n) = fileName
            End Select
        End If
        fileName = Dir$
    Loop

    ' 名前順に並べ替え（単純な挿入ソート）
    For i = 2 To n
        tmp = arr(i)
        j = i - 1
        Do While j >= 1
            If StrComp(arr(j), tmp, vbTextCompare) <= 0 Then Exit Do
            arr(j + 1) = arr(j)
            j = j - 1
        Loop
        arr(j + 1) = tmp
    Next i

    Set coll = New Collection
    For i = 1 To n
        coll.Add folderPath & arr(i)   ' フルパスで入れる
    Next i
    Set CollectImages = coll
End Function

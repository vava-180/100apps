Attribute VB_Name = "ExportRangeToPpt"
Option Explicit

' ============================================================
' 表をPowerPointスライドへ自動転記マクロ（Day 056 / Excel VBA）
'
' Excelで選んだ範囲を、新しいPowerPointのスライドに「図」として貼り付けます。
' 報告資料づくりで、表をスライドに載せる手間を減らします。
'
' しくみ:
'   - Excelから PowerPoint を起動（ローカルのアプリ操作。ネット通信はしません）
'   - 新しいプレゼンに白紙スライドを1枚追加し、選んだ範囲を「図」として貼り付け
'   - スライドの中央に配置します
'
' 使い方:
'   1) Excelでスライドに載せたい範囲を選ぶ（ひと続きの範囲）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → ExportRangeToPpt を実行
'
' 注意: PowerPoint がインストールされている必要があります。
'       貼り付けは「図」です（PowerPoint側で表の文字を編集することはできません）。
' ============================================================

' PowerPointの定数（遅延バインディングなので数値で指定）
Private Const ppLayoutBlank As Long = 12
' 1度に図にできるセル数の上限（大きすぎると重い・失敗しやすい）
Private Const MAX_CELLS As Long = 20000

Sub ExportRangeToPpt()
    Dim rng As Range
    Dim ppt As Object, pres As Object, sld As Object, shr As Object
    Dim createdPres As Boolean
    Dim i As Long

    If TypeName(Selection) <> "Range" Then
        MsgBox "PowerPointに載せたい範囲（セル）を選んでから実行してください。", vbExclamation
        Exit Sub
    End If
    Set rng = Selection
    If rng.Areas.Count > 1 Then
        MsgBox "ひと続きの範囲を選んでください（バラバラ選択は不可）。", vbExclamation
        Exit Sub
    End If
    If rng.Cells.CountLarge > MAX_CELLS Then
        MsgBox "範囲が大きすぎます（" & MAX_CELLS & " セル以内にしてください）。", vbExclamation
        Exit Sub
    End If

    If MsgBox(rng.Address & " を新しいPowerPointのスライドに図として貼り付けます。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    ' PowerPoint を起動（ここで失敗したら専用メッセージ）
    On Error GoTo NoPpt
    Set ppt = CreateObject("PowerPoint.Application")
    ppt.Visible = True
    On Error GoTo CleanFail

    ' 新しいプレゼン＋白紙スライド
    Set pres = ppt.Presentations.Add
    createdPres = True
    Set sld = pres.Slides.Add(1, ppLayoutBlank)

    ' Excelの範囲を「図」としてコピー（表や埋め込みではなく画像で確実に）
    rng.CopyPicture Appearance:=xlScreen, Format:=xlPicture
    DoEvents

    ' スライドに貼り付け（クリップボードのタイミングずれに備えて数回試す）
    Set shr = Nothing
    For i = 1 To 5
        On Error Resume Next
        Set shr = sld.Shapes.Paste
        On Error GoTo CleanFail
        If Not shr Is Nothing Then Exit For
        DoEvents
    Next i
    If shr Is Nothing Then Err.Raise vbObjectError + 1, , "スライドに貼り付けできませんでした。"

    Application.CutCopyMode = False

    ' 貼り付けた図をスライド中央に配置（Pasteの戻り値で確実に取得）
    shr.Left = (pres.PageSetup.SlideWidth - shr.Width) / 2
    shr.Top = (pres.PageSetup.SlideHeight - shr.Height) / 2

    On Error Resume Next
    ppt.Activate
    On Error GoTo 0

    MsgBox "PowerPointのスライドに貼り付けました。", vbInformation, "結果"
    Exit Sub

NoPpt:
    MsgBox "PowerPointを起動できませんでした。" & vbCrLf & _
           "PowerPointがインストールされているか確認してください。" & vbCrLf & Err.Description, _
           vbCritical, "エラー"
    Exit Sub

CleanFail:
    Application.CutCopyMode = False
    ' 自分が作った空のプレゼンは、保存せず閉じる（PowerPoint自体は閉じない）
    On Error Resume Next
    If createdPres And Not pres Is Nothing Then pres.Close
    On Error GoTo 0
    MsgBox "うまく転記できませんでした。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub

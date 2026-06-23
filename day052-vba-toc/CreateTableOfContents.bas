Attribute VB_Name = "CreateTableOfContents"
Option Explicit

' ============================================================
' ブック内ハイパーリンク目次マクロ（Day 052）
'
' ブックの中のすべてのシートへ飛べる「目次」シートを作ります。
' 目次の各行はハイパーリンクになっていて、クリックするとそのシートのA1へ移動します。
'   - 目次シートは先頭に作ります（名前は「目次」）
'   - すでに「目次」シートがあれば、中身を作り直します
'
' 使い方:
'   1) 目次を作りたいブックを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → CreateTableOfContents を実行
' ============================================================

Private Const TOC_NAME As String = "目次"

Sub CreateTableOfContents()
    Dim wb As Workbook
    Dim ws As Worksheet, toc As Worksheet
    Dim existing As Object
    Dim r As Long, listed As Long, hiddenSkipped As Long
    Dim oldScreenUpdating As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set wb = ActiveWorkbook

    ' 「目次」という名前のシートが既にある場合、ワークシートでなければ中止（名前衝突を避ける）
    On Error Resume Next
    Set existing = wb.Sheets(TOC_NAME)
    On Error GoTo 0
    If Not existing Is Nothing Then
        If TypeName(existing) <> "Worksheet" Then
            MsgBox "「" & TOC_NAME & "」という名前のシートがありますが、ワークシートではありません。" & vbCrLf & _
                   "名前を変えるか削除してから実行してください。", vbExclamation
            Exit Sub
        End If
    End If

    If MsgBox("このブックに「" & TOC_NAME & "」シートを作り、表示中の全ワークシートへのリンクを並べます。" & vbCrLf & _
              "（同名シートがあれば中身を作り直します。非表示シートとグラフシートは対象外）よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    ' 目次シートを用意（あれば中身を消して再利用、無ければ先頭に作る）
    Set toc = GetSheet(wb, TOC_NAME)
    If toc Is Nothing Then
        Set toc = wb.Worksheets.Add(Before:=wb.Worksheets(1))
        toc.Name = TOC_NAME
    Else
        toc.Cells.Clear
        If toc.Index <> 1 Then toc.Move Before:=wb.Worksheets(1)   ' 先頭でなければ先頭へ
    End If

    ' 見出し
    toc.Range("A1").Value = TOC_NAME
    toc.Range("A1").Font.Bold = True

    ' 各シートへのリンクを並べる（目次自身と非表示シートは除く）
    r = 2
    listed = 0
    hiddenSkipped = 0
    For Each ws In wb.Worksheets
        If ws.Name <> TOC_NAME Then
            If ws.Visible = xlSheetVisible Then
                ' 内部リンク。シート名のアポストロフィは '' に二重化してエスケープ
                ' （\ / ? * [ ] : はシート名に使えないので、追加のエスケープは不要）
                toc.Hyperlinks.Add _
                    Anchor:=toc.Cells(r, 1), _
                    Address:="", _
                    SubAddress:="'" & Replace(ws.Name, "'", "''") & "'!A1", _
                    TextToDisplay:=ws.Name
                r = r + 1
                listed = listed + 1
            Else
                hiddenSkipped = hiddenSkipped + 1   ' 非表示シートはリンク切れになるので外す
            End If
        End If
    Next ws

    ' 表示の調整は、失敗しても本体（目次作成）は成功扱いにする
    On Error Resume Next
    toc.Columns("A").AutoFit
    toc.Activate
    toc.Range("A1").Select
    On Error GoTo 0

    Application.ScreenUpdating = oldScreenUpdating
    If listed = 0 Then
        MsgBox "目次に並べる表示シートがありませんでした。", vbInformation, "結果"
    Else
        MsgBox "目次を作りました。" & vbCrLf & _
               "並べたシート: " & listed & " 枚 / 非表示で外した: " & hiddenSkipped & " 枚", vbInformation, "結果"
    End If
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' シートを名前で取得（無ければ Nothing）。
Private Function GetSheet(wb As Workbook, ByVal nm As String) As Worksheet
    On Error Resume Next
    Set GetSheet = wb.Worksheets(nm)
    On Error GoTo 0
End Function

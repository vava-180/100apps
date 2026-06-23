Attribute VB_Name = "AddFurigana"
Option Explicit

' ============================================================
' ふりがな自動付与マクロ（Day 045）
'
' 選んだ1列（氏名など）の読み（ふりがな）を求めて、すぐ右の列に書き出します。
' カタカナ／ひらがな を選べます。
'   例: B列に氏名 → C列にふりがな
'
' しくみ:
'   - Excelの Application.GetPhonetic で、漢字の読み（カタカナ）を取得する
'   - ひらがなにしたいときは StrConv(..., vbHiragana) で変換する
'   - 右の列にすでに値があるときは、上書きするか確認する
'
' 使い方:
'   1) 氏名などが入った「1列分」を選ぶ（見出しも処理対象。不要なら選択から外してください）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → AddFurigana を実行
'   4) 1（カタカナ）か 2（ひらがな）を選ぶ
'
' 注意: 読みはExcel/IMEの辞書による推定です。人名などは読み違いが出ることがあります。
' ============================================================

Sub AddFurigana()
    Dim ws As Worksheet
    Dim target As Range, cell As Range
    Dim kana As String
    Dim reading As String
    Dim added As Long, skipped As Long, failed As Long
    Dim hasExisting As Boolean, ok As Boolean
    Dim oldScreenUpdating As Boolean

    ' 前提チェック
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    If TypeName(Selection) <> "Range" Then
        MsgBox "氏名などが入った1列を選んでから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    ' 1つのまとまり・1列だけの選択に限定する（右の列へ書くため）
    If Selection.Areas.Count <> 1 Then
        MsgBox "ひと続きの1列を選んでください（バラバラ選択は不可）。", vbExclamation
        Exit Sub
    End If
    If Selection.Columns.Count <> 1 Then
        MsgBox "1列だけを選んでください（右の列にふりがなを書きます）。", vbExclamation
        Exit Sub
    End If
    ' 一番右の列(XFD)だと右隣が無いので書けない
    If Selection.Column >= ws.Columns.Count Then
        MsgBox "一番右の列は選べません（ふりがなを書く右の列がありません）。", vbExclamation
        Exit Sub
    End If

    ' 選択が列全体などで広すぎる場合は、使用範囲との重なりだけにしぼる
    Set target = Intersect(Selection, ws.UsedRange)
    If target Is Nothing Then
        MsgBox "対象のセルがありません。", vbInformation
        Exit Sub
    End If

    ' カタカナ／ひらがなを選ぶ
    kana = Trim$(InputBox("ふりがなの種類を選んでください。" & vbCrLf & _
                          "  1 = カタカナ" & vbCrLf & _
                          "  2 = ひらがな", "ふりがなの種類", "1"))
    If kana <> "1" And kana <> "2" Then
        If Len(kana) > 0 Then MsgBox "1 か 2 を入力してください。", vbExclamation
        Exit Sub
    End If

    ' 右の列にすでに値があるか確認する（元セルが空でない行だけを見る）
    hasExisting = False
    For Each cell In target.Cells
        If Not IsError(cell.Value) Then
            If Len(CStr(cell.Value)) > 0 And Len(SafeText(cell.Offset(0, 1))) > 0 Then
                hasExisting = True
                Exit For
            End If
        End If
    Next cell
    If hasExisting Then
        If MsgBox(target.Offset(0, 1).Address(False, False) & " にすでに値があります。上書きしますか？", _
                  vbYesNo + vbExclamation, "上書きの確認") <> vbYes Then Exit Sub
    End If

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    added = 0
    skipped = 0
    failed = 0
    For Each cell In target.Cells
        If IsError(cell.Value) Then
            failed = failed + 1                 ' エラー値のセルは飛ばす
        ElseIf Len(CStr(cell.Value)) = 0 Then
            skipped = skipped + 1               ' 空セルは飛ばす
        Else
            ok = True
            On Error Resume Next                ' このセルの読み取得だけ、失敗を許容する
            reading = Application.GetPhonetic(CStr(cell.Value))
            If Err.Number <> 0 Then ok = False
            Err.Clear
            On Error GoTo CleanFail
            If ok Then
                If kana = "2" Then reading = StrConv(reading, vbHiragana)
                cell.Offset(0, 1).Value = reading
                added = added + 1
            Else
                failed = failed + 1
            End If
        End If
    Next cell

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "ふりがなを付けました（自動推定なので、内容は必ずご確認ください）。" & vbCrLf & _
           "付けた: " & added & " 個 / 空で飛ばした: " & skipped & " 個 / 取得できず: " & failed & " 個", _
           vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' セルの値を安全に文字列にする（エラー値なら空文字を返す）。
Private Function SafeText(c As Range) As String
    If IsError(c.Value) Then
        SafeText = ""
    Else
        SafeText = CStr(c.Value)
    End If
End Function

Attribute VB_Name = "FormatCells"
Option Explicit

' ============================================================
' セル文字の一括整形マクロ（Day 044）
'
' 選んだ範囲（選んでいなければシートの使用範囲）の「文字が入ったセル」だけを対象に、
' 次のどれかの整形をまとめて行います:
'   1) トリム      … 前後の空白を消し、間の連続空白を1つにする（全角スペースも対象）
'   2) 全角→半角   … 英数字・カタカナ・記号を半角にそろえる
'   3) 半角→全角   … 英数字・カタカナ・記号を全角にそろえる
'   4) トリム＋全角→半角（よく使う組み合わせ）
'
' 数式が入ったセルは触りません（壊さないため）。数値セルも対象外（文字だけ整えます）。
'
' 使い方:
'   1) 整えたい範囲を選ぶ（選ばなければシート全体の使用範囲が対象）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → FormatCells を実行
'   4) 1～4 のモードを選ぶ
' ============================================================

Sub FormatCells()
    Dim ws As Worksheet
    Dim target As Range, textCells As Range, cell As Range
    Dim mode As String
    Dim changed As Long
    Dim s As String, t As String
    Dim oldScreenUpdating As Boolean

    ' 前提チェック：通常のワークシートが開いていること
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    ' 対象範囲を決める：範囲を選んでいればその選択（1セルでもOK）、そうでなければ使用範囲
    If TypeName(Selection) = "Range" Then
        Set target = Selection
    Else
        Set target = ws.UsedRange
    End If
    If target Is Nothing Then
        MsgBox "対象のセルがありません。", vbInformation
        Exit Sub
    End If

    ' 対象範囲のうち「文字の定数セル」だけを取り出す（数式・数値・空セルは除く）
    On Error Resume Next
    Set textCells = target.SpecialCells(xlCellTypeConstants, xlTextValues)
    Err.Clear
    On Error GoTo CleanFail
    If textCells Is Nothing Then
        MsgBox "整形できる文字セルが見つかりませんでした。", vbInformation
        Exit Sub
    End If

    ' モードを選んでもらう
    mode = Trim$(InputBox("文字の整え方を選んでください。" & vbCrLf & _
                          "  1 = トリム（前後の空白を消し、間の連続空白を1つに）" & vbCrLf & _
                          "  2 = 全角→半角（英数字・カナ・記号すべてを半角に）" & vbCrLf & _
                          "  3 = 半角→全角（英数字・カナ・記号すべてを全角に）" & vbCrLf & _
                          "  4 = トリム＋全角→半角", "セル文字の整形", "1"))
    If mode <> "1" And mode <> "2" And mode <> "3" And mode <> "4" Then
        If Len(mode) > 0 Then MsgBox "1～4 の番号を入力してください。", vbExclamation
        Exit Sub
    End If

    If MsgBox(textCells.Cells.CountLarge & " 個の文字セルを整形します。元に戻せないので、" & _
              "必要なら先に保存してください。" & vbCrLf & _
              "※ 2・3・4は英数字だけでなくカナ・記号も変換されます。実行しますか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    changed = 0
    For Each cell In textCells.Cells
        s = CStr(cell.Value2)   ' .Value2 は表示形式に左右されない「セルの中身」
        t = TransformText(s, mode)
        If t <> s Then
            ' = + - @ で始まる文字は、再代入で数式と解釈されないよう、書式を文字列にしてから書く
            If Len(t) > 0 And InStr("=+-@", Left$(t, 1)) > 0 Then cell.NumberFormat = "@"
            cell.Value2 = t
            changed = changed + 1
        End If
    Next cell

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "整形しました。" & vbCrLf & "変更したセル: " & changed & " 個", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' モードに応じて文字を整える。
Private Function TransformText(ByVal s As String, ByVal mode As String) As String
    Select Case mode
        Case "1": TransformText = NormalizeSpaces(s)
        Case "2": TransformText = StrConv(s, vbNarrow)                 ' 全角→半角
        Case "3": TransformText = StrConv(s, vbWide)                   ' 半角→全角
        Case "4": TransformText = NormalizeSpaces(StrConv(s, vbNarrow)) ' 先に全角→半角、その後に空白整理
        Case Else: TransformText = s
    End Select
End Function


' 前後の空白を消し、間の連続空白を1つにまとめる（全角スペース・タブも半角スペース扱い）。
Private Function NormalizeSpaces(ByVal s As String) As String
    s = Replace(s, ChrW$(&H3000), " ")   ' 全角スペース→半角スペース
    s = Replace(s, ChrW$(&HA0), " ")     ' ノーブレークスペース→半角スペース
    s = Replace(s, vbTab, " ")           ' タブ→半角スペース（改行は残す）
    ' 連続する空白を1つに（2個の空白が無くなるまで繰り返す）
    Do While InStr(s, "  ") > 0
        s = Replace(s, "  ", " ")
    Loop
    NormalizeSpaces = Trim$(s)
End Function

Attribute VB_Name = "CreateSheetsFromList"
Option Explicit

' ============================================================
' 名簿からシート一括作成マクロ（Day 041）
'
' いま開いているシート（名簿）の A列・2行目以降の値をシート名にして、
' 1行＝1枚のシートをまとめて作ります。
'   例: A2=営業部, A3=開発部 … → 「営業部」「開発部」…のシートができる
'
' シート名のルール（Excelの制限）に合わせて自動で整えます:
'   - 使えない文字 \ / ? * [ ] : は _ に置き換え
'   - タブ・改行・全角スペースなどは半角スペースにして前後をトリム
'   - 31文字を超える分は切り詰め
'   - 予約名 "History" は使えないので "History_" にする
'   - 同じ名前は (2)(3)… を付けて重複を避ける
'   - 空欄・エラー値の行は飛ばす
'
' 使い方:
'   1) 名簿シートを開く（A1は見出し、A2以降にシート名のもとを入れる）
'   2) Alt+F11 でVBE → このファイルをインポート（または中身を標準モジュールに貼り付け）
'   3) Alt+F8 → CreateSheetsFromList を実行
' ============================================================

Sub CreateSheetsFromList()
    Dim wb As Workbook
    Dim wsList As Worksheet
    Dim lastRow As Long, i As Long
    Dim rawName As String, newName As String
    Dim created As Long, skippedEmpty As Long, skippedError As Long
    Dim oldScreenUpdating As Boolean
    Dim cellVal As Variant

    ' 前提チェック：ブックが開いていて、いまが通常のワークシートであること
    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    If TypeName(ActiveSheet) <> "Worksheet" Then
        MsgBox "名簿となる通常のワークシートを開いてから実行してください。", vbExclamation
        Exit Sub
    End If

    Set wb = ActiveWorkbook
    Set wsList = ActiveSheet  ' いま開いているシートを「名簿」として使う

    ' A列の一番下の入力行を調べる
    lastRow = wsList.Cells(wsList.Rows.Count, 1).End(xlUp).Row
    If lastRow < 2 Then
        MsgBox "A列の2行目以降に、シート名のもとになる値を入れてください。", vbExclamation
        Exit Sub
    End If

    If MsgBox("A列の 2～" & lastRow & " 行目から、シートを一括作成します。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then
        Exit Sub
    End If

    ' 元の画面更新状態を覚えておき、終わったら必ず戻す
    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    created = 0
    skippedEmpty = 0
    skippedError = 0

    For i = 2 To lastRow
        cellVal = wsList.Cells(i, 1).Value
        If IsError(cellVal) Then
            skippedError = skippedError + 1          ' #N/A などのエラー値の行
        Else
            rawName = Trim$(CStr(cellVal))
            If Len(rawName) = 0 Then
                skippedEmpty = skippedEmpty + 1       ' 空欄の行
            ElseIf AddNamedSheet(wb, UniqueSheetName(wb, SanitizeSheetName(rawName))) Then
                created = created + 1
            Else
                skippedError = skippedError + 1        ' 名前を付けられなかった行
            End If
        End If
    Next i

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "完了しました。" & vbCrLf & _
           "作成: " & created & " シート" & vbCrLf & _
           "空欄で飛ばした行: " & skippedEmpty & " 件" & vbCrLf & _
           "エラーで飛ばした行: " & skippedError & " 件", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中で予期しないエラーが発生しました（" & created & " シート作成済み）。" & vbCrLf & _
           Err.Description, vbCritical, "エラー"
End Sub


' シートを1枚追加して名前を付ける。成功なら True。失敗したら追加した空シートを消して False。
Function AddNamedSheet(wb As Workbook, ByVal nm As String) As Boolean
    Dim ws As Worksheet
    On Error GoTo Failed
    Set ws = wb.Worksheets.Add(After:=wb.Worksheets(wb.Worksheets.Count))
    ws.Name = nm
    AddNamedSheet = True
    Exit Function
Failed:
    AddNamedSheet = False
    If Not ws Is Nothing Then
        ' 名前を付けられなかったときは、できた空シートを残さない
        Application.DisplayAlerts = False
        ws.Delete
        Application.DisplayAlerts = True
    End If
End Function


' シート名に使えない文字を整え、31文字までに収める。空なら "シート"。
Function SanitizeSheetName(ByVal s As String) As String
    Dim bad As Variant, ch As Variant

    ' 使えない記号は _ に置き換え
    bad = Array("\", "/", "?", "*", "[", "]", ":")
    For Each ch In bad
        s = Replace(s, CStr(ch), "_")
    Next ch

    ' タブ・改行・全角スペース・ノーブレークスペースは半角スペースにそろえる
    s = Replace(s, vbTab, " ")
    s = Replace(s, vbCr, " ")
    s = Replace(s, vbLf, " ")
    s = Replace(s, ChrW$(&H3000), " ")   ' 全角スペース
    s = Replace(s, ChrW$(&HA0), " ")     ' ノーブレークスペース

    s = Trim$(s)
    If Len(s) > 31 Then s = Left$(s, 31)

    ' 先頭・末尾のアポストロフィと空白はシート名に使えないので取り除く
    Do While Len(s) > 0 And (Left$(s, 1) = "'" Or Left$(s, 1) = " ")
        s = Mid$(s, 2)
    Loop
    Do While Len(s) > 0 And (Right$(s, 1) = "'" Or Right$(s, 1) = " ")
        s = Left$(s, Len(s) - 1)
    Loop

    If Len(s) = 0 Then s = "シート"
    ' "History" はExcelの予約名でシート名に使えないので避ける
    If StrComp(s, "History", vbTextCompare) = 0 Then s = "History_"

    SanitizeSheetName = s
End Function


' そのシート名が既に存在するか
Function SheetExists(wb As Workbook, ByVal nm As String) As Boolean
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = wb.Worksheets(nm)
    On Error GoTo 0
    SheetExists = Not (ws Is Nothing)
End Function


' 既存と重ならない名前にする。(2)(3)… を付けても31文字を超えないよう本体を削る。
Function UniqueSheetName(wb As Workbook, ByVal baseName As String) As String
    Dim cand As String, suffix As String, head As String
    Dim n As Long

    If Not SheetExists(wb, baseName) Then
        UniqueSheetName = baseName
        Exit Function
    End If

    n = 2
    Do
        suffix = "(" & n & ")"
        If Len(baseName) + Len(suffix) > 31 Then
            head = Left$(baseName, 31 - Len(suffix))
        Else
            head = baseName
        End If
        cand = head & suffix
        n = n + 1
    Loop While SheetExists(wb, cand)

    UniqueSheetName = cand
End Function

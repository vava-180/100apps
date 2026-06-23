Attribute VB_Name = "GenerateInvoices"
Option Explicit

' ============================================================
' 請求書テンプレ一括出力マクロ（Day 048）
'
' 同じブックの中にある2つのシートから、請求書を件数分まとめて作ります。
'   - 「請求データ」シート … 1行＝1件。1行目が見出し（例: 請求先 / 件名 / 金額）
'   - 「テンプレート」シート … セルに {請求先} {件名} {金額} {発行日} のような差し込み記号を書く
'
' 動き:
'   - 1件ごとに「テンプレート」を複製し、{見出し名} をその行の値に差し替える
'   - {発行日} は今日の日付に差し替える
'   - セル全体がちょうど {見出し名} のときは、値の型（数値・日付）を保って差し込む
'   - シート名は「請求先」の値（無ければ連番）。Excelの制限に合わせて自動調整
'   - 結果は新しいブックに出力（保存はユーザーが行う）。元のデータは変えません
'
' 使い方:
'   1) 「請求データ」「テンプレート」シートがあるブックを開く
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → GenerateInvoices を実行
'
' 注意: 数式セルの中の {…} は差し込みません（数式を壊さないため）。
' ============================================================

Private Const INVALID_SHEET As String = "\/?*[]:"
Private Const MAX_SHEET_LEN As Long = 31

Sub GenerateInvoices()
    Dim srcWb As Workbook, outWb As Workbook
    Dim dataWs As Worksheet, tmplWs As Worksheet, newWs As Worksheet
    Dim headers As Variant
    Dim lastRow As Long, lastCol As Long, r As Long, c As Long
    Dim keyCol As Long, made As Long, skipped As Long, warnUnknown As Long
    Dim issueDate As String, baseName As String
    Dim hadUnknown As Boolean
    Dim oldScreenUpdating As Boolean, oldEvents As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set srcWb = ActiveWorkbook
    Set dataWs = GetSheet(srcWb, "請求データ")
    Set tmplWs = GetSheet(srcWb, "テンプレート")
    If dataWs Is Nothing Or tmplWs Is Nothing Then
        MsgBox "このブックに「請求データ」と「テンプレート」の両方のシートが必要です。", vbExclamation
        Exit Sub
    End If

    ' 見出しとデータ範囲
    lastCol = dataWs.Cells(1, dataWs.Columns.Count).End(xlToLeft).Column
    lastRow = SheetLastRow(dataWs)   ' A列だけでなくシート全体から最終行を取る
    If lastCol < 1 Or lastRow < 2 Then
        MsgBox "「請求データ」は1行目に見出し、2行目以降にデータを入れてください。", vbExclamation
        Exit Sub
    End If
    ReDim headers(1 To lastCol)
    For c = 1 To lastCol
        headers(c) = CStr(dataWs.Cells(1, c).Value)
        If Len(Trim$(headers(c))) = 0 Then
            MsgBox "「請求データ」の見出しに空の列があります。見出しをすべて入れてください。", vbExclamation
            Exit Sub
        End If
    Next c
    keyCol = HeaderIndex(headers, "請求先")   ' シート名に使う列（無ければ 0）

    If MsgBox((lastRow - 1) & " 行ぶんの請求書を作ります。よろしいですか？", _
              vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    oldEvents = Application.EnableEvents
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    On Error GoTo CleanFail

    issueDate = Format$(Date, "yyyy/mm/dd")
    Set outWb = Workbooks.Add

    made = 0: skipped = 0: warnUnknown = 0
    For r = 2 To lastRow
        If RowIsEmpty(dataWs, r, lastCol) Then
            skipped = skipped + 1
        Else
            tmplWs.Copy After:=outWb.Worksheets(outWb.Worksheets.Count)
            Set newWs = outWb.Worksheets(outWb.Worksheets.Count)

            If keyCol > 0 Then
                baseName = CStr(dataWs.Cells(r, keyCol).Value)
            Else
                baseName = "請求書" & (r - 1)
            End If
            newWs.Name = UniqueSheetName(outWb, SanitizeSheetName(baseName))

            hadUnknown = False
            FillTemplate newWs, dataWs, r, headers, lastCol, issueDate, hadUnknown
            If hadUnknown Then warnUnknown = warnUnknown + 1
            made = made + 1
        End If
    Next r

    RemoveDefaultSheet outWb

    Application.ScreenUpdating = oldScreenUpdating
    Application.EnableEvents = oldEvents
    MsgBox "請求書を作りました。" & vbCrLf & _
           "作成: " & made & " 件 / 空で飛ばした: " & skipped & " 件" & vbCrLf & _
           "差し込めない記号 {…} が残った請求書: " & warnUnknown & " 件" & vbCrLf & _
           "新しいブックに出力しました（保存してください）。", vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    Application.EnableEvents = oldEvents
    MsgBox "途中でエラーが発生しました（" & made & " 件作成済み）。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 1枚の請求書シートの {見出し名} と {発行日} を、その行の値に置き換える。
' セル全体がちょうど {見出し名} のときは、値の型を保って差し込む。
Private Sub FillTemplate(ws As Worksheet, dataWs As Worksheet, ByVal r As Long, _
                         ByVal headers As Variant, ByVal lastCol As Long, _
                         ByVal issueDate As String, ByRef hadUnknown As Boolean)
    Dim cell As Range, s As String, whole As String, newS As String
    Dim idx As Long
    If ws.UsedRange Is Nothing Then Exit Sub
    For Each cell In ws.UsedRange.Cells
        If Not cell.HasFormula Then
            If VarType(cell.Value) = vbString Then
                s = CStr(cell.Value)
                If InStr(s, "{") > 0 Then
                    whole = WholeKey(s)
                    If Len(whole) > 0 Then
                        ' セル全体が1つの差し込み記号 → 型を保って入れる
                        If whole = "発行日" Then
                            cell.Value = issueDate
                        Else
                            idx = HeaderIndex(headers, whole)
                            If idx > 0 Then
                                cell.Value = dataWs.Cells(r, idx).Value   ' 数値・日付などをそのまま
                            Else
                                hadUnknown = True                        ' 未知キーは残す
                            End If
                        End If
                    Else
                        ' 文中に差し込み記号がある → 1パスで置換（二重差し込みしない）
                        newS = FillString(s, headers, lastCol, dataWs, r, issueDate, hadUnknown)
                        If newS <> s Then
                            If Len(newS) > 0 Then
                                If InStr("=+-@", Left$(newS, 1)) > 0 Then cell.NumberFormat = "@"
                            End If
                            cell.Value = newS
                        End If
                    End If
                End If
            End If
        End If
    Next cell
End Sub


' 文字列を1回だけ走査して {…} を値に置き換える。差し込んだ値は再走査しない。
Private Function FillString(ByVal s As String, ByRef headers As Variant, ByVal lastCol As Long, _
                            dataWs As Worksheet, ByVal r As Long, ByVal issueDate As String, _
                            ByRef hadUnknown As Boolean) As String
    Dim result As String, token As String
    Dim i As Long, q As Long
    i = 1
    Do While i <= Len(s)
        If Mid$(s, i, 1) = "{" Then
            q = InStr(i + 1, s, "}")
            If q = 0 Then
                result = result & Mid$(s, i)   ' 閉じ括弧が無ければ残りはそのまま
                Exit Do
            End If
            token = Mid$(s, i + 1, q - i - 1)
            result = result & LookupToken(token, headers, lastCol, dataWs, r, issueDate, hadUnknown)
            i = q + 1
        Else
            result = result & Mid$(s, i, 1)
            i = i + 1
        End If
    Loop
    FillString = result
End Function


' 差し込み記号1つ（token）を値に変換する。未知なら {token} のまま残す。
Private Function LookupToken(ByVal token As String, ByRef headers As Variant, ByVal lastCol As Long, _
                             dataWs As Worksheet, ByVal r As Long, ByVal issueDate As String, _
                             ByRef hadUnknown As Boolean) As String
    Dim c As Long
    If token = "発行日" Then
        LookupToken = issueDate
        Exit Function
    End If
    For c = 1 To lastCol
        If StrComp(CStr(headers(c)), token, vbTextCompare) = 0 Then
            LookupToken = CStr(dataWs.Cells(r, c).Value)
            Exit Function
        End If
    Next c
    hadUnknown = True
    LookupToken = "{" & token & "}"
End Function


' 文字列がちょうど "{キー}" 1つだけのとき、その中身（キー）を返す。違えば ""。
Private Function WholeKey(ByVal s As String) As String
    If Len(s) < 3 Then Exit Function
    If Left$(s, 1) <> "{" Or Right$(s, 1) <> "}" Then Exit Function
    If InStr(2, s, "{") > 0 Then Exit Function          ' 途中に別の { があれば全体キーではない
    If InStr(s, "}") <> Len(s) Then Exit Function        ' } が末尾以外にあれば全体キーではない
    WholeKey = Mid$(s, 2, Len(s) - 2)
End Function


' シートを名前で取得（無ければ Nothing）。
Private Function GetSheet(wb As Workbook, ByVal nm As String) As Worksheet
    On Error Resume Next
    Set GetSheet = wb.Worksheets(nm)
    On Error GoTo 0
End Function


' 見出し配列から name の位置（1始まり）を返す。無ければ 0。
Private Function HeaderIndex(ByVal headers As Variant, ByVal name As String) As Long
    Dim i As Long
    For i = LBound(headers) To UBound(headers)
        If StrComp(CStr(headers(i)), name, vbTextCompare) = 0 Then
            HeaderIndex = i
            Exit Function
        End If
    Next i
    HeaderIndex = 0
End Function


' その行が全列とも空かどうか
Private Function RowIsEmpty(ws As Worksheet, r As Long, lastCol As Long) As Boolean
    Dim c As Long
    For c = 1 To lastCol
        If Len(CStr(ws.Cells(r, c).Value)) > 0 Then
            RowIsEmpty = False
            Exit Function
        End If
    Next c
    RowIsEmpty = True
End Function


' シート全体の最終行（どの列にデータがあっても拾う）。空なら 0。
Private Function SheetLastRow(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlPrevious, MatchCase:=False)
    If f Is Nothing Then SheetLastRow = 0 Else SheetLastRow = f.Row
End Function


' シート名に使えない文字を整え、31文字までに収める。空なら "請求書"。
Private Function SanitizeSheetName(ByVal s As String) As String
    Dim i As Long, badChar As String
    For i = 1 To Len(INVALID_SHEET)
        badChar = Mid$(INVALID_SHEET, i, 1)
        s = Replace(s, badChar, "_")
    Next i
    s = Trim$(s)
    If Len(s) > MAX_SHEET_LEN Then s = Left$(s, MAX_SHEET_LEN)
    Do While Len(s) > 0 And (Left$(s, 1) = "'" Or Left$(s, 1) = " ")
        s = Mid$(s, 2)
    Loop
    Do While Len(s) > 0 And (Right$(s, 1) = "'" Or Right$(s, 1) = " ")
        s = Left$(s, Len(s) - 1)
    Loop
    If Len(s) = 0 Then s = "請求書"
    If StrComp(s, "History", vbTextCompare) = 0 Then s = "History_"
    SanitizeSheetName = s
End Function


' 既存と重ならないシート名にする（大文字小文字は区別しない。31字に収める）。
Private Function UniqueSheetName(wb As Workbook, ByVal baseName As String) As String
    Dim cand As String, suffix As String, head As String, n As Long
    If Not SheetExists(wb, baseName) Then
        UniqueSheetName = baseName
        Exit Function
    End If
    n = 2
    Do
        suffix = "(" & n & ")"
        If Len(baseName) + Len(suffix) > MAX_SHEET_LEN Then
            head = Left$(baseName, MAX_SHEET_LEN - Len(suffix))
        Else
            head = baseName
        End If
        cand = head & suffix
        n = n + 1
    Loop While SheetExists(wb, cand)
    UniqueSheetName = cand
End Function


Private Function SheetExists(wb As Workbook, ByVal nm As String) As Boolean
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = wb.Worksheets(nm)
    On Error GoTo 0
    SheetExists = Not (ws Is Nothing)
End Function


' 出力ブックの最初にできる空シート（Sheet1など）を削除する。
Private Sub RemoveDefaultSheet(wb As Workbook)
    Dim ws As Worksheet
    Dim oldAlerts As Boolean
    If wb.Worksheets.Count <= 1 Then Exit Sub
    Set ws = wb.Worksheets(1)
    If ws Is Nothing Then Exit Sub
    If IsEmptySheet(ws) Then
        oldAlerts = Application.DisplayAlerts
        Application.DisplayAlerts = False
        On Error Resume Next
        ws.Delete
        On Error GoTo 0
        Application.DisplayAlerts = oldAlerts   ' 必ず元に戻す
    End If
End Sub


Private Function IsEmptySheet(ws As Worksheet) As Boolean
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, LookAt:=xlPart, _
                          SearchOrder:=xlByRows, SearchDirection:=xlNext)
    IsEmptySheet = (f Is Nothing)
End Function

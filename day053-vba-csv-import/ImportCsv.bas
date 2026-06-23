Attribute VB_Name = "ImportCsv"
Option Explicit

' ============================================================
' CSV取り込み整形マクロ（Day 053）
'
' CSVファイルを新しいシートに取り込み、見やすく整えます。
'   - すべて「文字列」として取り込むので、電話番号などの先頭ゼロが消えません
'   - 各セルの前後の空白をトリム（整形）
'   - 見出し（1行目）を太字・先頭行を固定・列幅を自動調整
'   - 文字コードは BOM で判定（UTF-8 / Shift-JIS）。ADODB（Windows標準）で読みます
'
' しくみ:
'   Excelの「CSVを開く」は先頭ゼロを消したり日付に変えたりすることがあります。
'   このマクロは全部を文字列として入れるので、元のCSVの見た目をそのまま保てます。
'
' 使い方:
'   1) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   2) Alt+F8 → ImportCsv を実行
'   3) CSVファイルのパスを入力
'
' 注意: 1セルの中に改行を含むCSV（セル内改行）は対応していません（1行=1レコード前提）。
'       空行は取り込みません。各セルは前後の空白をトリムします。
' ============================================================

Sub ImportCsv()
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim csvPath As String
    Dim allText As String
    Dim lines() As String
    Dim fields() As String
    Dim rowsColl As Collection
    Dim data() As String
    Dim rowCount As Long, colMax As Long
    Dim i As Long, j As Long
    Dim oldScreenUpdating As Boolean
    Dim createdSheet As Boolean

    If ActiveWorkbook Is Nothing Then
        MsgBox "ブックが開かれていません。", vbExclamation
        Exit Sub
    End If
    Set wb = ActiveWorkbook

    csvPath = Trim$(InputBox("取り込むCSVファイルのフルパスを入力してください。", "CSV取り込み"))
    If Len(csvPath) = 0 Then Exit Sub
    If Dir$(csvPath) = "" Then
        MsgBox "ファイルが見つかりません: " & csvPath, vbExclamation
        Exit Sub
    End If

    ' 画面更新の状態は、設定変更やエラーより前に覚えておく
    oldScreenUpdating = Application.ScreenUpdating
    createdSheet = False
    On Error GoTo CleanFail

    ' ファイルを読む（BOMでUTF-8かShift-JISかを判定）
    allText = ReadAllText(csvPath)
    If Len(allText) = 0 Then
        MsgBox "ファイルが空のようです。", vbInformation
        Exit Sub
    End If

    ' 改行で行に分ける（CRLF / LF / CR のどれでも）
    allText = Replace(allText, vbCrLf, vbLf)
    allText = Replace(allText, vbCr, vbLf)
    lines = Split(allText, vbLf)

    ' まず行を解析して、行数・最大列数を求める（空行は除外）
    Set rowsColl = New Collection
    colMax = 0
    For i = LBound(lines) To UBound(lines)
        If Len(lines(i)) > 0 Then
            fields = SplitCsvLine(lines(i))     ' 引用符が閉じていない行はここでエラーになる
            rowsColl.Add fields
            If (UBound(fields) + 1) > colMax Then colMax = UBound(fields) + 1
        End If
    Next i
    rowCount = rowsColl.Count

    If rowCount = 0 Then
        MsgBox "取り込むデータがありませんでした。", vbInformation
        Exit Sub
    End If
    ' Excelの上限を超えるCSVは取り込めない
    If rowCount > wb.Worksheets(1).Rows.Count Or colMax > wb.Worksheets(1).Columns.Count Then
        MsgBox "CSVが大きすぎて、1シートに収まりません。", vbExclamation
        Exit Sub
    End If

    Application.ScreenUpdating = False

    ' 新しいシートを作る（CSVのファイル名をもとに）
    Set ws = wb.Worksheets.Add(After:=wb.Worksheets(wb.Worksheets.Count))
    createdSheet = True
    ws.Name = UniqueSheetName(wb, SanitizeSheetName(BaseName(csvPath)))

    ' 値を2次元配列に詰めてから、一度に書き込む（1セルずつより速い）
    ReDim data(1 To rowCount, 1 To colMax)
    For i = 1 To rowCount
        fields = rowsColl.Item(i)
        For j = LBound(fields) To UBound(fields)
            data(i, j + 1) = Trim$(fields(j))   ' 前後の空白をトリム
        Next j
    Next i

    With ws.Range(ws.Cells(1, 1), ws.Cells(rowCount, colMax))
        .NumberFormat = "@"      ' 文字列書式（先頭ゼロや日付の自動変換を防ぐ）
        .Value = data
    End With

    ws.Rows(1).Font.Bold = True

    ' 表示の調整（先頭行固定・列幅）は失敗しても取り込み自体は成功扱いにする
    On Error Resume Next
    ws.Activate
    ws.Range("A2").Select
    ActiveWindow.FreezePanes = True
    ws.Range(ws.Columns(1), ws.Columns(colMax)).AutoFit
    On Error GoTo 0

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "CSVを取り込みました。" & vbCrLf & _
           rowCount & " 行 / " & colMax & " 列（すべて文字列として取り込みました）", vbInformation, "結果"
    Exit Sub

CleanFail:
    ' 途中で失敗したら、作りかけのシートを残さない
    If createdSheet And Not ws Is Nothing Then
        Application.DisplayAlerts = False
        ws.Delete
        Application.DisplayAlerts = True
    End If
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "取り込みに失敗しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' ファイルをテキストとして読む。先頭のBOMでUTF-8かShift-JISかを判定する。
Private Function ReadAllText(ByVal path As String) As String
    Dim st As Object
    Dim head() As Byte
    Dim charset As String
    Dim text As String

    On Error GoTo NoAdodb
    Set st = CreateObject("ADODB.Stream")
    On Error GoTo 0

    ' まず先頭3バイトを見てBOMを確認
    st.Type = 1                 ' 1 = バイナリ
    st.Open
    st.LoadFromFile path
    If st.Size = 0 Then
        st.Close
        ReadAllText = ""
        Exit Function
    End If
    If st.Size >= 3 Then head = st.Read(3) Else head = st.Read
    st.Close

    charset = "shift_jis"
    If UBound(head) >= 2 Then
        If head(0) = &HEF And head(1) = &HBB And head(2) = &HBF Then charset = "utf-8"
    End If

    Set st = CreateObject("ADODB.Stream")
    st.Type = 2                 ' 2 = テキスト
    st.charset = charset
    st.Open
    st.LoadFromFile path
    text = st.ReadText
    st.Close

    ' 先頭にBOM文字が残ることがあるので取り除く
    If Len(text) > 0 Then
        If Left$(text, 1) = ChrW$(&HFEFF) Then text = Mid$(text, 2)
    End If
    ReadAllText = text
    Exit Function

NoAdodb:
    Err.Raise vbObjectError + 1, "ReadAllText", _
              "ADODB.Stream が使えません（CSVの読み込みに必要です）。"
End Function


' CSVの1行を、カンマ区切り＋ダブルクォート対応で分割する。引用符が閉じていなければエラー。
Private Function SplitCsvLine(ByVal lineText As String) As String()
    Dim result() As String
    Dim count As Long, i As Long
    Dim ch As String, cur As String
    Dim inQuotes As Boolean

    ReDim result(0 To 0)
    count = 0
    inQuotes = False
    cur = ""

    For i = 1 To Len(lineText)
        ch = Mid$(lineText, i, 1)
        If ch = """" Then
            If inQuotes And i < Len(lineText) And Mid$(lineText, i + 1, 1) = """" Then
                cur = cur & """"          ' "" は1つの " として扱う
                i = i + 1
            Else
                inQuotes = Not inQuotes    ' クォートの開始／終了
            End If
        ElseIf ch = "," And Not inQuotes Then
            ReDim Preserve result(0 To count)
            result(count) = cur
            count = count + 1
            cur = ""
        Else
            cur = cur & ch
        End If
    Next i

    ' 行末でクォートが閉じていない＝セル内改行か壊れたCSV。安全のためエラーにする。
    If inQuotes Then
        Err.Raise vbObjectError + 2, "SplitCsvLine", _
                  "CSVの引用符（"")が閉じていない行があります（セル内改行は非対応）:" & vbCrLf & lineText
    End If

    ReDim Preserve result(0 To count)
    result(count) = cur
    SplitCsvLine = result
End Function


' パスからファイル名（拡張子なし）を取り出す。
Private Function BaseName(ByVal path As String) As String
    Dim nm As String, p As Long
    nm = path
    p = InStrRev(nm, "\")
    If p > 0 Then nm = Mid$(nm, p + 1)
    p = InStrRev(nm, ".")
    If p > 1 Then nm = Left$(nm, p - 1)
    BaseName = nm
End Function


' シート名に使えない文字を _ にし、31文字までに収める。空なら "CSV"。
Private Function SanitizeSheetName(ByVal s As String) As String
    Dim invalid As String, i As Long
    invalid = "\/?*[]:"
    For i = 1 To Len(invalid)
        s = Replace(s, Mid$(invalid, i, 1), "_")
    Next i
    s = Trim$(s)
    If Len(s) > 31 Then s = Left$(s, 31)
    If Len(s) = 0 Then s = "CSV"
    SanitizeSheetName = s
End Function


' 既存と重ならないシート名にする。
Private Function UniqueSheetName(wb As Workbook, ByVal baseName As String) As String
    Dim cand As String, suffix As String, n As Long
    cand = baseName
    n = 2
    Do While SheetExists(wb, cand)
        suffix = "(" & n & ")"
        cand = Left$(baseName, 31 - Len(suffix)) & suffix
        n = n + 1
    Loop
    UniqueSheetName = cand
End Function


Private Function SheetExists(wb As Workbook, ByVal nm As String) As Boolean
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = wb.Worksheets(nm)
    On Error GoTo 0
    SheetExists = Not (ws Is Nothing)
End Function

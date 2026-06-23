Attribute VB_Name = "ConsolidateWorkbooks"
Option Explicit

' ============================================================
' 複数ブック集約マクロ（Day 042）
'
' 指定フォルダの中にある複数のExcel（.xlsx）の「1枚目シート」のデータを、
' 1枚のシートに縦に積み上げて集約します。各行には「元ファイル」名を付けます。
'   例: 支店A.xlsx, 支店B.xlsx … を1つの一覧にまとめる
'
' しくみ:
'   - ファイル名を名前順に処理し、最初の「中身のある」ファイルの見出し（1行目）を採用
'   - 先頭に「元ファイル」列を足し、各ファイルの2行目以降のデータを下に積み上げる
'   - 元のブックは「読み取り専用」で開き、保存せずに閉じる（中身は変えない）
'   - 結果は新しいブックに出力（保存はユーザーが行う）
'
' 使い方:
'   1) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   2) Alt+F8 → ConsolidateWorkbooks を実行
'   3) 集約したいExcelが入ったフォルダのパスを入力
'
' 注意: 各ファイルの列の並びは同じ前提です（最初のファイルの見出しに合わせて読みます）。
'       列数がちがうファイルは「警告」として数え、最初の見出しの列数ぶんだけ読みます。
' ============================================================

Sub ConsolidateWorkbooks()
    Dim folderPath As String, fileName As String
    Dim fileList As Collection
    Dim outWb As Workbook, outWs As Worksheet
    Dim hCols As Long, outRow As Long
    Dim filesDone As Long, filesFailed As Long, filesEmpty As Long, filesWarn As Long
    Dim headerWritten As Boolean, overflow As Boolean
    Dim oldScreenUpdating As Boolean, oldEvents As Boolean
    Dim failReport As String, status As String
    Dim nm As Variant

    ' フォルダを入力してもらう（既定はこのブックのある場所）
    folderPath = Trim$(InputBox("集約するExcel(.xlsx)が入ったフォルダのパスを入力してください。", _
                                "フォルダ指定", ThisWorkbook.Path))
    If Len(folderPath) = 0 Then Exit Sub
    If Right$(folderPath, 1) <> "\" Then folderPath = folderPath & "\"
    If Dir$(folderPath, vbDirectory) = "" Then
        MsgBox "フォルダが見つかりません。", vbExclamation
        Exit Sub
    End If

    ' ファイル名を集めて名前順に並べる（見出しを採用するファイルを安定させる）
    Set fileList = CollectXlsxNames(folderPath)
    If fileList.Count = 0 Then
        MsgBox "フォルダの中に .xlsx が見つかりませんでした。", vbInformation
        Exit Sub
    End If

    If MsgBox(fileList.Count & " 個の .xlsx を1枚のシートにまとめます。よろしいですか？" & vbCrLf & _
              folderPath, vbYesNo + vbQuestion, "確認") <> vbYes Then Exit Sub

    oldScreenUpdating = Application.ScreenUpdating
    oldEvents = Application.EnableEvents
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    On Error GoTo CleanFail

    Set outWb = Workbooks.Add
    Set outWs = outWb.Worksheets(1)
    SafeNameSheet outWs, "集約結果"

    outRow = 1
    hCols = 0
    headerWritten = False
    overflow = False
    filesDone = 0: filesFailed = 0: filesEmpty = 0: filesWarn = 0
    failReport = ""

    For Each nm In fileList
        fileName = CStr(nm)
        ' このマクロ入りブック自身は対象にしない（同じフォルダにある場合）
        If StrComp(folderPath & fileName, ThisWorkbook.FullName, vbTextCompare) = 0 Then
            ' skip
        Else
            status = AppendOneFile(folderPath & fileName, fileName, outWs, outRow, hCols, headerWritten)
            Select Case True
                Case status = "OK"
                    filesDone = filesDone + 1
                Case status = "WARN"
                    filesDone = filesDone + 1
                    filesWarn = filesWarn + 1
                Case status = "EMPTY"
                    filesEmpty = filesEmpty + 1
                Case status = "FULL"
                    filesDone = filesDone + 1
                    overflow = True
                Case Else   ' "FAIL:<理由>"
                    filesFailed = filesFailed + 1
                    failReport = failReport & vbCrLf & " - " & fileName & ": " & Mid$(status, 6)
            End Select
            If overflow Then Exit For
        End If
    Next nm

    ' 見出しの列ぶんだけ幅を整える（大量列でのAutoFit遅延を避ける）
    If hCols > 0 Then outWs.Range(outWs.Columns(1), outWs.Columns(hCols + 1)).AutoFit

    Application.ScreenUpdating = oldScreenUpdating
    Application.EnableEvents = oldEvents

    If Not headerWritten Then
        MsgBox "集約できるデータがありませんでした。", vbInformation, "結果"
        Exit Sub
    End If

    Dim msg As String
    msg = "完了しました。" & vbCrLf & _
          "集約: " & filesDone & " ファイル" & vbCrLf & _
          "中身が空で飛ばした: " & filesEmpty & " ファイル" & vbCrLf & _
          "列数がちがう（警告）: " & filesWarn & " ファイル" & vbCrLf & _
          "開けず失敗: " & filesFailed & " ファイル"
    If overflow Then msg = msg & vbCrLf & "※ 行数が上限に達したため、途中で打ち切りました。"
    If Len(failReport) > 0 Then msg = msg & vbCrLf & "失敗したファイル:" & failReport
    msg = msg & vbCrLf & "新しいブックに出力しました（保存してください）。"
    MsgBox msg, vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    Application.EnableEvents = oldEvents
    MsgBox "途中で予期しないエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' フォルダ直下の .xlsx を集めて、名前順に並べた Collection を返す（一時ファイル ~$ は除く）。
Private Function CollectXlsxNames(folderPath As String) As Collection
    Dim arr() As String, n As Long, fileName As String
    Dim i As Long, j As Long, tmp As String
    Dim coll As Collection

    n = 0
    fileName = Dir$(folderPath & "*.xlsx")
    Do While Len(fileName) > 0
        If Left$(fileName, 2) <> "~$" Then
            n = n + 1
            ReDim Preserve arr(1 To n)
            arr(n) = fileName
        End If
        fileName = Dir$
    Loop

    ' 名前順に並べ替え（単純な挿入ソート。ファイル数はふつう多くないので十分）
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
        coll.Add arr(i)
    Next i
    Set CollectXlsxNames = coll
End Function


' 1ファイルを開いて outWs に追記する。状態を文字列で返す:
'   "OK" 正常 / "WARN" 列数がちがうが追記した / "EMPTY" 中身なし /
'   "FULL" 出力行が上限に達した / "FAIL:<理由>" 開けない等の失敗
Private Function AppendOneFile(fullPath As String, fileName As String, _
        outWs As Worksheet, ByRef outRow As Long, ByRef hCols As Long, _
        ByRef headerWritten As Boolean) As String

    Dim srcWb As Workbook, srcWs As Worksheet
    Dim lr As Long, lc As Long, r As Long, c As Long
    Dim wasHeader As Boolean

    On Error GoTo Failed
    Set srcWb = Workbooks.Open(fileName:=fullPath, ReadOnly:=True)
    Set srcWs = srcWb.Worksheets(1)

    lr = LastRow(srcWs)
    lc = LastCol(srcWs)
    If lr = 0 Or lc = 0 Then
        srcWb.Close SaveChanges:=False
        AppendOneFile = "EMPTY"
        Exit Function
    End If

    wasHeader = headerWritten
    If Not headerWritten Then
        ' 最初の中身のあるファイルの見出しを採用（先頭に「元ファイル」列を足す）
        hCols = lc
        outWs.Cells(outRow, 1).Value = "元ファイル"
        For c = 1 To hCols
            outWs.Cells(outRow, c + 1).Value = srcWs.Cells(1, c).Value
        Next c
        outRow = outRow + 1
        headerWritten = True
    End If

    ' データ行（2行目以降）を積み上げる
    For r = 2 To lr
        If outRow >= outWs.Rows.Count Then    ' これ以上書くと行数の上限を超える
            srcWb.Close SaveChanges:=False
            AppendOneFile = "FULL"
            Exit Function
        End If
        outWs.Cells(outRow, 1).Value = fileName
        For c = 1 To hCols
            outWs.Cells(outRow, c + 1).Value = srcWs.Cells(r, c).Value
        Next c
        outRow = outRow + 1
    Next r

    srcWb.Close SaveChanges:=False

    ' 2ファイル目以降で、列数が最初の見出しと違うときは警告として知らせる
    If wasHeader And lc <> hCols Then
        AppendOneFile = "WARN"
    Else
        AppendOneFile = "OK"
    End If
    Exit Function

Failed:
    On Error Resume Next
    If Not srcWb Is Nothing Then srcWb.Close SaveChanges:=False
    On Error GoTo 0
    AppendOneFile = "FAIL:" & Err.Description
End Function


' シート全体の最終行（どの列にデータがあっても拾う）。空なら 0。
Private Function LastRow(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, _
                          SearchOrder:=xlByRows, SearchDirection:=xlPrevious)
    If f Is Nothing Then LastRow = 0 Else LastRow = f.Row
End Function


' シート全体の最終列。空なら 0。
Private Function LastCol(ws As Worksheet) As Long
    Dim f As Range
    Set f = ws.Cells.Find(What:="*", LookIn:=xlFormulas, _
                          SearchOrder:=xlByColumns, SearchDirection:=xlPrevious)
    If f Is Nothing Then LastCol = 0 Else LastCol = f.Column
End Function


' シート名を付ける。既に同名があるなどで付けられないときは日時付きの名前にする。
Private Sub SafeNameSheet(ws As Worksheet, ByVal nm As String)
    On Error Resume Next
    ws.Name = nm
    If ws.Name <> nm Then ws.Name = nm & "_" & Format$(Now, "yyyymmdd_hhnnss")
    On Error GoTo 0
End Sub

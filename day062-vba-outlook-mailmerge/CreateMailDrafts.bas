Attribute VB_Name = "CreateMailDrafts"
Option Explicit

' ============================================================
' 一斉メールの下書きを差し込みで作るマクロ（Day 062 / Outlook VBA）
'
' CSV（宛先リスト）と、{氏名} などの差し込み欄を書いたひな形から、
' 一人ずつの「下書きメール」を作成します。★送信はしません★（下書き保存のみ）。
' 送る前に内容を必ず目視できるので安全です。
'
' CSV の形式（1行目は見出し、UTF-8 でもShift-JISでもなく "ANSI/cp932" 推奨）:
'   メールアドレス,氏名,会社
'   taro@example.com,山田 太郎,ABC商事
'   hanako@example.com,佐藤 花子,DEF工業
'
' ひな形（件名・本文）の中で {見出し名} と書くと、その列の値に差し替わります。
'   例: 件名「{会社} {氏名} 様 ご案内」／本文「{氏名} 様\n\nお世話になっております。…」
'
' 使い方:
'   1) Alt+F11 でVBE → 本ファイルをインポート
'   2) Alt+F8 → CreateMailDrafts を実行
'   3) CSVファイルのパスを入力（または下の Const に直接書いてもよい）
'   4) 下書きフォルダに人数分の下書きができる
' ============================================================

' 件名・本文のひな形（{見出し名} が差し込み欄）。必要に応じて書き換えてください。
Private Const SUBJECT_TEMPLATE As String = "{会社} {氏名} 様｜ご案内"
Private Const BODY_TEMPLATE As String = _
    "{氏名} 様" & vbCrLf & vbCrLf & _
    "いつもお世話になっております。" & vbCrLf & _
    "{会社} の皆さまへご案内をお送りします。" & vbCrLf & vbCrLf & _
    "（ここに本文を書きます）" & vbCrLf & vbCrLf & _
    "よろしくお願いいたします。"

Sub CreateMailDrafts()
    Dim csvPath As String
    Dim fileNum As Integer
    Dim lineText As String
    Dim headers() As String
    Dim values() As String
    Dim isHeader As Boolean
    Dim mailColIndex As Long
    Dim created As Long
    Dim subjectText As String, bodyText As String
    Dim mail As Object
    Dim i As Long

    ' CSV のパスを尋ねる
    csvPath = Trim$(InputBox("宛先CSVのフルパスを入力してください。" & vbCrLf & _
                             "（1行目は見出し。メールアドレスの列が必要です）", "一斉下書き作成"))
    If Len(csvPath) = 0 Then Exit Sub
    If Dir$(csvPath) = "" Then
        MsgBox "ファイルが見つかりません: " & csvPath, vbExclamation
        Exit Sub
    End If

    On Error GoTo CleanFail

    isHeader = True
    mailColIndex = -1
    created = 0
    fileNum = FreeFile
    Open csvPath For Input As #fileNum

    Do Until EOF(fileNum)
        Line Input #fileNum, lineText
        If Len(Trim$(lineText)) = 0 Then GoTo NextLine   ' 空行は飛ばす

        If isHeader Then
            headers = SplitCsvLine(lineText)
            ' メールアドレスの列を探す（見出しに「メール」「mail」を含む列）
            For i = LBound(headers) To UBound(headers)
                If InStr(1, headers(i), "メール", vbTextCompare) > 0 _
                   Or InStr(1, LCase$(headers(i)), "mail") > 0 Then
                    mailColIndex = i
                    Exit For
                End If
            Next i
            If mailColIndex = -1 Then
                Close #fileNum
                MsgBox "見出しに『メールアドレス』の列が見つかりません。", vbExclamation
                Exit Sub
            End If
            isHeader = False
        Else
            values = SplitCsvLine(lineText)
            ' 差し込み（{見出し}→値）して件名・本文を作る
            subjectText = SUBJECT_TEMPLATE
            bodyText = BODY_TEMPLATE
            For i = LBound(headers) To UBound(headers)
                If i <= UBound(values) Then
                    subjectText = Replace(subjectText, "{" & headers(i) & "}", values(i))
                    bodyText = Replace(bodyText, "{" & headers(i) & "}", values(i))
                End If
            Next i

            ' 下書きメールを作る（★送信はしない。Saveで下書き保存）
            If mailColIndex <= UBound(values) Then
                If Len(Trim$(values(mailColIndex))) > 0 Then
                    Set mail = Application.CreateItem(0)   ' 0 = olMailItem
                    mail.To = Trim$(values(mailColIndex))
                    mail.Subject = subjectText
                    mail.Body = bodyText
                    mail.Save                              ' 下書きフォルダに保存
                    created = created + 1
                End If
            End If
        End If
NextLine:
    Loop

    Close #fileNum
    MsgBox "下書きを作成しました（送信はしていません）。" & vbCrLf & _
           "作成数: " & created & " 件", vbInformation, "完了"
    Exit Sub

CleanFail:
    On Error Resume Next
    Close #fileNum
    On Error GoTo 0
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' CSVの1行を、カンマ区切り＋ダブルクォート対応で分解する。
Private Function SplitCsvLine(ByVal lineText As String) As String()
    Dim result() As String
    Dim count As Long
    Dim i As Long
    Dim ch As String
    Dim cur As String
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

    ' 行末までクォートが閉じていなければ、壊れた行として中止する。
    ' （閉じ忘れを見逃すと、以降の列がズレた下書きが作られてしまうため）
    If inQuotes Then
        Err.Raise vbObjectError + 513, "SplitCsvLine", _
                  "CSVの行でダブルクォートが閉じられていません:" & vbCrLf & lineText
    End If

    ReDim Preserve result(0 To count)
    result(count) = cur
    SplitCsvLine = result
End Function

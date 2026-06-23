Attribute VB_Name = "SplitAddress"
Option Explicit

' ============================================================
' 住所分割マクロ（都道府県／市区町村以降）（Day 046）
'
' 選んだ1列の住所を、「都道府県」と「それ以降（市区町村以降）」に分けて、
' すぐ右の2つの列に書き出します。
'   例: A列「東京都新宿区西新宿2-8-1」→ B列「東京都」／C列「新宿区西新宿2-8-1」
'
' しくみ:
'   - 47都道府県の名前リストと「前方一致」で都道府県を判定する
'     （神奈川県・和歌山県・鹿児島県のような4文字の県も、リストなので正しく分かれる）
'   - 都道府県が見つからない住所は、そのまま「市区町村以降」に入れる
'
' 使い方:
'   1) 住所が入った「1列分」を選ぶ（見出しは選択から外すのがおすすめ）
'   2) Alt+F11 でVBE → このファイルをインポート（または標準モジュールに貼り付け）
'   3) Alt+F8 → SplitAddressMain を実行
'
' 注意: 分けるのは「都道府県」までです。市区町村と番地のさらに細かい分割はしません。
'       旧字体・異体字（例「鹿兒島縣」）の住所には対応していません（標準表記が前提）。
' ============================================================

Sub SplitAddressMain()
    Dim ws As Worksheet
    Dim target As Range, cell As Range
    Dim pref As String, rest As String, addr As String
    Dim done As Long, skipped As Long, noPref As Long
    Dim hasExisting As Boolean
    Dim oldScreenUpdating As Boolean
    Dim prefs As Variant

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
        MsgBox "住所が入った1列を選んでから実行してください。", vbExclamation
        Exit Sub
    End If
    Set ws = ActiveSheet

    ' ひと続きの1列だけに限定（右の2列に書くため）
    If Selection.Areas.Count <> 1 Then
        MsgBox "ひと続きの1列を選んでください（バラバラ選択は不可）。", vbExclamation
        Exit Sub
    End If
    If Selection.Columns.Count <> 1 Then
        MsgBox "1列だけを選んでください（右の2列に書き出します）。", vbExclamation
        Exit Sub
    End If
    ' 右に2列ぶんの余白が必要
    If Selection.Column > ws.Columns.Count - 2 Then
        MsgBox "右に2列ぶんの空きが必要です（右端に近い列は選べません）。", vbExclamation
        Exit Sub
    End If

    Set target = Intersect(Selection, ws.UsedRange)
    If target Is Nothing Then
        MsgBox "対象のセルがありません。", vbInformation
        Exit Sub
    End If

    ' 右の2列に既存値があるか確認（元セルが空でない行だけ見る）
    ' 数式や、結果が空に見える数式も「中身あり」として上書き前に確認する
    hasExisting = False
    For Each cell In target.Cells
        If Not IsError(cell.Value) Then
            If Len(CStr(cell.Value)) > 0 Then
                If CellHasContent(cell.Offset(0, 1)) Or CellHasContent(cell.Offset(0, 2)) Then
                    hasExisting = True
                    Exit For
                End If
            End If
        End If
    Next cell
    If hasExisting Then
        If MsgBox("右の2列にすでに値があります。上書きしますか？" & vbCrLf & _
                  "（都道府県＝右隣、市区町村以降＝その右）", _
                  vbYesNo + vbExclamation, "上書きの確認") <> vbYes Then Exit Sub
    End If

    oldScreenUpdating = Application.ScreenUpdating
    Application.ScreenUpdating = False
    On Error GoTo CleanFail

    prefs = PrefectureList()   ' 都道府県リストは一度だけ作る（毎セル作り直さない）
    done = 0: skipped = 0: noPref = 0
    For Each cell In target.Cells
        If IsError(cell.Value) Then
            skipped = skipped + 1
        Else
            ' 全角スペースを半角にしてから前後をトリム（先頭の全角空白で判定が崩れないように）
            addr = Trim$(Replace(CStr(cell.Value), ChrW$(&H3000), " "))
            If Len(addr) = 0 Then
                skipped = skipped + 1
            Else
                SplitOne addr, prefs, pref, rest
                cell.Offset(0, 1).Value = pref
                cell.Offset(0, 2).Value = rest
                If Len(pref) = 0 Then noPref = noPref + 1
                done = done + 1
            End If
        End If
    Next cell

    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "住所を分割しました。" & vbCrLf & _
           "分割した: " & done & " 件 / 空で飛ばした: " & skipped & " 件" & vbCrLf & _
           "都道府県が見つからなかった: " & noPref & " 件（そのまま右の列に入れています）", _
           vbInformation, "結果"
    Exit Sub

CleanFail:
    Application.ScreenUpdating = oldScreenUpdating
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 住所を「都道府県」と「それ以降」に分ける。都道府県が無ければ pref="" / rest=住所全体。
Private Sub SplitOne(ByVal addr As String, ByRef prefs As Variant, ByRef pref As String, ByRef rest As String)
    Dim i As Long
    For i = LBound(prefs) To UBound(prefs)
        If Left$(addr, Len(prefs(i))) = prefs(i) Then
            pref = prefs(i)
            rest = Mid$(addr, Len(prefs(i)) + 1)
            Exit Sub
        End If
    Next i
    pref = ""
    rest = addr
End Sub


' 47都道府県の名前（前方一致の判定に使う）
Private Function PrefectureList() As Variant
    PrefectureList = Array( _
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", _
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", _
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県", _
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県", _
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県", _
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県", _
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県")
End Function


' そのセルに何か入っているか（数式、または表示値が空でない値）。
Private Function CellHasContent(c As Range) As Boolean
    If c.HasFormula Then
        CellHasContent = True
    ElseIf IsError(c.Value) Then
        CellHasContent = True            ' エラー値も「中身あり」とみなす
    Else
        CellHasContent = (Len(CStr(c.Value2)) > 0)
    End If
End Function

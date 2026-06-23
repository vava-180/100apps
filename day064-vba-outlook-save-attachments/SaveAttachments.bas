Attribute VB_Name = "SaveAttachments"
Option Explicit

' ============================================================
' 添付ファイル一括保存マクロ（Day 064 / Outlook VBA）
'
' 選択しているメール（複数選択OK）の添付ファイルを、指定フォルダへ
' まとめて保存します。同名ファイルがぶつからないよう、必要なら
' ファイル名の後ろに連番を付けます。
'
' 仕様:
'   ・対象は「いま選択しているメール」（一覧で複数選んでから実行）
'   ・保存先フォルダはコードの SAVE_FOLDER で指定（無ければ自動作成）
'   ・画像署名などの小さな埋め込み添付も拾うため、サイズの下限で除外可
'   ・メール本体は変更しない（添付を保存するだけ）
'
' 使い方:
'   1) 下の SAVE_FOLDER を保存したいフォルダに書き換える
'   2) Alt+F11 でVBE → 本ファイルをインポート
'   3) Outlook の一覧で、保存したいメールを選ぶ（Ctrlで複数選択可）
'   4) Alt+F8 → SaveAttachments を実行
' ============================================================

' 保存先フォルダ（自分の環境に合わせて書き換えてください）
Private Const SAVE_FOLDER As String = "C:\Temp\Attachments"

' これより小さい添付は無視する（バイト）。署名画像などの誤保存を防ぐ。0なら全部保存。
Private Const MIN_SIZE As Long = 8000

Sub SaveAttachments()
    Dim sel As Object              ' Selection
    Dim mail As Object
    Dim att As Object
    Dim i As Long, j As Long
    Dim saved As Long
    Dim savePath As String

    On Error GoTo CleanFail

    ' 選択中のメールを取得
    If Application.ActiveExplorer Is Nothing Then
        MsgBox "メールの一覧画面で実行してください。", vbExclamation
        Exit Sub
    End If
    Set sel = Application.ActiveExplorer.Selection
    If sel Is Nothing Or sel.Count = 0 Then
        MsgBox "保存したいメールを選んでから実行してください。", vbExclamation
        Exit Sub
    End If

    ' 保存先フォルダを用意（無ければ作る）
    EnsureFolder SAVE_FOLDER

    saved = 0
    For i = 1 To sel.Count
        Set mail = sel.Item(i)
        ' 添付を持つアイテムだけ処理
        If HasAttachments(mail) Then
            For j = 1 To mail.Attachments.Count
                Set att = mail.Attachments.Item(j)
                ' 小さすぎる添付（署名画像など）は除外
                If MIN_SIZE = 0 Or att.Size >= MIN_SIZE Then
                    savePath = UniquePath(SAVE_FOLDER, att.FileName)
                    att.SaveAsFile savePath
                    saved = saved + 1
                End If
            Next j
        End If
    Next i

    MsgBox saved & " 個の添付ファイルを保存しました。" & vbCrLf & SAVE_FOLDER, _
           vbInformation, "完了"
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' そのアイテムが添付を持っているか（添付プロパティが無い種類でも落ちないように）。
Private Function HasAttachments(ByVal item As Object) As Boolean
    On Error Resume Next
    HasAttachments = (item.Attachments.Count > 0)
    On Error GoTo 0
End Function


' フォルダが無ければ作る（途中の階層もまとめて作成）。
Private Sub EnsureFolder(ByVal folderPath As String)
    Dim fso As Object
    Dim parent As String
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(folderPath) Then Exit Sub
    parent = fso.GetParentFolderName(folderPath)
    If Len(parent) > 0 Then EnsureFolder parent   ' 親フォルダから順に作る
    If Not fso.FolderExists(folderPath) Then fso.CreateFolder folderPath
End Sub


' 同名ファイルがあれば「名前(2).拡張子」のように連番を付けて、ぶつからないパスを返す。
Private Function UniquePath(ByVal folderPath As String, ByVal fileName As String) As String
    Dim fso As Object
    Dim baseName As String, ext As String
    Dim candidate As String
    Dim n As Long

    Set fso = CreateObject("Scripting.FileSystemObject")
    candidate = fso.BuildPath(folderPath, fileName)
    If Not fso.FileExists(candidate) Then
        UniquePath = candidate
        Exit Function
    End If

    baseName = fso.GetBaseName(fileName)
    ext = fso.GetExtensionName(fileName)
    n = 2
    Do
        If Len(ext) > 0 Then
            candidate = fso.BuildPath(folderPath, baseName & "(" & n & ")." & ext)
        Else
            candidate = fso.BuildPath(folderPath, baseName & "(" & n & ")")
        End If
        n = n + 1
    Loop While fso.FileExists(candidate)

    UniquePath = candidate
End Function

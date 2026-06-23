Attribute VB_Name = "TemplateMail"
Option Explicit

' ============================================================
' 定型メールのテンプレ送信補助マクロ（Day 065 / Outlook VBA）
'
' よく使う定型文（お礼／日程調整／資料送付 など）から1つ選ぶと、
' 件名・本文を入れた新規メールを「表示」します。★自動送信はしません★。
' 内容を確認・微修正してから、自分で送信ボタンを押せるので安全です。
'
' 仕組み:
'   ・テンプレは下の GetTemplate 内にまとめてある（自由に増やせる）
'   ・{宛名} は実行時に入力した名前へ差し替わる
'   ・mail.Display で画面に表示（送信は手動）。署名も自動で付く設定なら反映される
'
' 使い方:
'   1) Alt+F11 でVBE → 本ファイルをインポート
'   2) Alt+F8 → TemplateMail を実行
'   3) テンプレ番号と宛名を入力 → 下書きが画面に開く
' ============================================================

Sub TemplateMail()
    Dim choice As String
    Dim toName As String
    Dim subjectText As String, bodyText As String
    Dim mail As Object

    ' テンプレを選んでもらう
    choice = Trim$(InputBox( _
        "使うテンプレートの番号を選んでください。" & vbCrLf & _
        "  1 = お礼メール" & vbCrLf & _
        "  2 = 日程調整のお願い" & vbCrLf & _
        "  3 = 資料送付のご案内", "定型メール作成", "1"))
    If Len(choice) = 0 Then Exit Sub

    ' 宛名（{宛名} に差し込む）
    toName = Trim$(InputBox("宛名を入力してください（例: 山田）。" & vbCrLf & _
                            "空欄なら『ご担当者』にします。", "宛名の入力"))
    If Len(toName) = 0 Then toName = "ご担当者"

    ' 選んだテンプレの件名・本文を取得
    If Not GetTemplate(choice, subjectText, bodyText) Then
        MsgBox "1?3 の番号を入力してください。", vbExclamation
        Exit Sub
    End If

    ' {宛名} を差し替え
    subjectText = Replace(subjectText, "{宛名}", toName)
    bodyText = Replace(bodyText, "{宛名}", toName)

    On Error GoTo CleanFail
    ' 新規メールを作って表示（送信はしない）
    Set mail = Application.CreateItem(0)   ' 0 = olMailItem
    mail.Subject = subjectText
    mail.Body = bodyText
    mail.Display                           ' 画面に表示（自分で送信ボタンを押す）
    Exit Sub

CleanFail:
    MsgBox "途中でエラーが発生しました。" & vbCrLf & Err.Description, vbCritical, "エラー"
End Sub


' 番号に対応するテンプレの件名・本文を返す。見つかれば True。
' テンプレを増やしたいときは、ここに Case を追加してください。
Private Function GetTemplate(ByVal choice As String, _
                             ByRef subjectText As String, _
                             ByRef bodyText As String) As Boolean
    Select Case choice
        Case "1"   ' お礼
            subjectText = "お礼｜先日はありがとうございました"
            bodyText = "{宛名} 様" & vbCrLf & vbCrLf & _
                       "いつもお世話になっております。" & vbCrLf & _
                       "先日はお時間をいただき、誠にありがとうございました。" & vbCrLf & vbCrLf & _
                       "（ここに一言）" & vbCrLf & vbCrLf & _
                       "引き続きよろしくお願いいたします。"
            GetTemplate = True

        Case "2"   ' 日程調整
            subjectText = "日程調整のお願い"
            bodyText = "{宛名} 様" & vbCrLf & vbCrLf & _
                       "お世話になっております。" & vbCrLf & _
                       "下記日程でご都合のよい時間帯を教えていただけますでしょうか。" & vbCrLf & vbCrLf & _
                       "・候補1：" & vbCrLf & _
                       "・候補2：" & vbCrLf & _
                       "・候補3：" & vbCrLf & vbCrLf & _
                       "お手数をおかけしますが、よろしくお願いいたします。"
            GetTemplate = True

        Case "3"   ' 資料送付
            subjectText = "資料送付のご案内"
            bodyText = "{宛名} 様" & vbCrLf & vbCrLf & _
                       "お世話になっております。" & vbCrLf & _
                       "ご依頼いただいた資料を添付にてお送りいたします。" & vbCrLf & vbCrLf & _
                       "ご確認のうえ、ご不明点がございましたらお知らせください。" & vbCrLf & vbCrLf & _
                       "よろしくお願いいたします。"
            GetTemplate = True

        Case Else
            GetTemplate = False
    End Select
End Function

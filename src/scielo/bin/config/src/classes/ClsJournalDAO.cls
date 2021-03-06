VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ClsJournalDAO"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Private isis As ClIsisdll
Const changelinetextbox = vbCrLf

Function getJournalStandardList() As MyCollection
    Dim journals As New MyCollection
    Dim journal As ClsJournal
    Dim pissn As String
    Dim eissn As String
    
    Dim i As Long
    
    For i = 1 To isis.MfnQuantity
        Set journal = New ClsJournal
        
        journal.is_published = isis.FieldContentOccGet(i, 50, 1)
        
        journal.ISSN = isis.FieldContentOccGet(i, 400, 1)
        journal.shorttitle = isis.FieldContentOccGet(i, 150, 1)
        journal.JournalStandard = isis.FieldContentOccGet(i, 117, 1)
        journal.MedlineTitle = isis.FieldContentOccGet(i, 421, 1)
        journal.pmid = isis.FieldContentOccGet(i, 420, 1)
        
        
        Call serial_issn_get(i, pissn, eissn)
        journal.print_issn = pissn
        journal.online_issn = eissn
        
        journal.publisherName = isis.UsePft(i, "(v480+|, |)")
        journal.SUBJECT = isis.UsePft(i, "(v441+|/|)")
        journal.fulltitle = isis.FieldContentOccGet(i, 100, 1)
        journal.acron = isis.FieldContentOccGet(i, 68, 1)
        
        
        Call journals.add(journal, journal.ISSN + journal.shorttitle)
    Next
    Set getJournalStandardList = journals
End Function

Function getHistory(mfn As Long) As ClsHistory
    Dim q As Long
    Dim occs() As String
    Dim i As Long
    Dim journalStatus As ClsJournalStatus
    Dim history As New ClsHistory
    
    
    
    q = isis.FieldContentGetAll(mfn, 51, occs)
    For i = q To 1 Step -1
        Set journalStatus = New ClsJournalStatus
        
        journalStatus.statusDate = isis.getSubfieldContent("a", occs(i))
        journalStatus.status = isis.getSubfieldContent("b", occs(i))
        
        Call history.add(journalStatus, journalStatus.statusDate)
        
        If InStr(occs(i), "^c") > 0 Then
            Set journalStatus = New ClsJournalStatus
            journalStatus.statusDate = isis.getSubfieldContent("c", occs(i))
            journalStatus.status = isis.getSubfieldContent("d", occs(i))
            
            Call history.add(journalStatus, journalStatus.statusDate)
        End If
        
    Next
    Set getHistory = history
End Function
Function tagHistory(history As ClsHistory) As String
    Dim i As Long
    
    Dim journalStatus As ClsJournalStatus
    
    Const tag = "51"
    Dim tagged As String
    Dim Occ As String
    
    
    For i = 1 To history.count
        Set journalStatus = history.item(i)
        If Len(Occ) = 0 Then
            Occ = "<" + tag + ">^a" + journalStatus.statusDate + "^b" + journalStatus.status
        Else
            Occ = Occ + "^c" + journalStatus.statusDate + "^d" + journalStatus.status + "</" + tag + ">"
            tagged = Occ + tagged
            Occ = ""
        End If
    Next
    If Len(Occ) > 0 Then
        Occ = Occ + "</" + tag + ">"
        tagged = Occ + tagged
    End If
    
    tagHistory = tagged
End Function

Function getJournalCreativeCommons(mfn As Long) As clsCreativeCommons
    Dim languages() As String
    Dim texts() As String
    Dim creativeCommons As New clsCreativeCommons
    
    
    creativeCommons.Code = Serial_TxtContent(mfn, 541)
    
    q = isis.SubfieldContentGet(mfn, 540, "l", languages)
    q = isis.SubfieldContentGet(mfn, 540, "t", texts)
    
    For i = 1 To q
        Call creativeCommons.add(texts(i), languages(i))
    Next
    If q = 0 Then
        For i = 1 To idiomsinfo.count
            Call creativeCommons.add("", idiomsinfo(i).Code)
        Next
    End If
    Set getJournalCreativeCommons = creativeCommons
End Function
Function tagCreativeCommons(cc As clsCreativeCommons) As String
    Dim i As Long
    Const tag = "540"
    Dim tagged As String
    
    For i = 1 To cc.count
        If Len(cc.getLicenseByIndex(i).text) > 0 Then
            tagged = tagged + "<" + tag + ">^t" + cc.getLicenseByIndex(i).text + "^l" + cc.getLicenseByIndex(i).lang + "</" + tag + ">"
        End If
    Next
    
    tagCreativeCommons = tagged
End Function

Private Sub Class_Initialize()
    Set isis = New ClIsisdll
    
    With Paths("Title Database")
    If isis.Inicia(.Path, .FileName, .key) Then
        If isis.IfCreate(Paths("Title X ISSN Database").FileName) Then
            
        End If
    End If
    End With
End Sub

Function save(ByRef MfnTitle As Long, Data As String) As Boolean
    Dim OK As Boolean
    If MfnTitle = 0 Then
         MfnTitle = isis.RecordSave(Data)
         OK = (MfnTitle > 0)
    Else
        OK = isis.RecordUpdate(MfnTitle, Data)
    End If

    If OK Then
        Call isis.IfUpdate(MfnTitle, MfnTitle)
    End If
    save = OK
End Function

Function getJournalList() As ClsJournalList
    Dim i As Long
    Dim tmp As String
    Dim j As ClsJournal
    Dim jlist As New ClsJournalList
    
    For i = 1 To isis.MfnQuantity
        tmp = isis.UsePft(i, "v400,' ',v100")
        If Len(tmp) > 0 Then
            Set j = New ClsJournal
            j.key = tmp
            j.Title = Mid(tmp, 11)
            j.ISSN = Mid(tmp, 1, 9)
            j.pubid = isis.UsePft(i, "v68")
            j.CollectionURL = isis.UsePft(i, "v690")
            j.JournalStandard = isis.UsePft(i, "v117")
            j.shorttitle = isis.UsePft(i, "v150")
            Call jlist.add(j)
        End If
    Next
    Set getJournalList = jlist
End Function


Function existJournal(journalKey As String, journalTitle As String) As Long
    Dim i As Long
    Dim j As Long
    
    i = existJournalTitle(journalTitle)
    j = existISSN(journalKey)
    If i = j Then
    
    Else
        
    End If
End Function

Function existRecord(key As String, format As String, Optional Prefix As String) As Long
    Dim MfnCounter As Long
    Dim mfns() As Long
    Dim i As Long
    Dim found As Boolean
    Dim value As String
    Dim ID As String
    Dim mfn As Long
    
    ID = key
    If Len(key) > 30 Then key = Mid(Prefix + key, 1, 30)
    MfnCounter = isis.MfnFind(key, mfns)
    
    i = 0
    While (i < MfnCounter) And (Not found)
        i = i + 1
        value = isis.UsePft(mfns(i), format)
        If StrComp(value, ID) = 0 Then
            mfn = mfns(i)
            found = True
        End If
    Wend
    
    If Not found Then
        i = 0
        While (i < isis.MfnQuantity) And (Not found)
            i = i + 1
            value = isis.UsePft(mfn, format)
            If StrComp(Trim(value), Trim(ID)) = 0 Then
                found = True
                mfn = i
            End If
        Wend
    End If
    existRecord = mfn
End Function

Function existJournalTitle(journalTitle As String) As Long
    existJournalTitle = existRecord(journalTitle, "v100")
End Function
Function existISSN(journal_ISSN As String) As Long
    existISSN = existRecord(journal_ISSN, "v400", "pbn=")
End Function

Function getFieldContentByLanguage(mfn As Long, tag As Long, Optional language As String) As String
'xxx
    Dim subf As String
    If language <> "" Then subf = "*"
    
    getFieldContentByLanguage = isis.getFieldContentByLanguage(mfn, tag, language, subf)
End Function

Function getDecodedValue(Code As ColCode, mfn As Long, tag As Long, Optional DefaultOption As String) As String
    Dim content As String
    Dim exist As Boolean
    Dim itemCode As ClCode
    
        content = isis.UsePft(mfn, "v" + CStr(tag))
        If (Len(content) = 0) And (Len(DefaultOption) > 0) Then content = DefaultOption
        
        If Len(content) > 0 Then
            Set itemCode = New ClCode
            Set itemCode = Code(content, exist)
            If exist Then
                content = itemCode.value
            Else
                Debug.Print
            End If
        End If
    getDecodedValue = content
End Function


Function getRepetitiveFieldValue(mfn As Long, tag As Long, sep As String) As String
     getRepetitiveFieldValue = isis.UsePft(mfn, "(v" + CStr(tag) + "|" + sep + "|)")
End Function

Function delete(journal_ISSN As String) As Boolean
    Dim mfn As Long
    Dim issueDAO As New ClsIssueDAO
    Dim issueMFNs() As Long
    Dim i As Long
    Dim r As Boolean
    
    With Paths("Issue Database")
    Set issueDAO = New ClsIssueDAO
    Call issueDAO.create(.Path, .FileName, .key)
    End With
    
    mfn = existRecord(journal_ISSN, "v400", "pbn=")
    If mfn > 0 Then
        issueMFNs = issueDAO.getIssuesMfnByJournalID(journal_ISSN)
        For i = 1 To UBound(issueMFNs)
            r = issueDAO.deleteRecord(issueMFNs(i))
        Next
        r = isis.RecordDel(mfn)
        'r = save(mfn, "d*")
    End If
    delete = r
End Function

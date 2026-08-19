' TScreen_MyContract.ButtonRequestLoan
' VA 0x00555ADE   582 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x50
' ASSUMPTIONS
'   0x00C6F028 g_contractoffer_tprofile:TProfile -- settles the assemble.py conflict
'     (TPlayer vs TProfile) in favour of TProfile: +0x134 transferlisted, +0x104
'     relationboss, +0x74 contractexpires, +0x148 onloanfrom, +0x10 date:TMyDate, and
'     slots 0x88 GetStat / 0x98 GetAverageForm / 0x144 CancelLoan are all TProfile's.
'   0x00C67D94 g_Object568:TButton (TGadget.alph at +0x44),
'   0x00C67B34 g_Object542:TProgressBar (slot 0x8c SetPercent(f,i), 0x6c SetColour($,$)).
'   Float constants: 0x00C8AACC = 5.0, 0x00C8AAD0 = 7.0 (read from .data).
'   Literals CMESSAGE_LOANREQUESTREJECTED / ...DATE / CMESSAGE_CANCELLOANEARLY and
'     "$clubname" read with harness.read_string.  TClub.labelname is +0x1c (TBase_Team).
'   ColourGreen is the recovered module Function; its declared arity had to be corrected
'     from ()$ to (i)$ for this call site to compile -- see src/recovered_module/ColourGreen.bmx.
'   The leading guard is a real early return with the SOURCE comparison `< 1.0`: bcc
'     materialises the NEGATED predicate for a float If (setae) and branches with jne.
'   The transferlisted dispatch is a Select with empty Case 1 / Case 2 and no Default.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_Object568:TButton
'!Global g_Object542:TProgressBar
'!Global g_profile:TProfile
If g_Object568.alph < 1.0 Then Return 0
Select g_profile.transferlisted
	Case 0
		Local yr:Int = g_profile.date.GetYear()
		If g_profile.relationboss > 60 And g_profile.GetStat(12, 3, g_profile.clubid, yr) > 5.0 And g_profile.GetAverageForm(3, g_profile.clubid, yr) > 7.0 Then
			TScreen.DoMessage(GetText("CMESSAGE_LOANREQUESTREJECTED"), 0, 0)
		ElseIf g_profile.contractexpires - g_profile.date.sdate < 84 Then
			TScreen.DoMessage(GetText("CMESSAGE_LOANREQUESTREJECTEDDATE"), 0, 0)
		Else
			g_profile.transferlisted = 3
		End If
	Case 1
	Case 2
	Case 3
		g_profile.transferlisted = 0
	Case 4
		If TScreen.DoMessage(GetText("CMESSAGE_CANCELLOANEARLY").Replace("$clubname", TClub.SelectById(g_profile.onloanfrom).labelname), 1, 0) Then
			g_profile.CancelLoan()
			TScreen_MyContract.SetUpScreen()
			Return 0
		End If
End Select
TScreen_MyContract.UpdateTransferStatus()
TScreen_MyContract.UpdateOfferButtons()
g_Object542.SetPercent(g_profile.relationboss, 0)
g_Object542.SetColour("", ColourGreen(g_profile.relationboss))
Return 0

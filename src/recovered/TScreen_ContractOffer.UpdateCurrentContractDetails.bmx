' TScreen_ContractOffer.UpdateCurrentContractDetails
' VA 0x0055395E   692 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (692/692, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only.
' The opening guard is the 21-byte "If Not x" shape plus an early return, NOT
' "If x <> Null Then ... EndIf" -- the block form is 16 bytes shorter (676).
' Slot lookups: TBase_Team+0x3c = GetPrimaryColour, TGadget+0x64 = SetText($,$,i,i),
' TGadget+0x6c = SetColour($,$), TProgressBar+0x8c = SetPercent(f,i),
' TCompetition+0x9c = GetStringTeamPosition(i)$, TProfile+0x84 = GetStringContractExpires.
' 0x00C67B34 is the TProgressBar; the other nine 0x00C67Bxx globals are TLabels.
'!Global g_profile:TProfile
'!Global g_Object539:TLabel
'!Global g_Object540:TLabel
'!Global g_Object541:TLabel
'!Global g_Object542:TProgressBar
'!Global g_Object543:TLabel
'!Global g_Object544:TLabel
'!Global g_Object545:TLabel
'!Global g_Object546:TLabel
'!Global g_Object547:TLabel
If Not g_profile.myclub Then Return 0
Local c:TClub = g_profile.myclub
If g_profile.onloanfrom <> 0 Then c = TClub.SelectById(g_profile.onloanfrom)
Local n:TNation = TNation.SelectById(c.nationid)
Local cp:TCompetition = TCompetition.SelectById(c.leagueid)
g_Object539.SetColour(c.GetPrimaryColour(), "FFFFFF")
g_Object539.SetText(c.labelname, "", -1, -1)
g_Object540.SetText(n.labelname, "", -1, -1)
g_Object541.SetText(cp.GetStringTeamPosition(c.id) + " " + cp.name, "", -1, -1)
g_Object542.SetPercent(Float(g_profile.relationboss), 1)
g_Object542.SetColour("", ColourGreen(g_profile.relationboss))
If g_profile.onloanfrom <> 0 Then
	g_Object542.SetPercent(Float(g_profile.oldbossrel), 1)
	g_Object542.SetColour("", ColourGreen(g_profile.oldbossrel))
EndIf
g_Object543.SetText(FormatMoney(g_profile.contractwage, 0), "", -1, -1)
g_Object545.SetText(FormatMoney(g_profile.contractgoalbonus, 0), "", -1, -1)
g_Object546.SetText(FormatMoney(g_profile.contractassistbonus, 0), "", -1, -1)
g_Object547.SetText(FormatMoney(g_profile.contractcleanbonus, 0), "", -1, -1)
g_Object544.SetText(g_profile.GetStringContractExpires(), "", -1, -1)

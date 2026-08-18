' TScreen_EditCompetition.UpdateComp
' VA 0x0053250C   1296 bytes   mode=reloc   byte-identical vs NSS5.exe (1296/1296, reloc_masked=110)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x4c
'
' Reads back every edit widget on the Edit Competition screen into g_curcomp, the
' TCompetition currently being edited. Sibling of already-verified CreateScreen.bmx /
' SetUpScreen.bmx / ButtonNextComp.bmx, which supply every Global name and construction
' site used here.
'
' ASSUMPTIONS -- module Globals (NAMES ARE OURS; declared TYPE is load-bearing, it
' selects the vtable slot for every call made through it):
'   0x00C6572C g_editcomp_inpid:TInputBox        0x00C65720 g_curcomp:TCompetition
'   0x00C6EF50 g_engine_int161:Int (= g_debug, ReadSettingFloat(SET,"debug",...))
'   0x00C65734 g_editcomp_inpname:TInputBox      0x00C65738 g_editcomp_inptla:TInputBox
'   0x00C6573C g_editcomp_cmblevel:TCombo        0x00C65740 g_editcomp_cmblocale:TCombo
'   0x00C65744 g_editcomp_cmbbased:TCombo        0x00C65748 g_editcomp_cmbcomptype:TCombo
'   0x00C6574C g_editcomp_cmbstartyear:TCombo    0x00C65750 g_editcomp_cmbrecurring:TCombo
'   0x00C65754 g_editcomp_inpstartweek:TInputBox 0x00C65758 g_editcomp_inpduration:TInputBox
'   0x00C6575C g_editcomp_cmbmatchday1:TCombo    0x00C65760 g_editcomp_cmbmatchday2:TCombo
'   0x00C65764 g_editcomp_inpgroups:TInputBox    0x00C65768 g_editcomp_inprounds:TInputBox
'   0x00C6576C g_editcomp_cmblegs:TCombo         0x00C65770 g_editcomp_cmbregion:TCombo
'   0x00C65774 g_editcomp_cmbstatus:TCombo
'
' Class-table slots resolved via vtable_map.tsv:
'   TInputBox+0x94 GetText()$ (inherited TGadget)   TGadget+0x64 SetText($,$,i,i)i
'   TCombo+0xbc GetSelectedItem()i   TCombo+0xc0 GetSelectedItemId()i
'   TCompetition+0xb4 ChangeId(i)i   TNation+0x58(classtable) SelectById(i):TNation
'   TContinent+0x40(classtable) SelectById(i):TContinent
'   0x00C61CC0 = TScreen classtable+0x94 DoMessage($,i,i)i
'   0x00C616DC = TCompetition classtable+0x11c SortListBy(i,i)i
'   0x00C658D8 = this Type's own classtable+0x34 -> SetUpScreen(i,$), unqualified.
' Runtime helpers: 0x004A7130 _bbStringToInt (Int(...)); 0x004A7AC0 String(Int); 0x004A75B0
'   _bbStringReplace (String.Replace); 0x00505F6D ClampInt (src/recovered_module).
' Literals (harness.read_string): 0xC84574 "CMESSAGE_NEWCOMPIDSET", 0xC7D2BC "$id",
'   0xC845AC "Competition ", 0xC845D0 "COMP", 0xC5D284 "" (empty string).
'
' SHAPE NOTES (both settled by the byte oracle):
'  * The id-conflict guard is `If g_debug <> 0 Then <revert display> Else <ChangeId+msg>`,
'    not the reverse -- the original's `je` jumps FORWARD past the revert block to the
'    ChangeId block when g_debug = 0, so ChangeId is the Else, revert is the Then.
'  * The based-nation/continent lookup is a `Select g_curcomp.locale : Case 0 <TNation> :
'    Default <TContinent> : End Select`, NOT an If/Else -- Select loads locale into a
'    register once (`mov eax,[..+0x18]` then `cmp eax,0`); an If/Else re-tests the field
'    as a direct memory operand (2 bytes shorter) and does not match. Same idiom already
'    documented in SetUpScreen.bmx for the mirror-image write.
'  * The two matchday-sentinel clamps (`If primarymatchday < 1 Then =99`, same for
'    secondary) are BOTH read from their combos FIRST, then BOTH clamped -- not
'    read-then-clamp-then-read-then-clamp. Interleaving them costs a 23-byte gap pair.
'!Global g_editcomp_inpid:TInputBox
'!Global g_curcomp:TCompetition
'!Global g_engine_int161:Int
'!Global g_editcomp_inpname:TInputBox
'!Global g_editcomp_inptla:TInputBox
'!Global g_editcomp_cmblevel:TCombo
'!Global g_editcomp_cmblocale:TCombo
'!Global g_editcomp_cmbbased:TCombo
'!Global g_editcomp_cmbcomptype:TCombo
'!Global g_editcomp_cmbstartyear:TCombo
'!Global g_editcomp_cmbrecurring:TCombo
'!Global g_editcomp_inpstartweek:TInputBox
'!Global g_editcomp_inpduration:TInputBox
'!Global g_editcomp_cmbmatchday1:TCombo
'!Global g_editcomp_cmbmatchday2:TCombo
'!Global g_editcomp_inpgroups:TInputBox
'!Global g_editcomp_inprounds:TInputBox
'!Global g_editcomp_cmblegs:TCombo
'!Global g_editcomp_cmbregion:TCombo
'!Global g_editcomp_cmbstatus:TCombo
	Function UpdateComp:Int()
		Local newid:Int = Int(g_editcomp_inpid.GetText())
		If newid < 1 Then newid = 1
		If newid <> g_curcomp.id
			If g_engine_int161 <> 0
				g_editcomp_inpid.SetText(String(g_curcomp.id), "", -1, -1)
			Else
				If g_curcomp.ChangeId(newid) <> 0
					TScreen.DoMessage(GetText("CMESSAGE_NEWCOMPIDSET").Replace("$id", String(newid)), 0, 0)
					TCompetition.SortListBy(1, 1)
				EndIf
			EndIf
		EndIf
		g_curcomp.name = g_editcomp_inpname.GetText()
		g_curcomp.tla = g_editcomp_inptla.GetText()
		g_curcomp.level = g_editcomp_cmblevel.GetSelectedItem() - 1
		g_curcomp.locale = g_editcomp_cmblocale.GetSelectedItem() - 1
		Select g_curcomp.locale
			Case 0
				Local n:TNation = TNation.SelectById(g_editcomp_cmbbased.GetSelectedItemId())
				If n <> Null Then g_curcomp.based = n.id
			Default
				Local c:TContinent = TContinent.SelectById(g_editcomp_cmbbased.GetSelectedItemId())
				If c <> Null Then g_curcomp.based = c.id
		End Select
		g_curcomp.comptype = g_editcomp_cmbcomptype.GetSelectedItem() - 1
		g_curcomp.startyear = g_editcomp_cmbstartyear.GetSelectedItem() - 1
		If g_curcomp.startyear < 0 Then g_curcomp.startyear = 0
		g_curcomp.recurring = g_editcomp_cmbrecurring.GetSelectedItem()
		If g_curcomp.recurring < 1 Then g_curcomp.recurring = 1
		g_curcomp.startweek = Int(g_editcomp_inpstartweek.GetText())
		ClampInt(Varptr g_curcomp.startweek, 0, 52)
		g_curcomp.duration = Int(g_editcomp_inpduration.GetText())
		ClampInt(Varptr g_curcomp.duration, 0, 104)
		g_curcomp.primarymatchday = g_editcomp_cmbmatchday1.GetSelectedItem() - 1
		g_curcomp.secondarymatchday = g_editcomp_cmbmatchday2.GetSelectedItem() - 1
		If g_curcomp.primarymatchday < 1 Then g_curcomp.primarymatchday = 99
		If g_curcomp.secondarymatchday < 1 Then g_curcomp.secondarymatchday = 99
		g_curcomp.groups = Int(g_editcomp_inpgroups.GetText())
		g_curcomp.rounds = Int(g_editcomp_inprounds.GetText())
		g_curcomp.legs = g_editcomp_cmblegs.GetSelectedItem() - 1
		If g_curcomp.legs < 0 Then g_curcomp.legs = 0
		g_curcomp.townregion = g_editcomp_cmbregion.GetSelectedItem() - 1
		If g_curcomp.townregion < 0 Then g_curcomp.townregion = 0
		g_curcomp.compstatus = g_editcomp_cmbstatus.GetSelectedItem() - 1
		If g_curcomp.compstatus < 0 Then g_curcomp.compstatus = 0
		If g_curcomp.name = ""
			g_curcomp.name = "Competition " + String(g_curcomp.id)
		EndIf
		If g_curcomp.tla = ""
			g_curcomp.tla = "COMP" + String(g_curcomp.id)
		EndIf
		ClampInt(Varptr g_curcomp.groups, 0, 20)
		ClampInt(Varptr g_curcomp.rounds, 0, 20)
		SetUpScreen(g_curcomp.id, "")
		Return 0
	End Function

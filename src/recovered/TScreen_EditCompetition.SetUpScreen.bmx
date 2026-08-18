' TScreen_EditCompetition.SetUpScreen
' VA 0x00531944   1909 bytes   mode=reloc   byte-identical vs NSS5.exe (1909/1909, reloc_masked=140)
' KIND=Function (static, no implicit Self), SIG (i,$)i, class-table slot 0x34
' Params: a0:Int = competition id, a1:String = the screen SetUpScreen was entered from.
'
' ASSUMPTIONS -- module Globals (NAMES ARE OURS; the declared TYPE is load-bearing because
' it selects the vtable slot for every call made through it):
'   0x00C6571C g_editcomp_from:String      "the screen the editor was entered from" -- name
'                confirmed by TScreen_EditCompetition.ButtonQuit.bmx, which Selects on it.
'   0x00C65720 g_curcomp:TCompetition      construction site = TCompetition.SelectById(a0).
'                Name matches TScreen_EditCompetition.ButtonNextComp.bmx (same address);
'                ButtonAddPlace.bmx calls the same Global g_ec_comp -- the corpus already
'                carries two names for this address, neither more authoritative than mine.
'   0x00C596F0 g_nations:TList (of TNation)      0x00C6080C g_continents:TList (of TContinent)
'   0x00C65728..0x00C65790 -- the same construction sites CreateScreen.bmx already declared
'                for g_editcomp_inpid / inpname / inptla / cmblevel / cmblocale / cmbbased /
'                cmbcomptype / cmbstartyear / cmbrecurring / inpstartweek / inpduration /
'                cmbmatchday1 / cmbmatchday2 / inpgroups / inprounds / cmblegs / cmbregion /
'                cmbstatus / btnnoofteams / tblpromplaces / tblpromfromcomps / inpnewpromplace.
'
' Class-table slots resolved via vtable_map.tsv / direct PE read of the data pointer:
'   0x00C61C88 = TScreen+0x5C SetActive($,$):TScreen        0x00C6160C = TCompetition+0x4C SelectById
'   0x00C59A40 = TNation+0x78 SortListBy(i,i)i               0x00C59E18 = TClub+0x6C SelectListByLeagueId
'   0x00C59A30 = TNation+0x68 SelectListByContinent           0x00C60958 = TContinent classtable (downcast)
'   0x00C599C8 = TNation classtable (downcast)                 0x00C64754 = TPromotionPlace classtable
'   TGadget+0x64 SetText($,$,i,i)i    TCombo+0xAC SelectItem(i)i    TCombo+0x90 AddItem($,$,$,i)i
'   TTable+0x9C ClearItems()i    TTable+0x94 AddItem([]$,$,$)i     TList+0x38 IsEmpty()  TList+0x70 Count()
'   TCompetition+0xA4 GetNoofTeamsInRound()i    TPromotionPlace+0x48 GetStringPlace()$
' Fields: TCompetition id/name/tla/locale/level/based/comptype/startyear/startweek/duration/
'   recurring/primarymatchday/secondarymatchday/groups/rounds/legs/townregion/compstatus/
'   lpromotionplaces/lplacesthatpromotetome at their object_model.json offsets. TPromotionPlace
'   parentid=+8/place=+0xC/promotiontoid=+0x10. TNation (Extends TBase_Team) id=+0xC/name=+0x10
'   inherited; TContinent id=+8/name=+0xC own.
' Literals read with harness.read_string (a MATCH does not certify literal content on its own,
' but every one below was read out of NSS5.exe, not guessed): "editcompetition", "", "99FF99",
' "FFFFFF", "0" (btnnoofteams' reset text), ":" (the promotion-place id separator), "000000".
'
' SHAPE NOTES (both settled by the byte oracle, not by inspection alone):
'  * The locale gate is `Select g_curcomp.locale : Case 0 <sort+nations> : Default <continents>
'    : End Select`, NOT an If/Else. Select loads the subject into a temp ONCE (`mov eax,[..]`
'    then `mov eax,[eax+0x18]`) and tests the temp register; an If/Else re-reads the field as a
'    direct memory operand (`cmp dword[eax+0x18],0`, 2 bytes shorter) and does not match. The
'    Default block is emitted in the fall-through position (no jump) and Case 0's body is
'    emitted after the unconditional post-cases jump, reached by `je` -- so in memory the
'    continents loop comes first and the nations sort+loop comes second, though Case 0 (nations)
'    is textually first in source (codegen-patterns 10.2).
'  * The "no of teams" block is `If g_curcomp.comptype = 1 <...> Else Select g_curcomp.level :
'    Case 0 <...> : Case 1 <...> : End Select EndIf`, NOT an If/ElseIf/ElseIf chain. Select
'    loads level once; ElseIf re-tests it and costs 15+12 extra bytes across the two gaps.
'  * `md1`/`md2` (matchday-with-99-sentinel) and the two promotion-table concat strings (`s`,
'    `s2`) are named Locals with observable lifetime: matchday because the "+1, then clamp to
'    1 if 99" default is computed before the branch that may overwrite it; `s`/`s2` because the
'    array-literal element that is NOT the concat is evaluated strictly after the array is
'    allocated (`bbArrayNew1D`) while the concat itself runs earlier, only explicable if the
'    concatenated String is a Local already fully computed by the time the literal is built.
'  * `Case 0 ... Case 1` (no `Default`) trailing `jmp` after the `cmp eax,1/je` pair is the
'    Select's own no-match fallthrough, which coincides with the outer If's end label.
'!Global g_editcomp_from:String
'!Global g_curcomp:TCompetition
'!Global g_nations:TList
'!Global g_continents:TList
'!Global g_editcomp_inpid:TInputBox
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
'!Global g_editcomp_btnnoofteams:TButton
'!Global g_editcomp_tblpromplaces:TTable
'!Global g_editcomp_tblpromfromcomps:TTable
'!Global g_editcomp_inpnewpromplace:TInputBox
	Function SetUpScreen:Int(a0:Int, a1:String)
		TScreen.SetActive("editcompetition", "")
		g_editcomp_from = a1
		g_curcomp = TCompetition.SelectById(a0)
		g_editcomp_inpid.SetText(String(g_curcomp.id), "", -1, -1)
		g_editcomp_inpname.SetText(g_curcomp.name, "", -1, -1)
		g_editcomp_inptla.SetText(g_curcomp.tla, "", -1, -1)
		g_editcomp_cmblevel.SelectItem(g_curcomp.level + 1)
		g_editcomp_cmblocale.SelectItem(g_curcomp.locale + 1)
		g_editcomp_cmbbased.ClearItems()
		Select g_curcomp.locale
			Case 0
				TNation.SortListBy(1, 1)
				For Local n:TNation = EachIn g_nations
					g_editcomp_cmbbased.AddItem(n.name, "99FF99", "FFFFFF", n.id)
				Next
			Default
				For Local c:TContinent = EachIn g_continents
					g_editcomp_cmbbased.AddItem(c.name, "99FF99", "FFFFFF", c.id)
				Next
		End Select
		g_editcomp_cmbbased.SelectItem(g_curcomp.based)
		g_editcomp_cmbcomptype.SelectItem(g_curcomp.comptype + 1)
		g_editcomp_cmbstartyear.SelectItem(g_curcomp.startyear + 1)
		g_editcomp_cmbrecurring.SelectItem(g_curcomp.recurring)
		g_editcomp_inpstartweek.SetText(String(g_curcomp.startweek), "", -1, -1)
		g_editcomp_inpduration.SetText(String(g_curcomp.duration), "", -1, -1)
		Local md1:Int = g_curcomp.primarymatchday + 1
		If g_curcomp.primarymatchday = 99 Then md1 = 1
		g_editcomp_cmbmatchday1.SelectItem(md1)
		Local md2:Int = g_curcomp.secondarymatchday + 1
		If g_curcomp.secondarymatchday = 99 Then md2 = 1
		g_editcomp_cmbmatchday2.SelectItem(md2)
		g_editcomp_inpgroups.SetText(String(g_curcomp.groups), "", -1, -1)
		g_editcomp_inprounds.SetText(String(g_curcomp.rounds), "", -1, -1)
		g_editcomp_cmblegs.SelectItem(g_curcomp.legs + 1)
		g_editcomp_cmbregion.SelectItem(g_curcomp.townregion + 1)
		g_editcomp_cmbstatus.SelectItem(g_curcomp.compstatus + 1)
		g_editcomp_btnnoofteams.SetText("0", "", -1, -1)
		If g_curcomp.comptype = 1
			g_editcomp_btnnoofteams.SetText(String(g_curcomp.GetNoofTeamsInRound()), "", -1, -1)
		Else
			Select g_curcomp.level
				Case 0
					Local clubs:TList = TClub.SelectListByLeagueId(g_curcomp.id)
					If Not clubs.IsEmpty()
						g_editcomp_btnnoofteams.SetText(String(clubs.Count()), "", -1, -1)
					EndIf
				Case 1
					If g_curcomp.based > 0 And g_curcomp.comptype = 0 And g_curcomp.lplacesthatpromotetome.IsEmpty()
						Local clubs2:TList = TNation.SelectListByContinent(g_curcomp.based)
						If Not clubs2.IsEmpty()
							g_editcomp_btnnoofteams.SetText(String(clubs2.Count()), "", -1, -1)
						EndIf
					EndIf
			End Select
		EndIf
		g_editcomp_tblpromplaces.ClearItems()
		For Local pp:TPromotionPlace = EachIn g_curcomp.lpromotionplaces
			Local tc:TCompetition = TCompetition.SelectById(pp.promotiontoid)
			If tc <> Null
				Local s:String = String(tc.id) + ":" + tc.tla + ":" + tc.name
				g_editcomp_tblpromplaces.AddItem([pp.GetStringPlace(), s], "000000", "FFFFFF")
			EndIf
		Next
		g_editcomp_tblpromfromcomps.ClearItems()
		For Local pp2:TPromotionPlace = EachIn g_curcomp.lplacesthatpromotetome
			Local tc2:TCompetition = TCompetition.SelectById(pp2.parentid)
			If tc2 <> Null
				Local s2:String = String(tc2.id) + ":" + tc2.tla + ":" + tc2.name
				g_editcomp_tblpromfromcomps.AddItem([s2, pp2.GetStringPlace()], "000000", "FFFFFF")
			EndIf
		Next
		g_editcomp_inpnewpromplace.SetText("", "", -1, -1)
		Return 0
	End Function

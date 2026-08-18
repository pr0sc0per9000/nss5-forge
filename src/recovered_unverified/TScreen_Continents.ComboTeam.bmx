' TScreen_Continents.ComboTeam
' VA 0x00547EBD   903 bytes   KIND=Function, SIG ()i, slot 0x48
'
' FIX (byte-oracle: 341/903, first diff at byte 11 -- `mov dword ptr [ebp-4],Null` in the
' original vs `mov dword ptr [ebp-8],Null` here, i.e. `t` and the SECOND For-loop's hidden
' teampool-array-base temp were sitting in swapped stack slots, and `firstopenrow`/the FIRST
' loop's hidden list-object temp were correspondingly swapped between ebx/edi). Read with
' `python scripts/dis7.py TScreen_Continents ComboTeam` (full original disassembly) and
' compared instruction-by-instruction against our own compiled output (via
' `bytematch.disasm_original(..., path=our_exe)`): apart from this one localised
' allocation swap, EVERY other instruction in the function already matched byte-for-byte
' (same call targets, same field offsets, same CFG shape) -- length was ours=904 vs
' orig=903, off by exactly one. Root cause: the source re-indexed `arr[5]` three separate
' times, once per `ElseIf` comparison (`arr[5] = GetText("sla_Won")`, `arr[5] = ...Lost`,
' `arr[5] = ...Drawn`), instead of reading it once. codegen-patterns.md's own general
' finding applies directly: "our length longer than the original almost always means a
' subexpression is computed twice and the original used a Local" -- and bcc's allocator
' evidently sizes/orders the WHOLE function's temps as one pass, so the extra repeated-read
' pressure from the 3x `arr[5]` access was enough to perturb which physical slot/register
' `t` and the hidden loop temps landed in, even though those temps are used far away from
' the loop body where `arr[5]` is read. Fixed by reading `arr[5]` into `restext:String`
' once, right after `AddItem`, and comparing `restext` in all three `ElseIf` arms (the
' localised W/L/D result text described below) -- matching how a repeated field/index read
' feeding a comparison chain is handled everywhere else already established in this corpus.
' RESIDUAL UNCERTAINTY: the exact mechanism tying `arr[5]`'s repeat count to the `t`/
' teampool-temp slot swap is inferred, not proven by re-disassembling a rebuilt binary
' (this project's passes cannot run the build); if a future byte-oracle pass shows the slot
' swap persists after this change, re-open this note rather than assuming the Local alone
' was sufficient.
'
' ASSUMPTIONS
'  * Globals (names ours except where explain_global.py forces them; only the declared
'    TYPE is load-bearing):
'      0x00C671E8 g_combo_competition:TCombo   (CERTAIN, shared name w/ ComboContinent.bmx
'          and ComboCompetition.bmx -- same slot 0xc0 GetSelectedItemId() usage there)
'      0x00C67224 g_continents_mode:Int        (CERTAIN, shared w/ every Combo* sibling)
'      0x00C67220 g_continents_competition:TCompetition (matches ComboCompetition.bmx)
'      0x00C671EC g_continents_int03:Int       0x00C67208 g_continents_int05:Int
'          (both match ComboCompetition.bmx's own naming for these two addresses)
'      0x00C671D0 g_continents_panfixtures:TPanel   (only name explain_global reports)
'      0x00C6720C/10/14/18/1C g_continents_btnfixturesfirst/left/round/right/last:TButton
'          (only names explain_global reports; all from TScreen_Continents.CreateScreen)
'      0x00C671D4 g_table_02:TTable   0x00C671D8 g_table_03:TTable
'          (explain_global also offers g_continents_tblfixturesleague/tblfixturesclub at
'          equal STRONG tier; g_table_02/g_table_03 chosen to match the two closest
'          siblings, ComboContinent.bmx and ComboCompetition.bmx, which already hide/show
'          these same two tables under these names.)
'
'  * PTR_FUN_00C674B4, PTR_FUN_00C59E0C, PTR_FUN_00C59A20 and PTR_FUN_00C67498 are all
'    static cross-Type calls through class tables. Each was resolved by reading the
'    4-byte pointer actually stored at that address in NSS5.exe (not guessed):
'        0x00C674B4 -> 0x005492C1 = TScreen_Continents.RefreshComboColours   ()i
'        0x00C59E0C -> 0x004C146C = TClub.SelectById                        (i):TClub
'        0x00C59A20 -> 0x004BEC06 = TNation.SelectById                      (i):TNation
'        0x00C67498 -> 0x00548970 = TScreen_Continents.SetUpLeagueTable     ()i
'    (TClub/TNation.SelectById also match the identical dispatch already verified in
'    ComboCompetition.bmx.)
'
'  * `local_8[8]` is TBase_Team.labelshortname (offset 0x20, confirmed via
'    scripts/fields2.py TBase_Team). The panel title build
'    (FUN_004c5549/FUN_004a7c20 x2/TGadget.SetText slot 0x64) is the standard
'    Ghidra-merge shape documented on TButton.CreateButton.bmx et al.: SetText's real
'    sig is ($,$,i,i), and disassembly at 0x00547F7D-0x00547FB7 shows `push -1 / push -1
'    / push 0xc5d284("") / push 0xc850f0("Fixtures")` all happen BEFORE GetText even
'    runs, with the vtable call's own `add esp,0x14` (5 dwords: self+4 args) proving the
'    -1,-1,"" belong to SetText, not to GetText. The two _bbStringConcat calls were
'    likewise read directly off the disassembly (push order, not Ghidra's merged
'    display): concat(labelshortname," ") first, then concat(that, GetText("Fixtures")).
'    Final text = t.labelshortname + " " + GetText("Fixtures").
'
'  * FUN_004A6800 is NOT FUN_004A8F60 (_bbObjectDowncast, used everywhere else for plain
'    Object EachIn). It appears at exactly two call sites in the whole game
'    (here, and the still-unrecovered twin TScreen_Leagues.ComboClub@00545746), always
'    downcasting the result of `t.GetStringArrayFixtureList(...)`'s enumerator straight
'    off NextObject() (slot 0x34, confirmed 0-arg via disasm: `add esp,4` after the call,
'    not 8 -- so the shown `&DAT_00c59058` second argument is spillover for FUN_004A6800,
'    per the Ghidra-merge trap). Cross-checking TBase_Team.GetStringArrayFixtureList's own
'    body (0x004BD132) shows it builds a TList of boxed String[] arrays (via
'    TFixture.GetStringArrayForTeamId, slot 0x4c, sig (i)[]$); 0x00C59058 is the BBArray
'    element-type descriptor for String elsewhere in this project
'    (TProfile.GetStringArrayPropertyOwned.bmx, TScreen_EditContinents.SetUpScreen.bmx).
'    So FUN_004A6800 is the runtime's Object->String[] array downcast used by
'    `For Local arr:String[] = EachIn list`, distinct from the plain-Object downcast --
'    consistent with call_arity.tsv (2 args) and its own body (0x004A6800, a
'    strcmp-based type-name check, unlike 4A8F60's class-table walk).
'
'  * `puVar6[0xb]` is `arr[5]`: TFixture.GetStringArrayForTeamId (0x004C3BF4) allocates
'    the array via `_bbArrayNew1D(desc, 6)` and its own element stores land at raw
'    indices 6..11 (String[3] literals elsewhere in this project put data at +0x18,
'    confirming the 6-dword array header), so raw index 0xb=11 is source index 5, the
'    last of six elements. That element is filled from exactly the same three literals
'    ("sla_Won"/"sla_Lost"/"sla_Drawn", read via scripts/harness.read_string) that ComboTeam
'    compares it against here, confirming arr[5] is the localised W/L/D result text.
'
'  * `local_18` (named `rowidx` here) is a DEAD counter: initialised to 0 and never
'    incremented anywhere in this function (verified against the full disassembly --
'    no `add`/`inc` on [ebp-0x14] exists). The twin TScreen_Leagues.ComboClub DOES
'    increment its equivalent (`iVar7 = iVar7 + 1`), so this is a genuine divergence
'    between the two screens, not a transcription slip -- reproduced as found, per
'    guide 2 (preserve-by-default). Its only effect: `firstopenrow` (iVar8), once set on
'    the first not-Won/Lost/Drawn fixture, is always set to 0.
'
'  * The `g_table_03.SetRowColour(g_table_03.CountItems(), "colour")` calls are another
'    instance of the same merge shape: TTable.CountItems is a confirmed 0-arg method
'    (SIG=()i), so the colour literal shown attached to its call line is spillover for
'    the following SetRowColour(i,$)i call; disassembly at 0x005480C7-0x005480ED
'    confirms the colour is pushed BEFORE CountItems runs and SetRowColour's own
'    `add esp,0xc` (self+2 args) consumes it as the second argument.
'  * TTable.AddItem's real sig is ([]$,$,$)i; the two `&PTR_PTR_005c7d40` operands are
'    both the empty-string literal (established: TTable.New.bmx, TFormation.New.bmx),
'    written `""` per house style (TScreen_Promotions.SetUpScreen.bmx).
'  * TGadget slot 0x54=Hide, 0x58=Show, 0x64=SetText (from extracted/decomp/TGadget.*.c);
'    TTable's own slots 0x9c=ClearItems, 0x94=AddItem, 0xac=SetRowColour, 0xdc=
'    SelectItemByRow, 0xe8=ShowItem, 0xec=CountItems (from extracted/decomp/TTable.*.c).
'  * `g_continents_competition.teampool` / `tp.list` / `td.teamid` mirror the identical,
'    already-verified enumeration in ComboCompetition.bmx line 41 onward (same raw
'    array-walk shape, same &PTR_DAT_00c64b80 TTableData typeid at the inner EachIn).

'!Global g_combo_competition:TCombo
'!Global g_continents_mode:Int
'!Global g_continents_competition:TCompetition
'!Global g_continents_int03:Int
'!Global g_continents_int05:Int
'!Global g_continents_panfixtures:TPanel
'!Global g_continents_btnfixturesfirst:TButton
'!Global g_continents_btnfixturesleft:TButton
'!Global g_continents_btnround:TButton
'!Global g_continents_btnfixturesright:TButton
'!Global g_continents_btnfixtureslast:TButton
'!Global g_table_02:TTable
'!Global g_table_03:TTable

Function ComboTeam:Int()
	RefreshComboColours()
	Local t:TBase_Team = Null
	Select g_continents_mode
		Case 0
			t = TClub.SelectById(g_combo_competition.GetSelectedItemId())
		Case 1
			t = TNation.SelectById(g_combo_competition.GetSelectedItemId())
	End Select
	If t <> Null
		g_continents_btnfixturesfirst.Hide()
		g_continents_btnfixturesleft.Hide()
		g_continents_btnround.Hide()
		g_continents_btnfixturesright.Hide()
		g_continents_btnfixtureslast.Hide()
		g_continents_panfixtures.SetText(t.labelshortname + " " + GetText("Fixtures"), "", -1, -1)
		g_table_02.Hide()
		g_table_03.Show()
		g_table_03.ClearItems()
		Local rowidx:Int = 0
		Local firstopenrow:Int = -1
		For Local arr:String[] = EachIn t.GetStringArrayFixtureList(g_continents_competition.locale)
			g_table_03.AddItem(arr, "", "")
			Local restext:String = arr[5]
			If restext = GetText("sla_Won")
				g_table_03.SetRowColour(g_table_03.CountItems(), "99FF99")
			ElseIf restext = GetText("sla_Lost")
				g_table_03.SetRowColour(g_table_03.CountItems(), "FF9999")
			ElseIf restext = GetText("sla_Drawn")
				g_table_03.SetRowColour(g_table_03.CountItems(), "9999FF")
			ElseIf firstopenrow = -1
				firstopenrow = rowidx
			EndIf
		Next
		g_table_03.SelectItemByRow(0)
		If firstopenrow > -1
			g_table_03.ShowItem(firstopenrow + 10)
		EndIf
		g_continents_int03 = 0
		g_continents_int05 = 1
		For Local tp:TTeamPool = EachIn g_continents_competition.teampool
			For Local td:TTableData = EachIn tp.list
				If td.teamid = t.id
					SetUpLeagueTable()
					Return 0
				EndIf
			Next
			g_continents_int03 = g_continents_int03 + 1
		Next
	EndIf
	Return 0
End Function

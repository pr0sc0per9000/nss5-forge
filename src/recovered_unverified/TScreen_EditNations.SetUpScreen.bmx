' TScreen_EditNations.SetUpScreen
' VA 0x0052A8BC   1556 bytes   sig (i)i   class-table slot 0x34   KIND=Function (static)
' byte-identical vs NSS5.exe
' NOT YET BYTE-VERIFIED. Reconstructed from extracted/decomp/
' TScreen_EditNations.SetUpScreen@0052a8bc.c, cross-checked against object_model.json field
' offsets and against the two closest structural siblings, TScreen_EditClubs.SetUpScreen.bmx
' and TScreen_EditContinents.SetUpScreen.bmx (both already byte-verified in src/recovered/).
' Staged in recovered_pending pending an oracle pass; not yet claimed byte-identical.
'
' Loads nation a0, repopulates the four nation/rival combos and the continent combo from
' their master lists, writes every editor widget from the loaded nation's fields, rebuilds
' the club-membership table, and refreshes the kit preview icons.
'
' GLOBALS -- addresses are fact; names are the established corpus choices, not invented here
' (python scripts/explain_global.py <addr|name> for each):
'   0x00C65034 g_curnat:TNation -- ONLY Global this body assigns. explain_global.py's solver
'     resolves this address to three STRONG aliases, all TNation, all already used by
'     already-recovered TScreen_EditNations bodies that only READ it: g_curnat
'     (ButtonNextNat.bmx), g_curnation (ButtonPrevNat.bmx), g_editnation (EditKit.bmx).
'     extracted/global_alias_unified.tsv already picks the canonical: "g_curnation -> g_curnat"
'     and "g_editnation -> g_curnat" (both STRONG). g_curnat is used here directly. This is
'     the ONE dead-Global write docs/name-unification.md's "what is left" section names this
'     function for; UpdateNat.bmx's g_editnat_nation is the same slot under a fourth alias
'     (also merges to g_curnat).
'   0x00C596F0 g_nations:TList, 0x00C6080C g_continents:TList, 0x00C59A44 g_clubs:TList --
'     all three STRONG/confirmed master lists, already used throughout the corpus under
'     these exact names (ButtonNextNat.bmx / TContinent.New.bmx / TScreen_EditClubs.
'     SetUpScreen.bmx respectively).
'   0x00C6503C g_cmbNation:TCombo -- STRONG, already used by CreateScreen.bmx and
'     ComboNation.bmx under this exact spelling (explain_global.py's solver prints the
'     lowercased key "g_cmbnation"; BlitzMax identifiers are case-insensitive and
'     assemble.py's alias rewrite is explicitly case-insensitive too, so the existing
'     corpus spelling is reused verbatim rather than introducing a third casing).
'   Every remaining address below (0x00C65044 .. 0x00C65090) gets "0 names resolved" from
'   explain_global.py's SOLVER -- the alignment tool would not commit to one name across a
'   run of same-typed consecutive slots touched by only one body. But CreateScreen.bmx (the
'   constructor for every one of these widgets, already byte-verified, already live in
'   src/recovered/) declares a distinct '!Global pragma naming each address individually,
'   and this function only ever READS those same widgets CreateScreen already built -- so
'   CreateScreen's names are reused verbatim rather than re-picked, exactly as this project's
'   convention already does for g_editnat_ibName etc. in UpdateNat.bmx (explain_global.py
'   g_editnat_ibname confirms CreateScreen.bmx and UpdateNat.bmx already agree on it):
'     0x00C65044 g_editnat_btnId:TButton        0x00C6504C g_editnat_ibName:TInputBox
'     0x00C65050 g_editnat_ibShortName:TInputBox 0x00C65054 g_editnat_ibTla:TInputBox
'     0x00C65058 g_editnat_ibNationality:TInputBox 0x00C6505C g_editnat_ibStrength:TInputBox
'     0x00C65060 g_editnat_cmbContinent:TCombo  0x00C65064 g_editnat_cmbRival1:TCombo
'     0x00C65068 g_editnat_cmbRival2:TCombo     0x00C6506C g_editnat_cmbRival3:TCombo
'     0x00C65070 g_editnat_cmbClimate:TCombo    0x00C65074 g_editnat_cmbSkin1:TCombo
'     0x00C65078 g_editnat_cmbSkin2:TCombo      0x00C6507C g_editnat_ibStadiumName:TInputBox
'     0x00C65080 g_editnat_ibStadiumCapacity:TInputBox
'     0x00C65084 g_editnat_ibStadiumLong:TInputBox  0x00C65088 g_editnat_ibStadiumLat:TInputBox
'     0x00C6508C g_editnat_btnMembers:TButton   0x00C65090 g_editnat_tblMembers:TTable
'   NOTE on 0x00C65090: explain_global.py g_table reports this exact address is ALSO the
'   name GoMember.bmx (a different already-recovered TScreen_EditNations body) uses --
'   "g_table" -- but that name is independently AMBIGUOUS across four unrelated addresses
'   in the corpus (0x00C65A48/0x00C65038/0x00C65090/0x00C679B8), one of which is EditNations'
'   OWN "tbl_details" table (0x00C65038, also named g_table by CreateScreen.bmx). Since
'   CreateScreen.bmx -- the constructor -- already disambiguates the two EditNations tables
'   under two distinct names (g_table for 0x00C65038, g_editnat_tblMembers for 0x00C65090),
'   and this function never touches 0x00C65038 at all, g_editnat_tblMembers is used here;
'   GoMember.bmx's reuse of the collided "g_table" is a pre-existing corpus issue this file
'   does not attempt to fix.
'
' CALL TARGETS (class_tables.tsv classtable_va + vtable_map.tsv slot):
'   0x00C61C88 = TScreen+0x5C SetActive($,$):TScreen
'   0x00C599C8 = TNation+0x78 SortListBy(i,i)i    0x00C59DAC = TClub+0x94 SortListBy(i,i)i
'   TCombo+0x8C ClearItems()i   TCombo+0x90 AddItem($,$,$,i)i   TCombo+0xAC SelectItem(i)i
'   TTable+0x9C ClearItems()i   TTable+0x94 AddItem([]$,$,$)i   TTable+0xEC CountItems()i
'   TGadget+0x64 SetText($,$,i,i)i (TButton/TInputBox both inherit it unmodified)
'   Downcast type descriptors (= each Type's own class-table VA, class_tables.tsv): TNation
'   0x00C599C8, TContinent 0x00C60958, TClub 0x00C59DAC -- the three addresses
'   _bbObjectDowncast (FUN_004a8f60) is called against in the three EachIn loops.
'   0x004A7AC0 = _bbStringFromInt (Ghidra merges its one argument with the pushes that
'   follow it for the SUBSEQUENT SetText call -- codegen-patterns 13.2, already confirmed
'   in CreateScreen.bmx's own header). 0x0050640C = module FormatDecimals(f,i)$ (already
'   recovered, src/recovered_module/). 0x004A7C20 = _bbStringConcat x3, chaining
'   GetText("Clubs") + " (" + String(count) + ")" -- identical shape to
'   TScreen_EditContinents.SetUpScreen.bmx's g_ec_btn_nations.SetText line, string literals
'   0x00C824E4 "Clubs", 0x00C70F08 " (", 0x00C70EF8 ")" (harness.read_string). 0x00C5D284 is
'   the module empty-string constant (confirmed address, used for every omitted $ SetText
'   colour arg here); 0x00C82BA8 "nations", 0x00C7F250 "BBBBBB", 0x00C5D680 "FFFFFF"
'   (already confirmed in CreateScreen.bmx's own header).
'
' Fields (object_model.json): TBase_Team (TNation/TClub's super) id=+0xC name=+0x10
'   shortname=+0x14 tla=+0x18 strength=+0x24 rivalid1=+0x28 rivalid2=+0x2C rivalid3=+0x30
'   stadiumname=+0x34 stadiumcapacity=+0x38 stadiumlongitude=+0x3C(f) stadiumlatitude=+0x40(f).
'   TNation's own: nationality=+0x60($) continent=+0x64 climate=+0x68 primaryskin=+0x6C
'   secondaryskin=+0x70. TClub's own: nationid=+0x64. TContinent (Object-rooted): id=+8
'   name=+0xC.
'
' SHAPE NOTES (read off the decompilation; not oracle-confirmed)
'  * Combo population and current-nation detection happen in ONE pass over g_nations
'    (AddItem to all four combos is unconditional per iterated nation; the id match against
'    a0 is a nested, non-exclusive check within the same iteration) -- NOT two separate
'    passes the way it might read more simply. Reproduced as one loop, not split.
'  * The rival1/2/3 combos are populated with the FULL nation list, INCLUDING the nation
'    currently being edited -- unlike TScreen_EditClubs.SetUpScreen's equivalent rival
'    population, which explicitly excludes `c.id <> g_editclubs_club.id`. No such guard
'    exists here (no comparison against a0 inside the AddItem block); a nation can select
'    itself as its own rival. Preserved as-is (law 3), not added to match Clubs' behaviour.
'  * A SECOND, fresh EachIn pass over g_nations is required to find the three rival combo
'    indices, because rivalid1/2/3 belong to g_curnat, which is only fully known once the
'    first pass has found it (it could be any position in the list, including a later one).
'  * g_editnat_ibStrength is populated (offset +0x24, via bbStringFromInt), but NOT next to
'    the other four SetText calls (id/name/shortname/tla/nationality) -- it comes after the
'    continent combo is rebuilt and selected. Reproduced in the original's statement order,
'    not grouped with the other InputBox SetText calls.
'  * TNation.SortListBy(1,1) is called once, only before the nation/rival-combo pass;
'    the second (index-only) pass re-walks the same list without re-sorting it.
'    TClub.SortListBy(1,1) is called once, immediately before the club-membership pass.
'  * No guard clause and no early/mid-function return: the function is straight-line except
'    for its four EachIn loops, matching TScreen_EditContinents.SetUpScreen.bmx's shape
'    (same (i)i signature, no guard) rather than TScreen_EditClubs.SetUpScreen.bmx's guarded
'    one. The decompilation's own trailing `return 0;` is written here as an explicit
'    `Return 0` (TScreen_EditClubs.SetUpScreen.bmx does the same at its own tail;
'    TScreen_EditContinents.SetUpScreen.bmx omits it and relies on fall-through -- UNCERTAIN which
'    is byte-correct for a straight-line (i)i Function with no early return; kept explicit
'    here as the more literal transcription of the decompiled tail, with no behavioural
'    difference either way).
'
' REFINE PASS (2026-08-16, score 1227/1556 78.9%, first_diff byte 10 = 2nd byte of the
' `push 0xc5d284` empty-string immediate that is arg 2 of the opening TScreen.SetActive
' call): went through the decompilation line by line against this body and found no
' statement, argument, order, or type disagreement to fix.
'   * Every one of the ~55 calls below was checked against the decompiled line it compiles
'     from: same callee, same argument COUNT, same argument ORDER, same field offsets.
'   * The full statement sequence was cross-checked against explain_global.py's independent
'     "original touches, in machine-code order" trace for g_curnat (0x00C65034) -- a list
'     derived straight from the ORIGINAL binary's disassembly, not the C decompile -- and it
'     lines up exactly with this body's global-touch order end to end (SetActive; four
'     ClearItems; g_nations pass with the id-match store into g_curnat; five SetText calls;
'     continent combo rebuild + select; strength SetText; four stadium SetText/FormatDecimals;
'     climate/skin selects; table clear+rebuild; final count SetText).
'   * The nat/nat2 split for the two separate EachIn passes over g_nations mirrors
'     TScreen_EditClubs.SetUpScreen.bmx's own cp/cp2 split for its two passes over
'     g_competitions (BlitzMax Classic Locals are function-scoped, so a second `For Local
'     nat:TNation = EachIn g_nations` in the same Function cannot reuse the first pass's
'     name) -- same established fix for the same underlying constraint, not a fresh
'     invention here.
'   * String literal CONTENT at every address the decompilation pushes was independently
'     re-verified with harness.read_string() against binary/NSS5.exe rather than trusted
'     from an old note: 0x00C82BA8="nations", 0x00C7F250="BBBBBB", 0x00C5D680="FFFFFF",
'     0x00C824E4="Clubs", 0x00C70F08=" (", 0x00C70EF8=")", 0x00C5D284=None (the interned
'     empty string) -- all as this file's header already claimed.
'   * The length delta is already exactly 0 (1556/1556), which is itself evidence the
'     instruction shape (branch count, call count, loop count) already matches -- a wrong
'     If/Select shape or a hoisted/dropped Local would show as a nonzero delta, and none
'     is present.
' Conclusion: the first-difference bytes shown in the score report (the empty-string
' immediate, the "nations" immediate, and the SetActive call-thunk immediate, all inside
' the OPENING call) are absolute address operands, not structure -- and TScreen_
' EditContinents.SetUpScreen.bmx's OWN disassembly (harness.disasm_original(0x00528D01))
' shows it pushes that exact same 0x00C5D284/0x00C61C88 pair for its own, differently-
' worded, TScreen.SetActive(...) call. Two independently-shaped call sites agreeing with
' each other but not with today's score report points at project-wide data/string-pool
' layout still being unsettled by the other bodies in flight this run, not at a defect in
' this statement. Per rule 4, left as-is rather than guessing at a rewrite with nothing in
' the decompilation left to justify one.
'
'!Global g_curnat:TNation
'!Global g_nations:TList
'!Global g_cmbNation:TCombo
'!Global g_editnat_cmbRival1:TCombo
'!Global g_editnat_cmbRival2:TCombo
'!Global g_editnat_cmbRival3:TCombo
'!Global g_editnat_btnId:TButton
'!Global g_editnat_ibName:TInputBox
'!Global g_editnat_ibShortName:TInputBox
'!Global g_editnat_ibTla:TInputBox
'!Global g_editnat_ibNationality:TInputBox
'!Global g_editnat_cmbContinent:TCombo
'!Global g_continents:TList
'!Global g_editnat_ibStrength:TInputBox
'!Global g_editnat_ibStadiumName:TInputBox
'!Global g_editnat_ibStadiumCapacity:TInputBox
'!Global g_editnat_ibStadiumLong:TInputBox
'!Global g_editnat_ibStadiumLat:TInputBox
'!Global g_editnat_cmbClimate:TCombo
'!Global g_editnat_cmbSkin1:TCombo
'!Global g_editnat_cmbSkin2:TCombo
'!Global g_editnat_tblMembers:TTable
'!Global g_clubs:TList
'!Global g_editnat_btnMembers:TButton
TScreen.SetActive("nations", "")
g_cmbNation.ClearItems()
g_editnat_cmbRival1.ClearItems()
g_editnat_cmbRival2.ClearItems()
g_editnat_cmbRival3.ClearItems()
Local foundNation:Int = 0
Local foundRival1:Int = 0
Local foundRival2:Int = 0
Local foundRival3:Int = 0
Local n:Int = 1
TNation.SortListBy(1, 1)
For Local nat:TNation = EachIn g_nations
	g_cmbNation.AddItem(nat.name, "BBBBBB", "FFFFFF", nat.id)
	g_editnat_cmbRival1.AddItem(nat.name, "BBBBBB", "FFFFFF", nat.id)
	g_editnat_cmbRival2.AddItem(nat.name, "BBBBBB", "FFFFFF", nat.id)
	g_editnat_cmbRival3.AddItem(nat.name, "BBBBBB", "FFFFFF", nat.id)
	If nat.id = a0 Then
		g_curnat = nat
		foundNation = n
	EndIf
	n :+ 1
Next
n = 1
For Local nat2:TNation = EachIn g_nations
	If nat2.id = g_curnat.rivalid1 Then foundRival1 = n
	If nat2.id = g_curnat.rivalid2 Then foundRival2 = n
	If nat2.id = g_curnat.rivalid3 Then foundRival3 = n
	n :+ 1
Next
g_cmbNation.SelectItem(foundNation)
g_editnat_cmbRival1.SelectItem(foundRival1)
g_editnat_cmbRival2.SelectItem(foundRival2)
g_editnat_cmbRival3.SelectItem(foundRival3)
g_editnat_btnId.SetText(String(g_curnat.id), "", -1, -1)
g_editnat_ibName.SetText(g_curnat.name, "", -1, -1)
g_editnat_ibShortName.SetText(g_curnat.shortname, "", -1, -1)
g_editnat_ibTla.SetText(g_curnat.tla, "", -1, -1)
g_editnat_ibNationality.SetText(g_curnat.nationality, "", -1, -1)
g_editnat_cmbContinent.ClearItems()
For Local cont:TContinent = EachIn g_continents
	g_editnat_cmbContinent.AddItem(cont.name, "BBBBBB", "FFFFFF", cont.id)
Next
g_editnat_cmbContinent.SelectItem(g_curnat.continent)
g_editnat_ibStrength.SetText(String(g_curnat.strength), "", -1, -1)
g_editnat_ibStadiumName.SetText(g_curnat.stadiumname, "", -1, -1)
g_editnat_ibStadiumCapacity.SetText(String(g_curnat.stadiumcapacity), "", -1, -1)
g_editnat_ibStadiumLong.SetText(FormatDecimals(g_curnat.stadiumlongitude, 3), "", -1, -1)
g_editnat_ibStadiumLat.SetText(FormatDecimals(g_curnat.stadiumlatitude, 3), "", -1, -1)
g_editnat_cmbClimate.SelectItem(g_curnat.climate + 1)
g_editnat_cmbSkin1.SelectItem(g_curnat.primaryskin)
g_editnat_cmbSkin2.SelectItem(g_curnat.secondaryskin)
g_editnat_tblMembers.ClearItems()
TClub.SortListBy(1, 1)
For Local cl:TClub = EachIn g_clubs
	If cl.nationid = g_curnat.id
		g_editnat_tblMembers.AddItem([String(cl.id), cl.name, String(cl.strength)], "", "")
	End If
Next
g_editnat_btnMembers.SetText(GetText("Clubs") + " (" + String(g_editnat_tblMembers.CountItems()) + ")", "", -1, -1)
RefreshKits()
Return 0

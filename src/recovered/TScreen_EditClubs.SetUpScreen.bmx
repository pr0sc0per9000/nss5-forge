' TScreen_EditClubs.SetUpScreen
' VA 0x0052E105   1841 bytes   mode=reloc   byte-identical vs NSS5.exe (1841/1841,
' reloc_masked=117; re-verified with NSS5_NO_LEARN=1 so no call operand was masked by a
' name this run itself taught.)
' KIND=Function (static, no implicit Self), SIG (i,$)i, class-table slot 0x34
' Params: a0:Int = club id to load, a1:String = the screen this was entered from (stored
'   into g_editclubs_caller only when non-empty; ButtonNextClub.bmx already calls this
'   as `TScreen_EditClubs.SetUpScreen(c.id, "")`).
'
' ASSUMPTIONS -- module Globals (NAMES ARE OURS; the declared TYPE is load-bearing because
' it selects the vtable slot for every call made through it). Every address below is one
' CreateScreen.bmx (VA 0x0052CF39) already declared and named, or that ButtonQuit.bmx /
' EditKit.bmx / ButtonNextClub.bmx already established -- reused verbatim, not re-picked:
'   0x00C653C0 g_editclubs_caller:String   (ButtonQuit.bmx's g_editclubs_caller)
'   0x00C653C4 g_editclubs_club:TClub      (EditKit.bmx / RefreshKits.bmx's g_editclubs_club;
'                construction site = TClub.SelectById(a0))
'   0x00C653EC/F0/F4/F8/FC/00/04 g_editclubs_cmb{Nation,Rival1,Rival2,Rival3,League,
'                ContinentalComp,BTeamOf}:TCombo           (CreateScreen.bmx)
'   0x00C653D0 g_editclubs_btnId:TButton                    (CreateScreen.bmx)
'   0x00C653D8/DC/E0/E4/E8 g_editclubs_ib{Name,ShortName,Tla,NickName,Strength}:TInputBox
'   0x00C65408/0C/10/14 g_editclubs_ibStadium{Name,Capacity,Long,Lat}:TInputBox
'   0x00C596F0 g_nations:TList (of TNation)   0x00C59A44 g_clubs:TList (of TClub)
'   0x00C6099C g_competitions:TList (of TCompetition) -- all three are the master
'                per-Type lists, same construction pattern as g_nations/g_clubs already
'                established by TScreen_EditCompetition.SetUpScreen.bmx / ButtonNextClub.bmx.
'
' Class-table slots (class_tables.tsv classtable_va + vtable_map.tsv slot):
'   0x00C59E0C = TClub+0x60      SelectById(i):TClub          0x00C61C88 = TScreen+0x5C SetActive($,$):TScreen
'   0x00C59A40 = TNation+0x78    SortListBy(i,i)i              0x00C59E40 = TClub+0x94   SortListBy(i,i)i
'   0x00C616DC = TCompetition+0x11C SortListBy(i,i)i            0x00C59A20 = TNation+0x58 SelectById(i):TNation
'   TCombo+0x8C ClearItems()i   TCombo+0x90 AddItem($,$,$,i)i   TCombo+0xAC SelectItem(i)i
'   TGadget+0x64 SetText($,$,i,i)i (TButton/TInputBox both inherit it unmodified)
' Downcast type descriptors (= each Type's OWN class-table VA, per class_tables.tsv,
' confirming the EachIn loop var types beyond doubt): TNation classtable=0x00C599C8,
' TClub classtable=0x00C59DAC, TCompetition classtable=0x00C615C0 -- these are exactly the
' three addresses `_bbObjectDowncast` (0x004A8F60) is called with in the three EachIn loops.
' 0x004A6A30 = _bbStringCompare (unused after the guard-clause rewrite made a1's blank-
' check simpler, kept the call regardless -- see SHAPE NOTES). 0x004A7AC0 = _bbStringFromInt
' (Ghidra merges its one argument with the pushes that follow for the SUBSEQUENT SetText
' call -- read the raw `add esp,4`, codegen-patterns 13.2 / CreateScreen.bmx's own note).
' 0x0050640C = module FormatDecimals(f,i)$ (already recovered, src/recovered_module/).
'
' Fields: TBase_Team (TClub/TNation's super) id=+0xC name=+0x10 shortname=+0x14 tla=+0x18
'   strength=+0x24 rivalid1=+0x28 rivalid2=+0x2C rivalid3=+0x30 stadiumname=+0x34
'   stadiumcapacity=+0x38 stadiumlongitude=+0x3C(f) stadiumlatitude=+0x40(f). TClub's own:
'   nickname=+0x60 nationid=+0x64 leagueid=+0x68 continentalcompid=+0x6C bteamofid=+0x70.
'   TNation's own: continent=+0x64. TCompetition (Object-rooted, own fields from +8):
'   id=+8 name=+0xC locale=+0x18 level=+0x1C based=+0x20 comptype=+0x24.
'
' Literals read with harness.read_string (a MATCH does not certify literal content on its
' own): 0x00C83698 'editclubs', 0x00C5D680 'FFFFFF', 0x00C7F250 'BBBBBB'. 0x00C5D284 is the
' empty string (confirmed address, same one TCombo.SelectItem.bmx already names "the empty
' string" -- read_string returns None for it because bcc emits the interned empty BBString
' specially, not as a normal literal blob).
'
' SHAPE NOTES (both settled by the byte oracle, not by inspection alone):
'  * The guard is `If Not g_editclubs_club Then Return 0`, NOT `If club <> Null Then <body>
'    End If`. The latter compiles to a direct `cmp dword [g],<Null> / je` (12 bytes,
'    codegen-patterns 10.3) and is 15 bytes SHORTER than the original at this exact offset;
'    the original's `mov eax,[g] / cmp eax,<Null> / setne al / movzx eax,al / cmp eax,0 /
'    jne` (21 bytes) is the documented `If Not x` emission, branch sense inverted. The rest
'    of the function is therefore NOT nested inside an If block -- it is a flat guard-clause
'    body, matching the single shared `mov eax,0 / jmp <epilogue>` both the guard and the
'    function's own trailing `Return 0` jump to.
'  * `clubNation` (TNation, the club's own nation, looked up once for the ContinentalComp
'    loop's `based = clubNation.continent` test) is computed BEFORE the League loop, not
'    immediately before the ContinentalComp loop that actually uses it -- moving its
'    computation immediately before the loop that reads it FREES its live range to fit
'    inside a single loop (short block_count), and bcc then keeps it in a register (edi),
'    stealing edi from the enumerator and costing 20 bytes at a different offset (register,
'    not stack, holds it) plus follow-on 1-byte substitutions through the rest of the
'    ContinentalComp loop. Declared before the League loop, `clubNation` is live across BOTH
'    loops (large block_count -> low cost -> spilled to [ebp-0xC], codegen-patterns 22.1-2)
'    exactly as the original has it, and every one of those follow-on diffs disappears with
'    it. Textbook block_count lever (22.3 point 3): a *placement* question, not a
'    declaration-order one.
'  * All three master lists (`g_nations`/`g_clubs`/`g_competitions`) are walked with plain
'    `For Local x:T = EachIn list` -- bcc's typed-EachIn codegen downcasts every element
'    against the loop var's OWN class-table VA and silently skips non-matches (never
'    observed here since every list holds only its own Type, but it is why each loop opens
'    with a `_bbObjectDowncast` + Null check before the loop body proper).
'  * The four rival-style "found index" trackers (rivalid1/2/3/bteamofid) and the League/
'    ContinentalComp AddItem calls hard-code the `id` argument to literal 0 for League and
'    ContinentalComp items (SelectItem uses the running counter/position, not the id) --
'    reproduced as-is, not "fixed" to pass cp.id (law 3).
'!Global g_editclubs_club:TClub
'!Global g_editclubs_caller:String
'!Global g_editclubs_cmbNation:TCombo
'!Global g_editclubs_cmbRival1:TCombo
'!Global g_editclubs_cmbRival2:TCombo
'!Global g_editclubs_cmbRival3:TCombo
'!Global g_editclubs_cmbLeague:TCombo
'!Global g_editclubs_cmbContinentalComp:TCombo
'!Global g_editclubs_cmbBTeamOf:TCombo
'!Global g_editclubs_btnId:TButton
'!Global g_editclubs_ibName:TInputBox
'!Global g_editclubs_ibShortName:TInputBox
'!Global g_editclubs_ibTla:TInputBox
'!Global g_editclubs_ibNickName:TInputBox
'!Global g_editclubs_ibStrength:TInputBox
'!Global g_editclubs_ibStadiumName:TInputBox
'!Global g_editclubs_ibStadiumCapacity:TInputBox
'!Global g_editclubs_ibStadiumLong:TInputBox
'!Global g_editclubs_ibStadiumLat:TInputBox
'!Global g_nations:TList
'!Global g_clubs:TList
'!Global g_competitions:TList
	Function SetUpScreen:Int(a0:Int, a1:String)
		g_editclubs_club = TClub.SelectById(a0)
		If Not g_editclubs_club Then Return 0
		TScreen.SetActive("editclubs", "")
		If a1 <> "" Then g_editclubs_caller = a1
		g_editclubs_cmbNation.ClearItems()
		g_editclubs_cmbRival1.ClearItems()
		g_editclubs_cmbRival2.ClearItems()
		g_editclubs_cmbRival3.ClearItems()
		g_editclubs_cmbLeague.ClearItems()
		g_editclubs_cmbContinentalComp.ClearItems()
		g_editclubs_cmbBTeamOf.ClearItems()
		Local foundNation:Int = 0
		Local foundRival1:Int = 0
		Local foundRival2:Int = 0
		Local foundRival3:Int = 0
		Local foundLeague:Int = 0
		Local foundContinentalComp:Int = 0
		Local foundBTeamOf:Int = 0
		Local n:Int = 1
		TNation.SortListBy(1, 1)
		For Local nat:TNation = EachIn g_nations
			g_editclubs_cmbNation.AddItem(nat.name, "BBBBBB", "FFFFFF", nat.id)
			If nat.id = g_editclubs_club.nationid Then foundNation = n
			n :+ 1
		Next
		g_editclubs_cmbNation.SelectItem(foundNation)
		n = 1
		TClub.SortListBy(2, 1)
		For Local c:TClub = EachIn g_clubs
			If c.nationid = g_editclubs_club.nationid And c.id <> g_editclubs_club.id
				g_editclubs_cmbRival1.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
				g_editclubs_cmbRival2.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
				g_editclubs_cmbRival3.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
				g_editclubs_cmbBTeamOf.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
				If c.id = g_editclubs_club.rivalid1 Then foundRival1 = n
				If c.id = g_editclubs_club.rivalid2 Then foundRival2 = n
				If c.id = g_editclubs_club.rivalid3 Then foundRival3 = n
				If c.id = g_editclubs_club.bteamofid Then foundBTeamOf = n
				n :+ 1
			End If
		Next
		g_editclubs_cmbRival1.SelectItem(foundRival1)
		g_editclubs_cmbRival2.SelectItem(foundRival2)
		g_editclubs_cmbRival3.SelectItem(foundRival3)
		g_editclubs_cmbBTeamOf.SelectItem(foundBTeamOf)
		n = 1
		TCompetition.SortListBy(1, 1)
		Local clubNation:TNation = TNation.SelectById(g_editclubs_club.nationid)
		For Local cp:TCompetition = EachIn g_competitions
			If cp.level = 0 And cp.locale = 0 And cp.comptype = 0 And cp.based = g_editclubs_club.nationid
				g_editclubs_cmbLeague.AddItem(cp.name, "BBBBBB", "FFFFFF", 0)
				If cp.id = g_editclubs_club.leagueid Then foundLeague = n
				n :+ 1
			End If
		Next
		g_editclubs_cmbLeague.SelectItem(foundLeague)
		n = 1
		For Local cp2:TCompetition = EachIn g_competitions
			If clubNation <> Null And cp2.level = 0 And cp2.locale = 1 And cp2.based = clubNation.continent
				g_editclubs_cmbContinentalComp.AddItem(cp2.name, "BBBBBB", "FFFFFF", 0)
				If cp2.id = g_editclubs_club.continentalcompid Then foundContinentalComp = n
				n :+ 1
			End If
		Next
		g_editclubs_cmbContinentalComp.SelectItem(foundContinentalComp)
		g_editclubs_btnId.SetText(String(g_editclubs_club.id), "", -1, -1)
		g_editclubs_ibName.SetText(g_editclubs_club.name, "", -1, -1)
		g_editclubs_ibShortName.SetText(g_editclubs_club.shortname, "", -1, -1)
		g_editclubs_ibTla.SetText(g_editclubs_club.tla, "", -1, -1)
		g_editclubs_ibNickName.SetText(g_editclubs_club.nickname, "", -1, -1)
		g_editclubs_ibStrength.SetText(String(g_editclubs_club.strength), "", -1, -1)
		g_editclubs_ibStadiumName.SetText(g_editclubs_club.stadiumname, "", -1, -1)
		g_editclubs_ibStadiumCapacity.SetText(String(g_editclubs_club.stadiumcapacity), "", -1, -1)
		g_editclubs_ibStadiumLong.SetText(FormatDecimals(g_editclubs_club.stadiumlongitude, 3), "", -1, -1)
		g_editclubs_ibStadiumLat.SetText(FormatDecimals(g_editclubs_club.stadiumlatitude, 3), "", -1, -1)
		RefreshKits()
		Return 0
	End Function

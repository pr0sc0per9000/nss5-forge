' GLOBAL RENAMED (2026-08-15): g_mediapath -> g_iconpath in THIS file only.
' 0x00C6F170 is the GameMedia/Images/Icons/ root. The corpus uses the identifier
' g_mediapath for TWO different slots -- 0x00C6F170 here and in 8 other files, and
' 0x00C6E950 (the install root) in 9 OTHERS. One name, two slots, an exact 9/9 split,
' so no single value assigned to g_mediapath could ever be right at every call site:
' whichever way it went, half the asset paths resolved wrong and ~100 images failed to
' load. Per-body verification cannot catch this -- a Global reaches the compiled code
' only as an absolute address and the byte oracle masks those, so both spellings
' verify byte-perfectly. Renaming is byte-neutral; scripts/reverify.py confirms it.
' See scripts/unify_globals.py for the rest of this defect class.
' TScreen_Stats.CreateScreen
' VA 0x0054D4EB   2150 bytes   vtable slot 0x30   sig ()i
' KIND=Function (static, no Self)
' byte-identical vs NSS5.exe (2150/2150, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=219). Verified with NSS5_NO_LEARN=1 (no in-run helper-name
' learning) -- this body only reaches already-named class-table slots, GetText, and
' LoadImageChecked, so nothing here depends on self-taught masking.
'
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS and the TYPE are load-bearing)
'   0x00C679A4 -> g_stats_scr:TScreen          (the screen object; slot 0x40 AddGadget)
'   0x00C679A8 -> g_stats_trophyimg:TImage      "Trophy14.png", icon for btn_History
'   0x00C679AC -> g_stats_shirtimg:TImage       "Shirt14.png", icon for btn_Stats
'   0x00C679B0 -> g_stats_panHistory:TPanel     "pan_History" (starts Hidden)
'   0x00C679B4 -> g_stats_btnHistory:TButton    "btn_History" (added to pan_Stats)
'   0x00C679B8 -> g_stats_tblHistory:TTable     "tbl_History" (= g_table in
'                 TScreen_Stats.UpdateHistoryTable.bmx)
'   0x00C679BC -> g_stats_panStats:TPanel       "pan_stats" (starts Shown)
'   0x00C679C0 -> g_stats_btnStats:TButton      "btn_Stats" (added to pan_History)
'   0x00C679C4 -> g_stats_tblStats:TTable       "tbl_Stats" (= g_stats_table in
'                 TScreen_Stats.UpdateStatTable.bmx)
'   0x00C679C8 -> g_stats_comboClub:TCombo      "cmb_Clubs" (= g_stats_comboclub /
'                 g_combo_club / g_stats_combo_club in three other already-recovered
'                 files for this Type -- the corpus is not internally consistent on
'                 naming for this address; ours is g_stats_comboClub)
'   0x00C679CC -> g_stats_comboYear:TCombo      "cmb_Years" (= g_stats_combo_season /
'                 g_combo_year elsewhere)
'   0x00C679D0 -> g_stats_panStatsInt:TPanel    "pan_statsint"
'   0x00C679D4 -> g_stats_tblStatsInt:TTable    "tbl_StatsInt" (= g_stats_totals in
'                 TScreen_Stats.UpdateStatTable.bmx)
'   0x00C679D8 -> g_stats_comboYearInt:TCombo   "cmb_YearsInt" (= g_stats_combo_comp /
'                 g_combo_level elsewhere)
'   0x00C66768 -> g_pan_stable:TPanel   0x00C667B0 -> g_pan_money:TPanel  (shared across
'                 many screens' CreateScreen bodies; names taken from those, e.g.
'                 TScreen_Achievements.CreateScreen.bmx)
'   0x00C6F170 -> g_iconpath:String    globals_final.tsv calls this Int ("dword int
'                 access") and is WRONG -- it is pushed straight into _bbStringConcat
'                 with the two icon filenames, no Int->String conversion. Same address
'                 and same correction already recorded in half a dozen other CreateScreen
'                 bodies (e.g. TEngine.SetUp.bmx calls it g_iconpath).
'   0x00C6E91C -> g_col_highlight:String   globals_final.tsv calls this Int too and is
'                 WRONG for the same reason -- pushed directly as AddColumn's colorB:$
'                 argument. Already corrected under this name in
'                 TScreen_Options.RefreshButtons.bmx / TScreen_Shop.SetUpScreen.bmx.
'
' Class-table slots used (all confirmed against vtable_map.tsv): TScreen+0x38
' CreateScreen, TScreen+0x40 AddGadget, TGadget+0x74 AddChild, TGadget+0x54 Hide,
' TPanel+0x88 CreatePanel, TTable+0x88 CreateTable, TTable+0x90 AddColumn,
' TCombo+0x88 CreateCombo, TButton+0x88 CreateButton, THelpBox+0x30 Create,
' TList+0x44 AddLast (Self.lHelp, TScreen field +0x1c). TScreen_Stats' own two
' callbacks (ComboClub, UpdateStatTable) and ButtonMyHistory/ButtonMyStats are written
' unprefixed as sibling Functions/callbacks (guide 3d).
'
' Shape notes:
'   Four Locals are forced by the prologue (sub esp,8 + push ebx/esi/edi) exactly like
'   TScreen_Achievements.CreateScreen's three: `Local x:Int=10`, `Local y:Int=70`,
'   `Local w:Int=542`, `Local colw:Int=104`. Reference counts (16.3/18.2): x is reused at
'   every panel/table x position, both statsint recomputation and cmb_YearsInt (~7 uses,
'   highest -> a register), y less often (~4 -> a register), w and colw fewer times each
'   (~3, ~5) -> both spill to the stack. The widget-chaining temp for the
'   create/retain-release/AddColumn dance is a SEPARATE compiler temp that always lands
'   in ebx (rule 18.1: anything live across the conditional _bbGCFree call starts at the
'   lowest free colour) -- it is not one of the four declared Locals.
'   `x :+ w + 10` (COMPOUND assign, not `x = x + w + 10`) is load-bearing for 2 bytes:
'   `:+` evaluates `w + 10` as one unit and adds it to x in place (`add edi,eax`, 8
'   bytes); `x = x + w + 10` parses left-associative and computes `(x+w)+10` from
'   scratch, discarding the in-place add (`add eax,edi` / `mov edi,eax`, 10 bytes).
'   `y = 70` right after IS a real reassignment in source (not dead code) -- the
'   original re-emits `mov esi,0x46` even though the value does not change.
'   `pan_statsint`'s width is the expression `colw + 123` (227), not the literal 227,
'   and its x/y are the just-updated `x`/`y` (562, 70); h stays literal (30).
'   `cmb_YearsInt`'s x is the expression `x + 5` (567), not the literal 567. Every other
'   numeric literal
'   (cmb_Clubs/cmb_Years/cmb_YearsInt's x/y/w/h, all CreateButton geometry, all panel/
'   table constants) is pushed as a bare immediate in the original -- confirmed by
'   reading the raw disassembly end to end, not assumed from the decompile.
'   The two CreateButton x/y values are `Int(g_stats_panStats.x + g_stats_panStats.w -
'   105.0)` / `Int(g_stats_panStats.y + 5.0)` -- TGadget fields (+0x20 x, +0x24 y, +0x2c
'   w), read from BOTH buttons even though btnStats ends up a child of pan_History.
'   `If Not g_stats_trophyimg` is the 21-byte null-test form (setne/movzx), not
'   `If x = Null` (12 bytes) -- confirmed against the original's `cmp eax,<null>` /
'   `setne al` sequence.
'   All 35 string literals were read out of NSS5.exe with harness.read_string() and
'   checked individually against the body's own SYM table: exact, including case.
'!Global g_stats_scr:TScreen
'!Global g_stats_trophyimg:TImage
'!Global g_stats_shirtimg:TImage
'!Global g_stats_panHistory:TPanel
'!Global g_stats_btnHistory:TButton
'!Global g_stats_tblHistory:TTable
'!Global g_stats_panStats:TPanel
'!Global g_stats_btnStats:TButton
'!Global g_stats_tblStats:TTable
'!Global g_stats_comboClub:TCombo
'!Global g_stats_comboYear:TCombo
'!Global g_stats_panStatsInt:TPanel
'!Global g_stats_tblStatsInt:TTable
'!Global g_stats_comboYearInt:TCombo
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_iconpath:String
'!Global g_col_highlight:String
Function CreateScreen:Int()
	g_stats_scr = TScreen.CreateScreen("stats", Null, Null, Null)
	If Not g_stats_trophyimg
		g_stats_trophyimg = LoadImageChecked(g_iconpath + "Trophy14.png", -1)
		g_stats_shirtimg = LoadImageChecked(g_iconpath + "Shirt14.png", -1)
	EndIf
	g_stats_scr.AddGadget(g_pan_stable)
	g_stats_scr.AddGadget(g_pan_money)

	Local x:Int = 10
	Local y:Int = 70
	Local w:Int = 542
	Local colw:Int = 104

	g_stats_panStats = TPanel.CreatePanel("pan_stats", "", x, y, w, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 0)
	g_stats_panHistory = TPanel.CreatePanel("pan_History", "", x, y, w, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 0)
	g_stats_scr.AddGadget(g_stats_panStats)
	g_stats_scr.AddGadget(g_stats_panHistory)

	g_stats_tblStats = TTable.CreateTable("tbl_Stats", x, 100, 20, 0, 0, 2, "00FF00", 1.0, 1, Null)
	g_stats_tblStats.AddColumn(122, GetText("Club Stats"), "000000", "FFFFFF", 2)
	g_stats_tblStats.AddColumn(colw, GetText("League"), "000000", "EEEEEE", 1)
	g_stats_tblStats.AddColumn(colw, GetText("Cup"), "000000", "DDDDDD", 1)
	g_stats_tblStats.AddColumn(colw, GetText("Continent"), "000000", "EEEEEE", 1)
	g_stats_tblStats.AddColumn(colw, GetText("Season"), "000000", g_col_highlight, 1)
	g_stats_panStats.AddChild(g_stats_tblStats)

	g_stats_tblHistory = TTable.CreateTable("tbl_History", x, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_stats_tblHistory.AddColumn(120, GetText("Team"), "000000", "EEEEEE", 1)
	g_stats_tblHistory.AddColumn(60, GetText("Year"), "000000", "DDDDDD", 1)
	g_stats_tblHistory.AddColumn(361, GetText("Tournament"), "000000", "EEEEEE", 0)
	g_stats_panHistory.AddChild(g_stats_tblHistory)

	g_stats_comboClub = TCombo.CreateCombo("cmb_Clubs", GetText("All Clubs"), 15, 75, 180, 20, 1, 2, "888888", "FFFFFF", 1.0, ComboClub, 1)
	g_stats_comboYear = TCombo.CreateCombo("cmb_Years", GetText("All Time"), 200, 75, 80, 20, 1, 2, "888888", "FFFFFF", 1.0, UpdateStatTable, 1)
	g_stats_panStats.AddChild(g_stats_comboClub)
	g_stats_panStats.AddChild(g_stats_comboYear)

	g_stats_btnHistory = TButton.CreateButton("btn_History", GetText("My History"), Int(g_stats_panStats.x + g_stats_panStats.w - 105.0), Int(g_stats_panStats.y + 5.0), 100, 20, 1, 2, "FFFFFF", "FFFFFF", g_stats_trophyimg, ButtonMyHistory, 1.0, 1, "")
	g_stats_panStats.AddChild(g_stats_btnHistory)

	g_stats_btnStats = TButton.CreateButton("btn_Stats", GetText("My Stats"), Int(g_stats_panStats.x + g_stats_panStats.w - 105.0), Int(g_stats_panStats.y + 5.0), 100, 20, 1, 2, "FFFFFF", "FFFFFF", g_stats_shirtimg, ButtonMyStats, 1.0, 1, "")
	g_stats_panHistory.AddChild(g_stats_btnStats)
	g_stats_panHistory.Hide()

	x :+ w + 10
	y = 70

	g_stats_panStatsInt = TPanel.CreatePanel("pan_statsint", "", x, y, colw + 123, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 0)
	g_stats_scr.AddGadget(g_stats_panStatsInt)

	g_stats_tblStatsInt = TTable.CreateTable("tbl_StatsInt", x, 100, 20, 0, 0, 2, "00FF00", 1.0, 1, Null)
	g_stats_tblStatsInt.AddColumn(122, GetText("International Stats"), "000000", "FFFFFF", 2)
	g_stats_tblStatsInt.AddColumn(colw, GetText("tla_International"), "000000", g_col_highlight, 1)
	g_stats_panStatsInt.AddChild(g_stats_tblStatsInt)

	g_stats_comboYearInt = TCombo.CreateCombo("cmb_YearsInt", GetText("All Time"), x + 5, 75, 80, 20, 1, 2, "888888", "FFFFFF", 1.0, UpdateStatTable, 1)
	g_stats_panStatsInt.AddChild(g_stats_comboYearInt)

	g_stats_scr.lHelp.AddLast(THelpBox.Create(g_stats_comboYear, 0, 0, 0, 0, GetText("CHELP_STATFILTERS"), 1, 2))
End Function

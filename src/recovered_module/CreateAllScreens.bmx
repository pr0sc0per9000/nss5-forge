' CreateAllScreens  -- module-level Function (no Type)
' VA 0x0051B986   595 bytes   sig ()i
' byte-identical vs NSS5.exe (595/595, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=85, verified with NSS5_NO_LEARN=1 -- codegen-patterns 13.1)
'
' NAME IS OURS. Module-level Functions carry no BBDebugScope record, so the original name
' is unrecoverable. Called once, from TScreen.ResetScreens (VA 0x00510A05) right after
' TScreen.ClearAll -- this is the function that actually builds every screen in the game
' (53 distinct TScreen_X.CreateScreen() calls plus one TPanel_Controls.SetUp()), gated
' behind a progress bar so the multi-second construction shows feedback.
'
' EVERY `call dword ptr [addr]` in this body is a static cross-Type Function call
' resolved by finding which Type's class table the address falls inside
' (extracted/class_tables.tsv gives the table base, extracted/vtable_map.tsv gives the
' slot's name) -- this is the SAME construct as GameMain's boot-sequence calls documented
' in docs/game/engine/main-loop.md as "the open question": `TFoo.Bar()`, a plain static
' call to a Function declared on another Type, compiles to an indirect call through that
' Type's class table rather than E8, exactly like codegen-patterns.md 3d's same-Type case
' -- the open part was whether it also holds for a DIFFERENT Type's table. That question is
' now closed by this body's MATCH: writing ordinary `TScreen_Language.CreateScreen()`
' syntax reproduces `call dword ptr [0x00C63980]` byte for byte once the class-table slot
' resolves (masked per codegen-patterns.md section 1's second row). Every one of the 53
' CreateScreen calls and the one TPanel_Controls.SetUp() call were identified this way,
' cross-checked against class_tables.tsv + vtable_map.tsv, not guessed from name similarity.
'
' The five `TScreen.DoProgressBar(...)` calls (class-table slot 0xAC) are the SAME
' construct too, and mask on slot identity alone -- they verify here regardless of
' DoProgressBar's own body, which remains UNVERIFIED in src/recovered_unverified/ (see
' that file). A masked classtable-slot call never depends on the callee's own bytes being
' right (codegen-patterns.md section 1, row 2), only on both sides resolving to the same
' Type+slot, so this is not rule-13.3 stubbing -- DoProgressBar is not stood in for here,
' it is called for real, through the real static-dispatch mechanism, body-content-agnostic.
' The floats are literal progress percentages: 60.0, 70.0, 80.0, 90.0, 100.0, one per batch
' of screens created. "00FF00" (0x00C6E904) is the progress-bar colour. GetText("Loading")
' (the literal at 0x00C73AA4) supplies the localized label text, same value every call.
'
' The opening and closing statements are a matched pair, identified by literal string
' content (harness.read_string): "CreateScreensAll:" at 0x00C7E400 and "ScreensAllCreated:"
' at 0x00C7E430 -- a start/end log-line bracket around the whole batch, each logging a
' GC-collected memory snapshot formatted through the ALREADY-VERIFIED FormatMoney
' (0x0050720B) -- confirmed by identifying 0x004A8550 as the BlitzMax builtin
' GCMemAlloced() (`Function GCMemAlloced()="bbGCMemAlloced"`, tools/blitzmax-legacy-src/
' mod/brl.mod/blitz.mod/blitz.bmx:353), the same builtin already named in
' TEngine.RenderGameEngine's "Mem: " + String(GCMemAlloced()) debug line. Push-order
' analysis (codegen-patterns.md 16.2's rule generalised to `+`: the RIGHT operand is
' evaluated/pushed first, the LEFT operand -- here a bare literal -- is pushed last, right
' before the call) fixes the concatenation as literal-then-value, not value-then-literal:
' `"CreateScreensAll:" + FormatMoney(GCMemAlloced(), 0)`.
	Function CreateAllScreens:Int()
		GCCollect()
		LogLine("CreateScreensAll:" + FormatMoney(GCMemAlloced(), 0))
		TScreen_Language.CreateScreen()
		TScreen_MainMenu.CreateScreen()
		TScreen_Options.CreateScreen()
		TScreen_Controls.CreateScreen()
		TScreen_NewPlayer.CreateScreen()
		TScreen.DoProgressBar(60.0, GetText("Loading"), "00FF00", 0)
		TScreen_Difficulty.CreateScreen()
		TScreen_EditMenu.CreateScreen()
		TScreen_EditContinents.CreateScreen()
		TScreen_EditNations.CreateScreen()
		TScreen_Clubs.CreateScreen()
		TScreen_EditClubs.CreateScreen()
		TScreen_EditKits.CreateScreen()
		TScreen_Competitions.CreateScreen()
		TScreen_EditCompetition.CreateScreen()
		TScreen_Promotions.CreateScreen()
		TScreen_ContinentalComps.CreateScreen()
		TScreen_Calendar.CreateScreen()
		TScreen.DoProgressBar(70.0, GetText("Loading"), "00FF00", 0)
		TScreen_TestMenu.CreateScreen()
		TScreen_TestFixtures.CreateScreen()
		TScreen_TestTournaments.CreateScreen()
		TScreen_GameMenu.CreateScreen()
		TScreen_Shop.CreateScreen()
		TScreen_BootShop.CreateScreen()
		TScreen_ContractOffer.CreateScreen()
		TScreen_MyContract.CreateScreen()
		TScreen_Home.CreateScreen()
		TScreen_Stats.CreateScreen()
		TScreen_Finances.CreateScreen()
		TScreen_Abilities.CreateScreen()
		TScreen.DoProgressBar(80.0, GetText("Loading"), "00FF00", 0)
		TScreen_Relationships.CreateScreen()
		TScreen_Leagues.CreateScreen()
		TScreen_Continents.CreateScreen()
		TScreen_WorldMap.CreateScreen()
		TScreen_MatchPrep.CreateScreen()
		TScreen_Dilemma.CreateScreen()
		TScreen_Newspaper.CreateScreen()
		TScreen_Achievements.CreateScreen()
		TScreen.DoProgressBar(90.0, GetText("Loading"), "00FF00", 0)
		TScreen_SeasonReview.CreateScreen()
		TScreen_WebPage.CreateScreen()
		TScreen_ReportPhysio.CreateScreen()
		TScreen_ReportBoss.CreateScreen()
		TScreen_Casino.CreateScreen()
		TScreen_BlackJack.CreateScreen()
		TScreen_Roulette.CreateScreen()
		TScreen_Slots.CreateScreen()
		TScreen_Pairs.CreateScreen()
		TScreen_Negotiate.CreateScreen()
		TScreen_Interview.CreateScreen()
		TScreen_Stable.CreateScreen()
		TScreen_Kits.CreateScreen()
		TScreen_Formation.CreateScreen()
		TScreen_MatchPaused.CreateScreen()
		TScreen.DoProgressBar(100.0, GetText("Loading"), "00FF00", 0)
		TPanel_Controls.SetUp()
		GCCollect()
		LogLine("ScreensAllCreated:" + FormatMoney(GCMemAlloced(), 0))
	End Function

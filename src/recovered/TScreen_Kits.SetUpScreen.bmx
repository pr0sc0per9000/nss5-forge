' TScreen_Kits.SetUpScreen -- byte-identical vs NSS5.exe
' VA 0x0054989D   1260 bytes (Ghidra-authoritative)   vtable slot 0x34
' KIND=Function (:TFixture,()i,()i)i
'
' VERIFIED 2026-08-23, three checks, NSS5_NO_LEARN=1 in the environment for all three:
'   1. PER-FUNCTION ORACLE. harness.try_method("TScreen_Kits","SetUpScreen", body) ->
'      status=MATCH mode=reloc matched=1260 total=1260 reloc_masked=105
'      orig_len=1260 our_len=1260 orig_len_from=ghidra orig_va=0x0054989D.
'   2. COMPOSITION, which is what the previous header asked for and did not have.
'      scripts/assemble.py rebuilt src/assembled/nss5_assembled.exe in an isolated
'      worktree, then scripts/check_assembled.py's comparator (harness.compare, the
'      assembled-side symbol tables, learn=None) over this VA:
'          identical modulo reloc : 1     DIVERGED after assembly : 0
'      i.e. the body survives the whole-program facts -- vtable slot order, Global
'      types, Type declaration order -- unchanged. check_assembled.py's own target
'      list is drawn from coverage.load_recovered(), which scans src/recovered* only,
'      so this VA had to be fed in explicitly; the comparator and its inputs are
'      otherwise untouched.
'   3. LITERAL CONTENT, which a byte MATCH does NOT certify (the oracle masks the
'      BBString address a literal reaches the code as -- the kit-style names "STRIPES",
'      "SPLIT", "DIAGONALSPLIT", "SEGMENTS", "CHEQUERED" are exactly the kind of thing
'      that would compare equal while being wrong). scripts/check_literals.py --files
'      <this file> -> OK, 0 mismatches, against the exe's own decoded BBStrings.
'
'   mode=reloc, not exact, is the expected verdict: our image links at different
'   addresses than NSS5.exe, so every Global/string/class-table operand is a
'   relocation. Every non-relocation byte agrees.
'
' PROMOTED to src/recovered/ in this pass. Promotion moves the body's position in the
' emitted source, and Type declaration order is a whole-program property, so it was
' re-verified AFTER the move, not before: assemble.py rebuilt, then check_assembled.py
' over this VA (identical modulo reloc, 0 diverged) and over its own standard 80-body
' sample (9 exact / 71 reloc / 0 diverged / 0 unlocatable).
'
' CAVEAT THAT THE ORACLE CANNOT COVER (docs/specs/21-module-globals.md 8.1): relocation
' masking means a Global reference compares equal whatever slot it names. A MATCH here
' is a proof about the emitted code, not about which slot each name resolves to.
'
' HOW THE BODY GOT HERE (earlier pass, retained for the reasoning trail):
' localise_diff.py (scripts/localise_diff.py, run against a private probe build so no
' shared state was touched) isolated the ENTIRE -32 byte delta to three real shape
' defects, not to an unfixable register quirk as the previous pass's header concluded:
'
'   1. `a0.level` was compared with If/ElseIf (`If a0.level = 0 ... ElseIf a0.level = 1`).
'      The original's disassembly loads level into a register ONCE
'      (`mov eax,[esi+0x3c]`) and does two back-to-back `cmp`/`je` tests falling through
'      to "neither matched" -- the textbook bcc Select shape (guide/codegen-patterns.md
'      section on If/ElseIf vs Select: "a Select loads the subject once and emits
'      back-to-back compares"). Fixed: `Select a0.level / Case 0 ... / Case 1 ... /
'      End Select` (no Default -- falling through with neither case handled is the
'      original's own behaviour, not a bug introduced here).
'
'   2. GetHomeTeamId()/GetAwayTeamId() are called on `g_kits_fixture` (the Global), NOT
'      on `a0`, for BOTH the home and the away call, in BOTH the club and nation
'      branches. The previous pass's header asserted an "asymmetry" (first call reads
'      a0, second reads the Global) based on Ghidra's decompile text -- but the RAW
'      disassembly reloads from the fixed address 0xc674d0 at every one of the four
'      call sites (0x54990E, 0x5499B9, and their away-id siblings), even though `a0`
'      (esi) is still live and unspilled at that point. Ghidra's decompiler had
'      copy-propagated `PTR_DAT_00c674d0 == param_1` and simply chose to print the
'      shorter name; the machine code it was printed from is not what it says. Fixed:
'      every GetHomeTeamId()/GetAwayTeamId() call now reads `g_kits_fixture`.
'
'   3. The 5-way kit-style dispatch (STRIPES/SPLIT/DIAGONALSPLIT/SEGMENTS/CHEQUERED,
'      each testing shirt1 AND shirt2, falling back to a shirt1-ONLY test when none
'      match) was an If/ElseIf/.../Else chain. The original lays out five back-to-back
'      String-equality tests against ONE register load of `home.kitcolsHome.style`,
'      followed IMMEDIATELY by the fallback (shirt1-only) body inline, THEN -- after
'      that inline fallback's own `jmp` to the shared exit -- the five per-style
'      bodies one after another, each ending in its own `jmp` to the same exit. That is
'      exactly the Select layout TBall.Kick.bmx's header already documents ("bcc lays
'      out Select as [compares] + [Default body inline] + [the other Cases' bodies
'      afterward, each jmp back to the shared exit]"), just with a String subject
'      instead of an Int one. Fixed: `Select g_kits_home.kitcolsHome.style / Case
'      "STRIPES" ... / Case "SPLIT" ... / Case "DIAGONALSPLIT" ... / Case "SEGMENTS"
'      ... / Case "CHEQUERED" ... / Default ... / End Select`. The intermediate
'      `Local s1:String = ...` is gone too -- Select evaluates its subject expression
'      exactly once into its own implicit temp (see TBall.Kick.bmx's bare
'      `Select Rand(2)`), so a separate Local was never needed.
'
' EMERGENT, NOT SEPARATELY FIXED: the previous pass's header treated the parameter
' register mismatch (original esi=a0/ebx=a1/edi=a2, prior body's edi=a0/esi=a1/ebx=a2)
' as the root cause and spent most of its effort on it directly, without success.
' Correcting the three shape defects above collapses a0's reference count from ~9
' textual uses down to 2 (the initial `g_kits_fixture = a0` store and the `Select
' a0.level` subject) -- every other "use" was never really a use of a0 at all, it was
' a mis-transcribed use of g_kits_fixture. With that reference count restored to what
' the original's register allocator actually saw, bcc's graph colourer independently
' picked esi/ebx/edi for a0/a1/a2 in the same order as the original, with no direct
' intervention on the prologue. This matches codegen-patterns.md's standing warning
' not to chase register identity by hand -- fix the reference counts the allocator is
' actually reacting to, and let it choose.
'
' RESOLVED (high confidence, reusable -- semantics are FULLY understood):
'   Signature params: a0:TFixture, a1:Int() (an "OK" callback), a2:Int() (a "cancel"
'   callback) -- SIG is (:TFixture,()i,()i)i so both a1/a2 are function-pointer typed
'   `Int()`, per blitzmax-language-guide.md section 10.1.
'   Fields used (all confirmed against object_model.json):
'     TFixture: level @0x3c (=field 15*4), matches param_1[0xf] in the decompile.
'     TBase_Team (super of TClub/TNation): id@0xc, labelname@0x1c, kitcolsHome@0x44.
'     TKitStrings (kitcolsHome's type): style@8($), shirt1@0xc($), shirt2@0x10($).
'     TProfile (the module Global at 0x00C6F028, named g_profile per
'       extracted/globals_type_overrides.tsv -- NOT the stale g_contractoffer_tplayer/
'       TPlayer guess in globals_named.tsv, see globals_corrections.tsv): nationid@0x1c,
'       clubid@0x20.
'   Slots resolved via class_tables.tsv (classtable_va + slot -> Type.Function/Method):
'     0x00c59e0c = TClub slot 0x60      -> TClub.SelectById(i):TClub
'     0x00c59a20 = TNation slot 0x58    -> TNation.SelectById(i):TNation
'     0x00c67634 = TScreen_Kits slot 0x38 -> ButtonChangeKits()  (bare call, same Type)
'     0x00c67638 = TScreen_Kits slot 0x3c -> RefreshKits()        (bare call, same Type)
'     0x00c61c88 = TScreen slot 0x5c    -> TScreen.SetActive($,$):TScreen
'     TGadget slot 0x58 = Show(); TGadget slot 0x64 = SetText($,$,i,i)i (both confirmed
'       in earlier passes, see TScreen_Leagues.ComboClub.bmx header).
'   String literals (harness.read_string): 0xc756ac "STRIPES", 0xc75848 "SPLIT",
'     0xc84b14 "DIAGONALSPLIT", 0xc758d4 "SEGMENTS", 0xc758f0 "CHEQUERED", 0xc88798 "kits",
'     0xc81674 "btn_play". 0xc5d284 does not decode as a BBString (read_string -> None);
'     the call site pattern (push const; ...; SetText(name, CONST, -1, -1)) matches every
'     other SetText(...,"",...) call in the corpus, so treat it as the "" literal until
'     proven otherwise.
'   Behaviour: shows the kit-comparison screen for one fixture. Stores the fixture and two
'   UI callbacks into Globals; determines home/away team objects by SelectById through
'   TClub (level=0, club fixture) or TNation (level=1, international fixture) -- home/away
'   left Null if level is neither 0 nor 1 (ORIGINAL BUG candidate: no else/Default branch,
'   not "fixed"); flags whether either side is the player's own club/nation (g_profile
'   .clubid / .nationid); sets the two team-name labels; seeds two Rand(5,1)-shaped ints;
'   calls RefreshKits() and TScreen.SetActive("kits","btn_play"); then runs a 5-way String
'   Select on home.kitcolsHome.style ("STRIPES"/"SPLIT"/"DIAGONALSPLIT"/"SEGMENTS"/
'   "CHEQUERED", each testing shirt1 AND shirt2 clash against away's kit, Default falling
'   back to a shirt1-ONLY check) and calls ButtonChangeKits() if the shirt colours clash --
'   i.e. an "avoid identical kit colours" auto-swap.
'   FUN_0059f089(a,b) (called twice as (5,1)): BlitzMax's own builtin Rand(low,high).

	'!Global g_kits_panel:TGadget
	'!Global g_kits_fixture:TFixture
	'!Global g_kits_okfunc:Int()
	'!Global g_kits_cancelfunc:Int()
	'!Global g_kits_home:TBase_Team
	'!Global g_kits_away:TBase_Team
	'!Global g_kits_showhome:Int
	'!Global g_kits_showaway:Int
	'!Global g_kits_label1:TGadget
	'!Global g_kits_label2:TGadget
	'!Global g_kits_int1:Int
	'!Global g_kits_int2:Int
	'!Global g_kits_int3:Int
	'!Global g_profile:TProfile
	g_kits_panel.Show()
	g_kits_okfunc = a1
	g_kits_cancelfunc = a2
	g_kits_fixture = a0
	g_kits_showhome = 0
	g_kits_showaway = 0
	Select a0.level
		Case 0
			g_kits_home = TClub.SelectById(g_kits_fixture.GetHomeTeamId())
			g_kits_away = TClub.SelectById(g_kits_fixture.GetAwayTeamId())
			If g_kits_home.id = g_profile.clubid Then g_kits_showhome = 1
			If g_kits_away.id = g_profile.clubid Then g_kits_showaway = 1
		Case 1
			g_kits_home = TNation.SelectById(g_kits_fixture.GetHomeTeamId())
			g_kits_away = TNation.SelectById(g_kits_fixture.GetAwayTeamId())
			If g_kits_home.id = g_profile.nationid Then g_kits_showhome = 1
			If g_kits_away.id = g_profile.nationid Then g_kits_showaway = 1
	End Select
	g_kits_label1.SetText(g_kits_home.labelname, "", -1, -1)
	g_kits_label2.SetText(g_kits_away.labelname, "", -1, -1)
	g_kits_int1 = 0
	g_kits_int2 = Rand(5, 1)
	g_kits_int3 = Rand(5, 1)
	RefreshKits()
	TScreen.SetActive("kits", "btn_play")
	Select g_kits_home.kitcolsHome.style
		Case "STRIPES"
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1 And g_kits_home.kitcolsHome.shirt2 = g_kits_away.kitcolsHome.shirt2
				ButtonChangeKits()
			End If
		Case "SPLIT"
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1 And g_kits_home.kitcolsHome.shirt2 = g_kits_away.kitcolsHome.shirt2
				ButtonChangeKits()
			End If
		Case "DIAGONALSPLIT"
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1 And g_kits_home.kitcolsHome.shirt2 = g_kits_away.kitcolsHome.shirt2
				ButtonChangeKits()
			End If
		Case "SEGMENTS"
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1 And g_kits_home.kitcolsHome.shirt2 = g_kits_away.kitcolsHome.shirt2
				ButtonChangeKits()
			End If
		Case "CHEQUERED"
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1 And g_kits_home.kitcolsHome.shirt2 = g_kits_away.kitcolsHome.shirt2
				ButtonChangeKits()
			End If
		Default
			If g_kits_home.kitcolsHome.shirt1 = g_kits_away.kitcolsHome.shirt1
				ButtonChangeKits()
			End If
	End Select
	Return 0

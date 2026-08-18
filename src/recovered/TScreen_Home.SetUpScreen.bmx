' TScreen_Home.SetUpScreen
' VA 0x0053CAE2   848 bytes   mode=reloc   byte-identical vs NSS5.exe
' (848/848, original length from Ghidra's inventory, reloc_masked=56; verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x34
'
' This is the between-matches hub: every "return to menu" flow in the game lands here.
' It switches the active screen to "home", starts the menu music, refreshes the club/
' rating/value labels for whichever club the player is at (handling an out-on-loan
' player specially), and refreshes the five progress bars (fame/happiness/skills/
' lifestyle/achievements) and their colours from the player's current stats.
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug
'   record). 0x00C6F028 is typed TProfile by construction-site + field/slot evidence in
'   globals_corrections.tsv (NOT TPlayer, an earlier unsound guess); the name g_profile
'   is the one already used by every sibling screen (TScreen_Stats/Finances/Achievements
'   .SetUpScreen etc.) that references the same address.
'     0x00C6F028 -> g_profile:TProfile
'     0x00C66958 -> g_lbl_teamcurrent1:TLabel   (TScreen_Home.CreateScreen's Global map)
'     0x00C6695C -> g_lbl_teamcurrent2:TLabel
'     0x00C66964 -> g_lbl_rating2:TLabel        (note: 0x00C66960 = lbl_rating1, the
'                    static "Rating" caption set once at CreateScreen, is NOT touched here)
'     0x00C6696C -> g_lbl_value2:TLabel         (0x00C66968 = lbl_value1, likewise untouched)
'     0x00C66970 -> g_prg_fame:TProgressBar
'     0x00C66984 -> g_prg_happiness:TProgressBar
'     0x00C66990 -> g_prg_skills:TProgressBar
'     0x00C6699C -> g_prg_lifestyle:TProgressBar
'     0x00C669A8 -> g_prg_achievements:TProgressBar
'   TProfile field offsets (extracted/object_model.json): date +0x10 (:TMyDate),
'   onloanfrom +0x148 (Int), myclub +0x1D0 (:TClub). TClub extends TBase_Team: id +0xC,
'   labelname +0x1C are inherited TBase_Team fields; nationid +0x64, leagueid +0x68 are
'   TClub's own (also used by TProfile.RandomIncident.bmx, same offsets).
'   Class-table slots resolved via vtable_map.tsv:
'     TProfile+0x150 CheckAchievement(i)i     TProfile+0xF8  GetFame()f
'     TProfile+0xC4  GetHappiness()i          TProfile+0xA4  GetSkillRating()i
'     TProfile+0xF4  GetLifestyle()i          TProfile+0x14C GetAchievements()i
'     TProfile+0xB8  GetValue()i              TProfile+0x8C  GetStringStat(i,i,i,i,i)$
'     TMyDate+0x54   GetYear()i               TBase_Team+0x3C GetPrimaryColour()$
'     (TClub does not override GetPrimaryColour(); the call dispatches through the
'      inherited TBase_Team slot -- confirmed against class_tables.tsv/vtable_map.tsv,
'      TClub's own slots start again only at 0x44 Destroy.)
'     TGadget+0x6C   SetColour($,$)i          TGadget+0x64   SetText($,$,i,i)i
'     TProgressBar+0x8C SetPercent(f,i)i
'     0x00C61C88 = TScreen+0x5C SetActive($,$):TScreen (called TScreen.SetActive(...),
'       no receiver object -- same static-classtable-slot pattern already established
'       for every other SetUpScreen in this project, e.g. TScreen_GameMenu.SetUpScreen).
'     TNation+0x58 SelectById(i):TNation, TCompetition+0x4C SelectById(i):TCompetition,
'       TClub+0x60 SelectById(i):TClub -- all called through their own Type (no receiver).
'   E8 targets: 0x004BCB98 PlayTrack, 0x004A7C20 bbStringConcat (the "+" on
'   comp.GetStringTeamPosition(club.id) + " " + comp.name), 0x0050720B FormatMoney,
'   0x00507DC1 ColourGreen (module Functions, already recovered).
'   String literals read with harness.read_string: 0x00C5D284 "" (used repeatedly, one of
'   the two zero-length BBString constants bcc picks between depending on argument slot),
'   0x00C85D00 "home", 0x00C5D680 "FFFFFF", 0x00C6EF28 " ".
'
' NOTES ON SHAPE
'   * `TNation.SelectById(club.nationid)` is a genuine standalone statement whose return
'     value is thrown away -- confirmed by disassembly: eax is clobbered by the very next
'     push before ever being stored anywhere. (TCompetition.SelectById right after it
'     DOES have its result kept, in a Local.) Reproduce the dead call; do not drop it.
'   * `If g_profile.myclub <> Null` wraps club/competition/year lookup AND all four of the
'     top labels (teamcurrent1/2, rating2, value2) -- the whole block is skipped, and the
'     five progress bars below still run, when the player currently has no club (e.g. a
'     free pass). This is the `If cond Then <block>` (no Else) shape: the original tests
'     `myclub = Null` and jumps PAST the block when true (section 10.3's 16-byte long form,
'     using the 32-bit immediate since the branch target is far).
'   * `If g_profile.onloanfrom Then club = TClub.SelectById(...)` is a single-branch guard
'     (no Else) reassigning `club` from `g_profile.myclub` to the loan club.
'   * Each of the five progress-bar blocks needs its Int stat value coerced to Float for
'     SetPercent(f,i)i. `GetFame()f` already returns a Float and feeds SetPercent directly;
'     the other four return Int and the coercion forces a store-then-FILD through the
'     function's one spare stack slot ([ebp-8], reused independently by each of the four --
'     x86's FILD has no register form) -- an ordinary compiler expression temporary, not a
'     declared source Local.
'   * The two SetColour call sites pass their arguments in OPPOSITE order from each other:
'     `g_lbl_teamcurrent1.SetColour(club.GetPrimaryColour(), "FFFFFF")` (computed colour
'     first, literal second) but `g_prg_happiness.SetColour("", ColourGreen(...))` (literal
'     first, computed colour second) -- and likewise for skills/lifestyle/achievements.
'     This is genuinely a different argument order at each call site, not a single rule:
'     bcc pushes arguments right-to-left, so the LAST-pushed explicit argument (the one
'     immediately before Self) is always the FIRST parameter in source, and that lands on
'     "FFFFFF" for the label but on the ColourGreen(...) call for the progress bars.
'     Getting this backwards on the progress-bar calls cost exactly one extra `push ""`
'     appearing too early relative to the original (byte 510 of 848) -- diagnostic of a
'     swapped argument order in a 2-arg call, not a missing statement.
'!Global g_profile:TProfile
'!Global g_lbl_teamcurrent1:TLabel
'!Global g_lbl_teamcurrent2:TLabel
'!Global g_lbl_rating2:TLabel
'!Global g_lbl_value2:TLabel
'!Global g_prg_fame:TProgressBar
'!Global g_prg_happiness:TProgressBar
'!Global g_prg_skills:TProgressBar
'!Global g_prg_lifestyle:TProgressBar
'!Global g_prg_achievements:TProgressBar
	Function SetUpScreen:Int()
		TScreen.SetActive("home", "")
		PlayTrack(2)
		g_profile.CheckAchievement(80)
		If g_profile.myclub <> Null
			Local club:TClub = g_profile.myclub
			If g_profile.onloanfrom Then club = TClub.SelectById(g_profile.onloanfrom)
			TNation.SelectById(club.nationid)
			Local comp:TCompetition = TCompetition.SelectById(club.leagueid)
			Local yr:Int = g_profile.date.GetYear() - 1
			g_lbl_teamcurrent1.SetColour(club.GetPrimaryColour(), "FFFFFF")
			g_lbl_teamcurrent1.SetText(club.labelname, "", -1, -1)
			g_lbl_teamcurrent2.SetText(comp.GetStringTeamPosition(club.id) + " " + comp.name, "", -1, -1)
			g_lbl_rating2.SetText(g_profile.GetStringStat(18, 3, club.id, yr, 1), "", -1, -1)
			g_lbl_value2.SetText(FormatMoney(g_profile.GetValue(), 1), "", -1, -1)
		End If
		g_prg_fame.SetPercent(g_profile.GetFame(), 1)
		g_prg_happiness.SetPercent(g_profile.GetHappiness(), 1)
		g_prg_happiness.SetColour("", ColourGreen(g_profile.GetHappiness()))
		g_prg_skills.SetPercent(g_profile.GetSkillRating(), 1)
		g_prg_skills.SetColour("", ColourGreen(g_profile.GetSkillRating()))
		g_prg_lifestyle.SetPercent(g_profile.GetLifestyle(), 1)
		g_prg_lifestyle.SetColour("", ColourGreen(g_profile.GetLifestyle()))
		g_prg_achievements.SetPercent(g_profile.GetAchievements(), 1)
		g_prg_achievements.SetColour("", ColourGreen(g_profile.GetAchievements()))
	End Function

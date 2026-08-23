' TEngine.SetUpMatch
' VA 0x004CE7BE   1776 bytes   mode=reloc   byte-identical vs NSS5.exe (matched 1776/1776)
' CORRECTED 2026-08-22: DebugLog(...) -> LogLine(...) at all 3 call sites.
' MATCH 1776/1776, first_diff=None, NSS5_NO_LEARN=1, reproduced on two worker trees.
' Before: MISMATCH, mode=diff, 1776/1776 LENGTH-EXACT, first_diff=+15.
'
' +15 is the OPERAND of `E8` at 0x004CE7CC, whose target is 0x00505B91. That address is
' this corpus's own LogLine (src/recovered_module/LogLine.bmx states VA 0x00505b91,
' 58 bytes, sig ($)i) and 213 other files call it. `DebugLog` is not a recovered function
' at all -- it has no body anywhere under src/, and this file was the ONLY one naming it.
' It is BlitzMax's own built-in, so the body compiled and was length-exact while calling a
' different function from the original's.
'
' Why the byte oracle caught it and localise_diff did not: localise_diff reported
' "CLEAN -- byte-identical modulo the oracle's masks" throughout, because a call operand is
' inside its mask set. Only harness.try_method's by-name check compares WHICH function the
' operand targets. A length-exact body calling the wrong function is invisible to every
' check except that one -- which is the argument for NSS5_NO_LEARN=1 on every audit, since
' with learning on this body would teach the table that 0x00505B91 is DebugLog and
' self-certify (codegen-patterns.md 15.5).
'
' Ruled out before changing anything: the file is byte-identical to git HEAD, so it was not
' edited after being banked.
' KIND=Function (STATIC method on TEngine), SIG (:TFixture,:TTeam,:TTeam,()i)i, class-table slot 0x3c
' harness.try_method: status=MATCH, mode=reloc, 1776/1776,
' learned_helpers=['0x00505b91=_brl_blitz_DebugLog'] (ordinary in-run learning --
' codegen-patterns.md 13.1: "Default OFF -- normal work still learns, which is how the
' table was bootstrapped." Re-verifying this file with NSS5_NO_LEARN=1 alone will show
' MISMATCH at the very first DebugLog call until 0x00505B91 is persisted into the helper
' table by whichever script owns that write -- that is expected, not a regression.)
'
' Body-only format: statements only; parameters are a0:TFixture, a1:TTeam, a2:TTeam, a3:Int().
'
' FIELD OFFSETS BOUND (object_model.json, all confirmed by direct evidence in this body):
'   TFixture   +0xc matchtype, +0x10 round, +0x18 leg, +0x3c level, +0x40 compid,
'              +0x50 GetFirstLegScore(*i,*i)i (Ptr/Var out-params, called with Varptr).
'   TTeam      +8 id, +0x10 tla$, +0x2c kitplayer:TKit.
'   TKit       +0x10 newcol:[]$ (newcol[1] read).
'   TBase_Team (super of TClub and TNation) +0x38 stadiumcapacity, +0x58 imgFlag:TImage.
'   TCompetition +0x18 locale, +0x1c level, +0x24 comptype, +0x50 compstatus,
'                slot 0xf8 IsCupFinal()i.
'   TGadget    slot 0x54 Hide, 0x58 Show, 0x64 SetText($,$,i,i)i, 0x6c SetColour($,$)i
'              (TLabel and the TGadget[] array elements all inherit these unmodified).
'   TProfile   +0x1d8 selectedformatch (same Global/field as TScreen_Kits.ButtonPlay.bmx's
'              g_profile.selectedformatch).
'
' GLOBAL TYPES -- three of globals_final.tsv's guesses are contradicted by direct
' construction/assignment evidence IN THIS BODY and are overridden here (do not propagate
' the tsv guess back into this file):
'   0x00C5B22C -- globals_final.tsv guesses TPlayer ("UNSOUND uniqueness claim", flagged
'     low-confidence). This body assigns a0:TFixture into it directly (`g_fixture = a0`) and
'     then reads +0xc/+0x10/+0x18/+0x3c/+0x40/+0x50 through it, all of which are exactly
'     TFixture's own fields/slot. Declared TFixture, matching the independent derivation
'     in TEngine.GetWinningClub.bmx and TEngine.SetUpWeatherConditions.bmx (both explain
'     the same re-derivation); TEngine.EndReplay.bmx carries the TPlayer guess and is
'     unrelated to this typing (never touch other files' bodies here).
'   0x00C5B218 / 0x00C5B21C -- globals_final.tsv flags a CONFLICT (TKit=2 sites vs TTeam=1
'     site). This body assigns a1:TTeam / a2:TTeam into them directly, matching the
'     typing recorded in TEngine.ForcePositionResetAll.bmx (as g_homeTeam/
'     g_awayTeam) and TEngine.ResetClubLastChange.bmx / TEngine.SetUpWeatherConditions.bmx
'     (as g_Object17/g_Object18, the names kept here for consistency with the majority).
'   0x00C5B2D4 / 0x00C5B2D8 -- globals_final.tsv guesses TClub/Object. Untouched by any other
'     recovered file. This body assigns `<club-or-nation>.imgFlag` into them in BOTH Select
'     cases (TBase_Team +0x58 is TImage on both TClub and TNation), so the correct type is
'     TImage, not TClub -- declared g_Object21/g_Object22:TImage here.
'   0x00C5B240 -- globals_final.tsv guesses Object[] ("init=bbEmptyArray"). This body clears
'     99 elements with a literal `0` store and no refcount release at all (codegen-patterns
'     10.6: a real Object-array null-store still retains/releases). A literal-0, no-release
'     store only happens for a value type, so this is Int[], not Object[] -- declared
'     g_engine_arr01:Int[] here. (g_engine_arr02 stays Object-ish: its elements ARE
'     dereferenced as objects and dispatch through slots 0x64/0x6c, which only TGadget-family
'     Types carry, so it is declared TGadget[].)
'
' STRUCTURE NOTES
'   The `TGadget[] arr` is 4 gadgets: [0]/[2] = badge/crest images for team1/team2 (SetColour
'     only), [1]/[3] = team1/team2 name labels (SetText with Left(tla,8) then SetColour with
'     the kit's newcol[1]). g_Object41/g_Object42 are 2 more separate TLabels (round info /
'     "Cup Match" or "Leg N" or "Aggregate a b" info).
'   `Select g_fixture.level` has exactly two Cases (0=club match: TClub.SelectById + kit
'     colours "666666"/"FFFFFF"; 1=international: TNation.SelectById + "FFFFFF"/"FFFFFF"),
'     no Default -- confirmed by the no-default trailing-jmp shape (codegen-patterns 10.2).
'   `Select Rand(5, 1) \ Case 1 ... \ Default ...` at the very end is NOT an If/Else: the
'     Default arm still ends in a redundant `jmp $+2` in the original (same shape as the
'     no-default Select above, EB 00), which an equivalent If/Else does not emit. Confirmed
'     by scripts/localise_diff.py isolating exactly that trailing 2 bytes as the only length
'     delta before this fix (orig 1776 vs ours 1774).
'   Two string-concat chains read right-to-left in PUSH order but LEFT-to-right in the final
'     string (cdecl: last-pushed operand is Concat's first/leftmost argument) -- confirmed
'     against the already-verified TEngine.RenderGameEngine.bmx "Mem: "+String(...) call
'     shape before trusting it here for the 5-piece Aggregate-score string.
'   `Rand(5, 1)` (low > high) is transcribed exactly as pushed; not "fixed" to `Rand(1, 5)`
'     per law 3 (reproduce, do not improve).
'   Literals read with harness.read_string()/raw float32: "SetUpMatch", ">>> MemAlloced = ",
'     "FixtureType:", "666666", "FFFFFF", "tla_CupMatch", "tla_Leg", " 1", "tla_Aggregate",
'     " ", g_engine_float09's assigned constant = 2.0 (0x00C73B34, raw dword 0x40000000).
'!Global g_engine_int55:Int
'!Global g_enginestate:Int
'!Global g_opt_playercam:Int
'!Global g_replayframes:TList
'!Global g_engine_int12:Int()
'!Global g_fixture:TFixture
'!Global g_engine_int23:Int
'!Global g_engine_int24:Int
'!Global g_Object17:TTeam
'!Global g_Object18:TTeam
'!Global g_engine_float09:Float = 1.0
'!Global g_engine_float01:Float = 2.0
'!Global g_engine_int25:Int
'!Global g_engine_arr01:Int[]
'!Global g_engine_int18:Int
'!Global g_engine_int20:Int
'!Global g_player_int01:Int
'!Global g_engine_int49:Int
'!Global g_Object21:TImage
'!Global g_Object22:TImage
'!Global g_engine_labels:TLabel[]
'!Global g_Object41:TLabel
'!Global g_Object42:TLabel
'!Global g_training_int03:Int
'!Global g_profile:TProfile
'!Global g_engine_int22:Int
LogLine("SetUpMatch")
GCCollect()
g_engine_int55 = GCMemAlloced()
LogLine(">>> MemAlloced = " + String(g_engine_int55))
TEngine.SetUpChannels()
g_enginestate = 2
If Not g_replayframes Then
	g_replayframes = CreateList()
Else
	g_replayframes.Clear()
End If
g_engine_int12 = a3
g_fixture = a0
a0.GetFirstLegScore(Varptr g_engine_int23, Varptr g_engine_int24)
LogLine("FixtureType:" + String(g_fixture.matchtype))
g_Object17 = a1
g_Object18 = a2
If g_opt_playercam > 1 Then g_engine_float09 = 2.0
g_engine_float01 = g_engine_float09
g_engine_int25 = 0
For Local i:Int = 0 To 98
	g_engine_arr01[i] = 0
Next
g_engine_int18 = 1
If g_engine_int20 >= 45 Then g_engine_int18 = 2
If g_engine_int20 >= 90 Then g_engine_int18 = 3
If g_engine_int20 >= 105 Then g_engine_int18 = 4
g_player_int01 = 0
g_engine_int49 = 0
TEngine.SetUpRadarColours()
TEngine.SetUpWeatherConditions()
TEngine.ResumeSounds()
g_Object21 = Null
g_Object22 = Null
TPitch.SetStadiumSize(60000, 0)
Select g_fixture.level
	Case 0
		Local p0:TClub = TClub.SelectById(g_Object17.id)
		Local p1:TClub = TClub.SelectById(g_Object18.id)
		If p0 <> Null Then
			g_Object21 = p0.imgFlag
			TPitch.SetStadiumSize(p0.stadiumcapacity, 0)
		End If
		If p1 <> Null Then
			g_Object22 = p1.imgFlag
		End If
		g_engine_labels[0].SetColour("666666", "FFFFFF")
		g_engine_labels[2].SetColour("666666", "FFFFFF")
		g_Object41.SetColour("666666", "FFFFFF")
		g_Object42.SetColour("666666", "FFFFFF")
	Case 1
		Local p0:TNation = TNation.SelectById(g_Object17.id)
		Local p1:TNation = TNation.SelectById(g_Object18.id)
		If p0 <> Null Then
			g_Object21 = p0.imgFlag
		End If
		If p1 <> Null Then
			g_Object22 = p1.imgFlag
		End If
		g_engine_labels[0].SetColour("FFFFFF", "FFFFFF")
		g_engine_labels[2].SetColour("FFFFFF", "FFFFFF")
		g_Object41.SetColour("FFFFFF", "FFFFFF")
		g_Object42.SetColour("FFFFFF", "FFFFFF")
End Select
Local comp:TCompetition = TCompetition.SelectById(a0.compid)
g_Object42.Hide()
If comp <> Null And comp.comptype = 1 Then
	g_Object42.Show()
	g_Object42.SetText(GetText("tla_CupMatch"), "", -1, -1)
	If g_fixture.leg = 1 Then g_Object42.SetText(GetText("tla_Leg") + " 1", "", -1, -1)
	If g_fixture.leg = 2 Then g_Object42.SetText(GetText("tla_Aggregate") + " " + String(g_engine_int24) + " " + String(g_engine_int23), "", -1, -1)
	If comp.IsCupFinal() Then
		TPitch.SetStadiumSize(60000, 1)
	ElseIf comp.level = 1 And (comp.locale = 2 Or comp.compstatus = 1) Then
		TPitch.SetStadiumSize(60000, 1)
	End If
End If
If g_training_int03 = 0 Then
	TPitch.SetUpFans(a1, a2, g_fixture.level)
End If
g_engine_labels[1].SetText(Left(g_Object17.tla, 8), "", -1, -1)
g_engine_labels[1].SetColour(g_Object17.kitplayer.newcol[1], "FFFFFF")
g_engine_labels[3].SetText(Left(g_Object18.tla, 8), "", -1, -1)
g_engine_labels[3].SetColour(g_Object18.kitplayer.newcol[1], "FFFFFF")
g_engine_int22 = -1
If g_profile.selectedformatch > 1 Then
	Select Rand(5, 1)
		Case 1
			g_engine_int22 = Rand(10, 65)
		Default
			g_engine_int22 = Rand(55, 65)
	End Select
End If
TEngine.MatchLoop()
Return 0

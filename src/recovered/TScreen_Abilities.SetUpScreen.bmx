' TScreen_Abilities.SetUpScreen
' VA 0x0053E86C   3188 bytes   mode=reloc   byte-identical vs NSS5.exe
' (3188/3188, original length from Ghidra's inventory, reloc_masked=239,
'  re-verified with NSS5_NO_LEARN=1)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x34
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug
'   record).  Every name below is the one already banked by
'   src/recovered/TScreen_Abilities.CreateScreen.bmx and
'   src/recovered/TScreen_Abilities.ButtonTraining.bmx, so the corpus stays consistent:
'     0x00C66A68 -> g_screen_abilities:TScreen   (construction site = TScreen.CreateScreen)
'     0x00C6F028 -> g_profile:TProfile           (construction/high in globals_final.tsv;
'                   fields +0x15C energy:Float and +0x16C injury:Int line up exactly)
'     TProgressBar Globals, all typed by construction site in CreateScreen (1 site each):
'       0x00C66A78 pace       0x00C66A7C dribbling  0x00C66A80 tackling
'       0x00C66A84 passing    0x00C66A88 shooting   0x00C66A8C heading
'       0x00C66A90 flair      0x00C66A94 skills     0x00C66A9C longshots
'       0x00C66AA0 finishing  0x00C66AA4 crossing   0x00C66AA8 freekicks
'       0x00C66AAC corners    0x00C66AB0 penalties  0x00C66AB4 positioning
'       0x00C66AB8 shortpassing  0x00C66ABC longpassing  0x00C66AC0 aggression
'   Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'     0x00C61C88 = TScreen+0x5C   SetActive ($,$):TScreen   (static, direct FF 15)
'     0x00C61CE0 = TScreen+0xB4   Tutorial ()i              (static, direct FF 15)
'     0x00C63438 = TLabel class table (pushed as bbObjectDowncast's 2nd argument)
'     slot 0x60 on a TScreen       = TScreen.SetActiveGadget ($)i  -- KIND=Function, but it
'       is invoked THROUGH the instance, so bcc dispatches `mov eax,[g]/mov eax,[eax]/
'       call [eax+0x60]` and pushes no Self.
'     slot 0x90 on a TScreen       = TScreen.GetGadgetByName ($):TGadget
'     slot 0x64 on a TGadget       = TGadget.SetText ($,$,i,i)i  (all four arguments are
'       written out; the trailing "", -1, -1 are pushed at the call site)
'     slot 0x8C on a TProgressBar  = TProgressBar.SetPercent (f,i)i
'     slot 0xA4 on a TProfile      = TProfile.GetSkillRating ()i
'     slot 0x130 on a TProfile     = TProfile.GetPaceCap ()i  (called twice -- for pace AND
'       for dribbling; the other five abilities test the literal 100 instead)
'   TProfile field offsets from extracted/object_model.json: +0xA4 pace, +0xA8 shooting,
'     +0xAC passing, +0xB0 tackling, +0xB4 heading, +0xB8 dribbling, +0xBC flair,
'     +0xC4 crossing, +0xC8 freekicks, +0xCC corners, +0xD0 positioning, +0xD4 shortpassing,
'     +0xD8 longpassing, +0xDC aggression, +0xE0 longshots, +0xE4 finishing, +0xE8 penalties,
'     +0xEC boots:Int[], +0x15C energy:Float, +0x16C injury:Int, +0x1C8 helppages:Int[].
'     [eax+0x58] on helppages is BBArray data (+0x18) + 16*4, i.e. helppages[16].
'   TGadget field +0x44 = alph:Float (same field TScreen_Abilities.ButtonTraining tests).
'   E8 targets: 0x004A7AC0 bbStringFromInt, 0x004A7C20 bbStringConcat,
'     0x004A8F60 bbObjectDowncast, 0x004BCB98 PlayTrack, 0x004C5549 GetText,
'     0x0050640C FormatDecimals ($ = (f,i)).  PlayTrack, GetText and FormatDecimals are all
'     already banked in src/recovered_module/, so none of them is a stub (13.3).
'
' NOTES ON SHAPE (byte-observable, read off the disassembly)
'   * `sub esp,4` -- ONE dword slot, and it is the compiler's fild scratch at [ebp-4], not a
'     source Local.  Both real Locals (`i`, `ok`) are register-allocated (ecx, esi).
'   * The For loop's counter is DEAD after the loop: nothing reads it and the loop has no
'     other effect.  It is reproduced because it is in the original, not because it does
'     anything (16.8 -- do not tidy the original's quirks).
'   * Every Int -> Float argument goes through `mov [ebp-4],eax / fild [ebp-4]` implicitly;
'     no explicit Float() or Int() appears in the source.
'   * `If g_profile.energy < 20.0` lowers to fld energy / fld 20.0 / fxch / fucompp / setae
'     / jne-skip -- bcc emits the COMPLEMENT of the source relation for floats and
'     complements the jump.  Reading the setae as the source relation gives the wrong body.
'   * The seven `Or Not ok` disjunctions short-circuit through eax (`jne` past the second
'     operand), which is the ordinary Or shape, not a Select.
'   * String literals were read out of NSS5.exe with harness.read_string.  The oracle masks
'     a literal's ADDRESS, so their CONTENTS are the part of this file the MATCH does not
'     certify.  0x00C5D284 is a zero-length BBString, i.e. "".
'!Global g_screen_abilities:TScreen
'!Global g_profile:TProfile
'!Global g_prg_pace:TProgressBar
'!Global g_prg_dribbling:TProgressBar
'!Global g_prg_tackling:TProgressBar
'!Global g_prg_passing:TProgressBar
'!Global g_prg_shooting:TProgressBar
'!Global g_prg_heading:TProgressBar
'!Global g_prg_flair:TProgressBar
'!Global g_prg_skills:TProgressBar
'!Global g_prg_longshots:TProgressBar
'!Global g_prg_finishing:TProgressBar
'!Global g_prg_crossing:TProgressBar
'!Global g_prg_freekicks:TProgressBar
'!Global g_prg_corners:TProgressBar
'!Global g_prg_penalties:TProgressBar
'!Global g_prg_positioning:TProgressBar
'!Global g_prg_shortpassing:TProgressBar
'!Global g_prg_longpassing:TProgressBar
'!Global g_prg_aggression:TProgressBar
	Function SetUpScreen()
		TScreen.SetActive("abilities", "")
		PlayTrack(2)
		g_screen_abilities.SetActiveGadget("")
		For Local i:Int = 1 To 10
			If g_profile.boots[i - 1] > 0 Then Exit
		Next
		g_prg_pace.SetPercent(g_profile.pace, 1)
		g_prg_dribbling.SetPercent(g_profile.dribbling, 1)
		g_prg_tackling.SetPercent(g_profile.tackling, 1)
		g_prg_passing.SetPercent(g_profile.passing, 1)
		g_prg_heading.SetPercent(g_profile.heading, 1)
		g_prg_shooting.SetPercent(g_profile.shooting, 1)
		g_prg_flair.SetPercent(g_profile.flair, 1)
		g_prg_skills.SetPercent(g_profile.GetSkillRating(), 1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_PaceNum")).SetText(FormatDecimals(g_profile.pace / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_DribblingNum")).SetText(FormatDecimals(g_profile.dribbling / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_TacklingNum")).SetText(FormatDecimals(g_profile.tackling / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_PassingNum")).SetText(FormatDecimals(g_profile.passing / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_HeadingNum")).SetText(FormatDecimals(g_profile.heading / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_ShootingNum")).SetText(FormatDecimals(g_profile.shooting / 10.0, 1), "", -1, -1)
		TLabel(g_screen_abilities.GetGadgetByName("lbl_FlairNum")).SetText(FormatDecimals(g_profile.flair / 10.0, 1), "", -1, -1)
		g_screen_abilities.GetGadgetByName("btn_Pace").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Dribbling").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Tackling").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Passing").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Heading").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Shooting").alph = 1.0
		g_screen_abilities.GetGadgetByName("btn_Flair").alph = 1.0
		Local ok:Int = 1
		If g_profile.injury <> 0 Then ok = 0
		If g_profile.energy < 20.0 Then ok = 0
		If g_profile.pace >= g_profile.GetPaceCap() Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Pace").alph = 0.5
		End If
		If g_profile.dribbling >= g_profile.GetPaceCap() Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Dribbling").alph = 0.5
		End If
		If g_profile.tackling >= 100 Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Tackling").alph = 0.5
		End If
		If g_profile.passing >= 100 Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Passing").alph = 0.5
		End If
		If g_profile.heading >= 100 Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Heading").alph = 0.5
		End If
		If g_profile.shooting >= 100 Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Shooting").alph = 0.5
		End If
		If g_profile.flair >= 100 Or Not ok
			g_screen_abilities.GetGadgetByName("btn_Flair").alph = 0.5
		End If
		g_prg_positioning.SetPercent(g_profile.positioning, 1)
		g_prg_shortpassing.SetPercent(g_profile.shortpassing, 1)
		g_prg_longpassing.SetPercent(g_profile.longpassing, 1)
		g_prg_finishing.SetPercent(g_profile.finishing, 1)
		g_prg_longshots.SetPercent(g_profile.longshots, 1)
		g_prg_crossing.SetPercent(g_profile.crossing, 1)
		g_prg_freekicks.SetPercent(g_profile.freekicks, 1)
		g_prg_corners.SetPercent(g_profile.corners, 1)
		g_prg_penalties.SetPercent(g_profile.penalties, 1)
		g_prg_aggression.SetPercent(g_profile.aggression, 1)
		g_prg_positioning.SetText(GetText("Positioning") + " " + g_profile.positioning, "", -1, -1)
		g_prg_shortpassing.SetText(GetText("Short Passing") + " " + g_profile.shortpassing, "", -1, -1)
		g_prg_longpassing.SetText(GetText("Long Passing") + " " + g_profile.longpassing, "", -1, -1)
		g_prg_finishing.SetText(GetText("Finishing") + " " + g_profile.finishing, "", -1, -1)
		g_prg_longshots.SetText(GetText("Long Shots") + " " + g_profile.longshots, "", -1, -1)
		g_prg_crossing.SetText(GetText("Crossing") + " " + g_profile.crossing, "", -1, -1)
		g_prg_freekicks.SetText(GetText("Free Kicks") + " " + g_profile.freekicks, "", -1, -1)
		g_prg_corners.SetText(GetText("Corners") + " " + g_profile.corners, "", -1, -1)
		g_prg_penalties.SetText(GetText("Penalties") + " " + g_profile.penalties, "", -1, -1)
		g_prg_aggression.SetText(GetText("Aggression") + " " + g_profile.aggression, "", -1, -1)
		If g_profile.helppages[16] = 0
			TScreen.Tutorial()
			g_profile.helppages[16] = 1
		End If
	End Function

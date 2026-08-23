' TPlayer.DoAnimCelebrate
' VA 0x004fd64c   2851 bytes   vtable slot 0x1f0   sig (i)i
' byte-identical vs NSS5.exe (2851/2851, original length from Ghidra's inventory, mode=reloc,
' verified under NSS5_NO_LEARN=1).
' Body-only format: statements only; parameters are a0, a1, ...
' a0 is the celebration-anim direction/style index (2/3/0/1/5 handled, others leave
' currentanim untouched). Case 0 also drops a TPitchMark (a sliding celebration).
' The Fame/Boss/Fans bonus tracking only runs for the human-tracked newstar during a
' celebration state (g_player_int01=8) and only once per bonus (guarded by Self.bonus).
' TProfile fields position/coachrep_fame/coachrep_boss/coachrep_fans and methods
' UpdateRelationship(i,i)i / CheckAchievement(i)i are real reflected members (offsets
' 0x30/0x70/0x60/0x68, slots 0xc0/0x150) -- confirmed via harness.load_data(), not invented.
' The three position-based bonus tables MUST be written as `Select g_profile.position`
' (not If/ElseIf): bcc's Select evaluates the subject once and places the Default body
' immediately after the compares, before the numbered Case bodies -- an If/ElseIf cascade
' emits an extra per-branch re-test and is 60 bytes too long per occurrence (3 occurrences).
' The away-team zone Select (z, 1..8) needs explicit empty `Case 1` / `Case 5` clauses --
' omitting a case that does nothing still drops its `cmp/je` from the original.
' String literals read from NSS5.exe via harness.read_string(): "FF00FF", "+", "Fame!",
' "Boss", "Fans" (all confirmed byte-exact; a MATCH alone does not certify literal content).
'!Global g_player_arr10:Int[]
'!Global g_player_arr11:Int[]
'!Global g_player_arr12:Int[]
'!Global g_player_arr13:Int[]
'!Global g_player_arr14:Int[]
'!Global g_player_f07:Float
'!Global g_player_int01:Int
'!Global g_team1:TTeam
'!Global g_team2:TTeam
'!Global g_player_tplayer01:TPlayer
'!Global g_cameramen:TList
'!Global g_profile:TProfile
'!Global g_pitch_int05:Int
'!Global g_player_int16:Int
'!Global g_player_int17:Int
'!Global g_player_int19:Int
'!Global g_pitch_int17:Int
' g_pitch_int18/g_pitch_int19 original data-section values are 140/-140
' (0x00C5D678/0x00C5D67C), read directly from NSS5.exe. See codegen-patterns 21.1/21.3.
'!Global g_pitch_int18:Int = 140
'!Global g_pitch_int19:Int = -140
'!Global g_pitch_int21:Int
' CASE DIRECTION CORRECTED 2026-08-22: 3 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
Select a0
	Case 2
		Self.currentanim = g_player_arr10
	Case 3
		Self.currentanim = g_player_arr11
	Case 0
		Self.currentanim = g_player_arr12
		TPitchMark.AddPitchMark(Int(Self.x + Self.xvel * g_player_f07), Int(Self.y + Self.yvel * g_player_f07), Int(Self.direction), 1, 0.5)
	Case 1
		Self.currentanim = g_player_arr13
	Case 5
		Self.currentanim = g_player_arr14
End Select
Self.frame = 0
Self.joy.Clear()
If Self.newstar And g_player_int01 = 8 And g_player_tplayer01 = Self
	If Self.bonus = 0
		For Local cm:TCameraMan = EachIn g_cameramen
			If Dist2D(Self.x, Self.y, cm.x, cm.y) < TPitch.YardsToPixels(10.0)
				Self.bonus = 1
				TParticle.StarShower(Int(Self.x), Int(Self.y), "+" + GetText("Fame!").ToUpper(), "FF00FF")
				g_profile.CheckAchievement(37)
				Select g_profile.position
					Case 3
						g_profile.coachrep_fame = g_profile.UpdateRelationship(7, 3)
					Case 4
						g_profile.coachrep_fame = g_profile.UpdateRelationship(7, 2)
					Case 5
						g_profile.coachrep_fame = g_profile.UpdateRelationship(7, 1)
					Default
						g_profile.coachrep_fame = g_profile.UpdateRelationship(7, 4)
				End Select
				Exit
			EndIf
		Next
	EndIf
	If Self.bonus = 0
		Local goaly:Int = g_pitch_int18
		If Self.GetMyTeam() = g_team2 Then goaly = g_pitch_int19
		If Dist2D(Self.x, Self.y, g_pitch_int17, goaly) < TPitch.YardsToPixels(20.0)
			Self.bonus = 1
			TParticle.StarShower(Int(Self.x), Int(Self.y), "+" + GetText("Boss").ToUpper(), "FF00FF")
			g_profile.CheckAchievement(38)
			Select g_profile.position
				Case 3
					g_profile.UpdateRelationship(1, 4)
					g_profile.coachrep_boss = g_profile.coachrep_boss + 4
				Case 4
					g_profile.UpdateRelationship(1, 3)
					g_profile.coachrep_boss = g_profile.coachrep_boss + 3
				Case 5
					g_profile.UpdateRelationship(1, 2)
					g_profile.coachrep_boss = g_profile.coachrep_boss + 2
				Default
					g_profile.UpdateRelationship(1, 5)
					g_profile.coachrep_boss = g_profile.coachrep_boss + 5
			End Select
		EndIf
	EndIf
	If Self.bonus = 0
		If Self.x < -g_player_int16 Or Self.x > g_player_int16 Or Self.y < -g_player_int17 Or Self.y > g_player_int17
			Local ok:Int = 0
			Local z:Int = 0
			If Self.y < -g_player_int17 Then z = 1
			If Self.y > g_player_int17 Then z = 2
			If Self.x < -g_player_int16 Then z = 3
			If Self.x > g_player_int16 Then z = 4
			If Self.y < -g_player_int17 And Self.x < -g_player_int16 Then z = 5
			If Self.y < -g_player_int17 And Self.x > g_player_int16 Then z = 6
			If Self.y > g_player_int17 And Self.x < -g_player_int16 Then z = 7
			If Self.y > g_player_int17 And Self.x > g_player_int16 Then z = 8
			If Self.GetMyTeam() = g_team1
				Select z
					Case 1
						If g_pitch_int21 >= 2 Then ok = 1
					Case 2
						If g_pitch_int21 >= 2 Then ok = 1
					Case 3
						If g_pitch_int05 Or Self.y < g_player_int19 Then ok = 1
					Case 4
						If g_pitch_int21 >= 1 And g_pitch_int05 = 0 Then ok = 1
					Case 5
						ok = 1
					Case 6
						If g_pitch_int21 >= 1 And g_pitch_int05 = 0 Then ok = 1
					Case 7
						If g_pitch_int05 <> 0 Then ok = 1
					Case 8
						If g_pitch_int21 >= 1 And g_pitch_int05 = 0 Then ok = 1
				End Select
			Else
				Select z
					Case 1
					Case 2
						If g_pitch_int21 >= 2 And g_pitch_int05 Then ok = 1
					Case 3
						If g_pitch_int05 = 0 And Self.y > g_player_int19 Then ok = 1
					Case 4
						If g_pitch_int21 >= 1 And g_pitch_int05 Then ok = 1
					Case 5
					Case 6
						If g_pitch_int21 >= 3 And g_pitch_int05 Then ok = 1
					Case 7
						ok = 1
					Case 8
						If g_pitch_int21 >= 3 And g_pitch_int05 Then ok = 1
				End Select
			EndIf
			If ok
				Self.bonus = 1
				TParticle.StarShower(Int(Self.x), Int(Self.y), "+" + GetText("Fans").ToUpper(), "FF00FF")
				g_profile.CheckAchievement(36)
				Select g_profile.position
					Case 3
						g_profile.UpdateRelationship(3, 4)
						g_profile.coachrep_fans = g_profile.coachrep_fans + 4
					Case 4
						g_profile.UpdateRelationship(3, 3)
						g_profile.coachrep_fans = g_profile.coachrep_fans + 3
					Case 5
						g_profile.UpdateRelationship(3, 2)
						g_profile.coachrep_fans = g_profile.coachrep_fans + 2
					Default
						g_profile.UpdateRelationship(3, 5)
						g_profile.coachrep_fans = g_profile.coachrep_fans + 5
				End Select
			EndIf
		EndIf
	EndIf
EndIf
Return 0

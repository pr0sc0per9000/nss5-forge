' TPlayer.UpdateOffside
' VA 0x004FE9BA   984 bytes   vtable slot 0x218   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (984/984, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=34)
' Body-only format: statements only, Self implicit.
'
' Companion to TPlayer.CheckOffside: CheckOffside fires the instant a pass
' is played into an offside position; UpdateOffside runs every frame the ball is in open play
' and (a) recomputes Self.offside live as attacker/defenders move, and (b) after a short delay
' shows the "Get Onside" boss-message nag if the player stays offside.
'
' module Globals assumed by this body (names ours, types load-bearing):
'   0x00C6CF90 : Int    g_training_int03  -- training-mode suppression flag (already named,
'                                            reused verbatim from TPlayer.AddPlayerRating.bmx)
'   0x00C5B1FC : Int    g_player_int01    -- match state; TEngine.GetStringMatchState.bmx maps
'                                            1=In Play, 4=Free Kick, 6=Goal Kick -- exactly the
'                                            three states offside is live in (already named)
'   0x00C5DEA4 : TBall  g_player_tplayer02 -- g_ball (hand-verified elsewhere)
'   0x00C5DE10 : TList  g_players          -- all on-pitch TPlayer, downcast confirmed against
'                                            TPlayer's own class table (0x00C5F94C) at the
'                                            EachIn NextObject() call; same Global already
'                                            named in TPlayer.CleanThrough.bmx
'   0x00C6EFD4 : Int    g_player_int50    -- current match clock (hand-verified elsewhere)
'   0x00C5B218 : TTeam  g_hometeam        -- +8 is TTeam.id (already established in
'                                            TPlayer.CheckOffside.bmx's own header)
'   0x00C6B284 : TList  g_bossmsg_list    -- already named in TBossMessage.ClearAll.bmx; slot
'                                            0x70 = TList.Count()
'
' slots resolved: TPlayer 0x160 = GetShootingDirection()i; 0x170 = GetDistanceToByLine(i)f;
'   0x238 = BossPositive()i; TBall 0x70(field) = controlledby:TPlayer; TStats_Match 0x10(field)
'   = reds:Int; TBossMessage classtable+0x34 = Create(i,$,$)i (0x00C6B414 is the class-table
'   interior, not a real Global -- see globals_classtable_slots.tsv); FUN_004c5549 = the
'   already-recovered module Function GetText (see TProfile.GetCurrentTip.bmx); 0x59f089 =
'   _brl_random_Rand -- the "...(4, 1)" is source order (rightmost source arg pushed first).
' fields: offside +0xac, selectionno +0xbc, goalside +0x8c, y +0x50, teamid +0x14,
'   offsidetime +0xb8, matchstats +0x188 (:TStats_Match), newstar +0x8.
' string literals read out of .data: 0x00C7A6D4="CBOSSPOS_GETONSIDE",
'   0x00C7A704="CBOSSNEG_GETONSIDE", 0x00C5D680="FFFFFF". Float constant at 0x00C7A6D0 read
'   directly (2.0) -- the oracle masks the .rdata ADDRESS only, so the VALUE was verified by
'   hand with check_floats.py, not inferred.
'
' load-bearing shape (the two things that cost the most iterations to pin down):
'   * `If Not g_player_tplayer02 Then Return 0` -- NOT `If g_player_tplayer02 = Null`. The two
'     compile to different bytes (TBossMessage.ClearAll.bmx's header already documents this:
'     `<> Null` emits a direct cmp/je; `Not x` emits a materialised cmp/setne/movzx/cmp/je).
'     Likewise `Self.goalside <> 0` (not `= 0`) guards the Return -- the source's sense is the
'     opposite of the natural-looking reading of the decompile.
'   * The four-term `Self.newstar And matchclock>offsidetime+2500 And matchclock<offsidetime+3000
'     And g_bossmsg_list.Count()=0` is ONE flat And, not nested Ifs -- each false term's `je`
'     lands exactly on the NEXT term's own `cmp eax,0` (reusing the already-materialised 0),
'     cascading through to the real exit only from the last term. And the home/away flag
'     `(g_hometeam.id = Self.teamid)` is NOT hoisted into a shared Local -- the original
'     recomputes it separately inline at each of the two TBossMessage.Create call sites
'     (20 redundant bytes per branch); hoisting it cost exactly 2x20 bytes short.
'   * `wasoffside` is Self.offside read before the reset-to-0 at the top of the method, and the
'     final `Self.offside=1` after the defender-search loop is unconditional (the loop's own
'     early `Return 0` mid-scan is what leaves it at 0 when a defender IS found onside).
	Method UpdateOffside:Int()
		'!Global g_training_int03:Int
		'!Global g_player_int01:Int
		'!Global g_player_tplayer02:TBall
		'!Global g_players:TList
		'!Global g_player_int50:Int
		'!Global g_hometeam:TTeam
		'!Global g_bossmsg_list:TList
		Local wasoffside:Int = Self.offside
		Self.offside = 0
		If g_training_int03 <> 0 Then Return 0
		Select g_player_int01
			Case 1
			Case 4
			Case 6
			Default
				Return 0
		End Select
		If Not g_player_tplayer02 Then Return 0
		If g_player_tplayer02.controlledby <> Null
			If g_player_tplayer02.controlledby = Self Then Return 0
			If g_player_tplayer02.controlledby.teamid <> Self.teamid Then Return 0
		End If
		If Self.selectionno = 0 Or Self.selectionno > 10 Then Return 0
		If Self.goalside <> 0 Then Return 0
		Select Self.GetShootingDirection()
			Case -1
				If Self.y >= 0 Then Return 0
			Case 1
				If Self.y <= 0 Then Return 0
		End Select
		Local n:Int = Int(Self.GetDistanceToByLine(1) + 2.0)
		For Local p:TPlayer = EachIn g_players
			If p.matchstats.reds <> 0 Then Continue
			If p.teamid = Self.teamid Then Continue
			If p.selectionno = 0 Or p.selectionno > 10 Then Continue
			If p.GetDistanceToByLine(0) < n Then Return 0
		Next
		Self.offside = 1
		If wasoffside = 0 And Self.offside = 1
			Self.offsidetime = g_player_int50
		Else
			If Self.newstar And g_player_int50 > Self.offsidetime + 2500 And g_player_int50 < Self.offsidetime + 3000 And g_bossmsg_list.Count() = 0
				If Self.BossPositive()
					TBossMessage.Create((g_hometeam.id = Self.teamid), GetText("CBOSSPOS_GETONSIDE" + Rand(4, 1)), "FFFFFF")
				Else
					TBossMessage.Create((g_hometeam.id = Self.teamid), GetText("CBOSSNEG_GETONSIDE" + Rand(4, 1)), "FFFFFF")
				End If
			End If
		End If
		Return 0
	End Method

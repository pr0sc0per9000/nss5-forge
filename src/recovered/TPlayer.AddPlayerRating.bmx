' TPlayer.AddPlayerRating
' VA 0x005031AE   1357 bytes   vtable slot 0x234   sig (i,i,$)i
' byte-identical vs NSS5.exe (1357/1357, original length from Ghidra's inventory, mode=reloc)
' module globals this body declares:
'   Global g_training_int03:Int          (0x00C6CF90)
'   Global g_player_tplayer02:TBall      (0x00C5DEA4)
'   Global g_contractoffer_tplayer:TProfile (0x00C6F028)
'   Global g_Object17:TTeam              (0x00C5B218)
' Assumptions: 0x00C6B414 = TBossMessage.Create(i,$,$)i; FUN_004C5549 = GetText;
' FUN_00505B91 = LogLine; FUN_00505F6D = ClampInt.
' NOTE -- 0x004A6BF0 is `_bbStringContains`, NOT `_bbStringStartsWith` as
' decomp_annotated labels it. With `.StartsWith` the body is the right LENGTH
' (1357/1357) and diverges only in that one E8 operand at +893; with `.Contains`
' it is exact. runtime_helpers.tsv (49 witnesses) is correct, the annotator is not.
' `Rand(4)` / `Rand(5)` emit two pushes because BRL's Rand has `max_value:Int=1`
' as a default argument, which bcc materialises at the call site.
	Method AddPlayerRating:Int(a0:Int, a1:Int, a2:String)
		'!Global g_training_int03:Int
		'!Global g_player_tplayer02:TBall
		'!Global g_contractoffer_tplayer:TProfile
		'!Global g_Object17:TTeam
		If Self.newstar = 0 Then Return 0
		If g_training_int03 <> 0 Then Return 0
		If g_player_tplayer02 <> Null And g_player_tplayer02.lastkickmatchstate = 3 Then Return 0
		Local s:String = ""
		Select a0
			Case 1
				g_contractoffer_tplayer.temp_freekicks = g_contractoffer_tplayer.temp_freekicks + a1
				s = "Free Kicks"
			Case 2
				g_contractoffer_tplayer.temp_corners = g_contractoffer_tplayer.temp_corners + a1
				s = "Corners"
			Case 3
				g_contractoffer_tplayer.temp_crossing = g_contractoffer_tplayer.temp_crossing + a1
				s = "Crossing"
			Case 4
				g_contractoffer_tplayer.temp_positioning = g_contractoffer_tplayer.temp_positioning + a1
				s = "Positioning"
			Case 5
				g_contractoffer_tplayer.temp_shortpassing = g_contractoffer_tplayer.temp_shortpassing + a1
				s = "Short Passing"
			Case 6
				g_contractoffer_tplayer.temp_longpassing = g_contractoffer_tplayer.temp_longpassing + a1
				s = "Long Passing"
			Case 7
				g_contractoffer_tplayer.temp_aggression = g_contractoffer_tplayer.temp_aggression + a1
				s = "Aggression"
			Case 8
				g_contractoffer_tplayer.temp_longshots = g_contractoffer_tplayer.temp_longshots + a1
				s = "Long Shots"
			Case 9
				g_contractoffer_tplayer.temp_finishing = g_contractoffer_tplayer.temp_finishing + a1
				s = "Finishing"
			Case 10
				g_contractoffer_tplayer.temp_penalties = g_contractoffer_tplayer.temp_penalties + a1
				s = "Penalties"
		End Select
		ClampInt(Varptr g_contractoffer_tplayer.temp_freekicks, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_corners, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_crossing, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_positioning, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_shortpassing, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_longpassing, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_aggression, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_longshots, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_finishing, -10, 10)
		ClampInt(Varptr g_contractoffer_tplayer.temp_penalties, -10, 10)
		If a1 < 0
			s = s + " " + a1
		Else
			s = s + " +" + a1
		EndIf
		LogLine(s)
		If a2 <> ""
			If a2.Contains("BAD") And Self.matchstats.rating > 95 Then Return 0
			If a2.Contains("GOOD") And Rand(4) = 1
				TBossMessage.Create(g_Object17.id = Self.teamid, GetText("CBOSS_GENERICGOOD" + Rand(5)), "FFFFFF")
			ElseIf a2.Contains("BAD") And Rand(4) = 1
				TBossMessage.Create(g_Object17.id = Self.teamid, GetText("CBOSS_GENERICBAD" + Rand(5)), "FFFFFF")
			ElseIf Self.BossPositive() <> 0
				TBossMessage.Create(g_Object17.id = Self.teamid, GetText(a2.Replace("SHOUT", "POS")), "FFFFFF")
			Else
				TBossMessage.Create(g_Object17.id = Self.teamid, GetText(a2.Replace("SHOUT", "NEG")), "FFFFFF")
			EndIf
		EndIf
	End Method

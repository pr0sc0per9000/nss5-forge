' TStats_Match.UpdateRating
' VA 0x0056e2de   1357 bytes   vtable slot 0x48   sig (i,i,i,i,i,i)i
' byte-identical vs NSS5.exe (1357/1357, original length from Ghidra's inventory)
' harness mode=reloc.
' Params a0..a5 are positionally verified from the disassembly; names are inferred
'   (docs/specs/09-match-engine-implementation-spec.md 5.3 calls them a1,minsPlayed,
'   subOnMin,a4,a5,a6 -- shifted by one here to match this project's a0-based convention).
'   a1=minutes played this game, a2=minute subbed on, a3=selection no. passed to
'   GetPlayTime, a4/a5 form the score-margin term m=a5-a4 clamped to [-15,0].
' g_stats_match_float01..11 and g_opt_matchlength are the Engine.ini rating weights and
'   the match-length option, same Globals as TStats_Match.New (0x00C6A62C-654, 0x00C5D230).
' TPitch class table + 0x6C = TPitch.YardsToPixels(f)f (0x00C5D998, confirmed).
' EachIn downcast class table 0x00C6A97C = TStat (as in CountStat/AddStat).
' Abs(Int)Int is the shared runtime idiom at 0x004A7F60 (xor/sar/sub abs, no dedicated name).
' ORIGINAL BUG (VA 0x0056E763): stype=8 ("saves"?) adds g_stats_match_float08
'   (ratingtackles), the SAME global as stype=7 (tackles), and shares its counter. The
'   compiled-in ratingsaves weight (0x00C6A644, g_stats_match_float07) is dead code in
'   this function -- never read here. Reproduced faithfully, not fixed.
' Comparison direction is load-bearing for codegen: `a4 > a5` / `a1 > a2` match the
'   original's register/operand order exactly; the mirror-image spellings compile to a
'   different (but logically identical) cmp/jcc pair and cost bytes.
	Method UpdateRating:Int(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int, a5:Int)
		' Original data-section values, read directly from NSS5.exe -- see
		' codegen-patterns 21.1/21.3.
		'!Global g_stats_match_float01:Float = -0.25
		'!Global g_stats_match_float02:Float = 3.0
		'!Global g_stats_match_float03:Float = 3.0
		'!Global g_stats_match_float04:Float = 1.0
		'!Global g_stats_match_float05:Float = 17.0
		'!Global g_stats_match_float06:Float = 10.0
		'!Global g_stats_match_float08:Float = 5.0
		'!Global g_stats_match_float09:Float = -5.0
		'!Global g_stats_match_float10:Float = -8.0
		'!Global g_stats_match_float11:Float = -22.0
		'!Global g_opt_matchlength:Int
		Self.rating = 55
		If Self.subbedontime > -1 Then Self.rating = 60
		If Self.subbedontime > 65 Then Self.rating = 65
		If Self.subbedofftime < 45 Then Self.rating = 65

		Local gd:Int = a1 - a2
		If gd > 3 Then gd = 3

		Select a0
			Case 3
				Self.rating = Int(Self.rating + gd * 2.5)
			Case 4
				Self.rating = Int(Self.rating + gd * 2.5)
			Case 5
				Self.rating = Int(Self.rating + gd * 2.5)
			Default
				Self.rating :+ 5
				If a2 = 0
					Self.rating :+ a3 / 3
				Else
					Self.rating :- a2 * 5
				EndIf
		End Select

		Local m:Float = Float(a5 - a4)
		ClampFloat(Varptr m, -15.0, 0.0)
		If a1 = a2
			If a4 > a5 Then Self.rating = Int(Self.rating - m * 0.5)
		ElseIf a1 < a2
			If a4 > a5 Then Self.rating = Int(Self.rating - m)
		ElseIf a1 > a2
			If a4 > a5 Then Self.rating = Int(Self.rating - m * 0.25)
		EndIf

		Local playTime:Int = Self.GetPlayTime(a3)
		Local perMin:Float = g_stats_match_float01
		Select g_opt_matchlength
			Case 3
				perMin = g_stats_match_float01 / 5.0 * 3.0
			Case 5
				perMin = g_stats_match_float01
			Case 7
				perMin = g_stats_match_float01 / 5.0 * 7.0
		End Select
		Self.rating = Int(Self.rating + playTime * perMin)

		Local nGoals:Int, nShots:Int, nPasses:Int, nAssists:Int, nHeaders:Int, nTS:Int
		For Local s:TStat = EachIn Self.list
			Select s.stype
				Case 5
					nGoals :+ 1
					If nGoals < 4 Then Self.rating = Int(Self.rating + g_stats_match_float05)
				Case 2
					nShots :+ 1
					If nShots < 11 Then Self.rating = Int(Self.rating + g_stats_match_float04)
				Case 3
					nPasses :+ 1
					If nPasses < 11 Then Self.rating = Int(Self.rating + g_stats_match_float02)
				Case 4
					nAssists :+ 1
					If nAssists < 4 Then Self.rating = Int(Self.rating + g_stats_match_float06)
				Case 6
					nHeaders :+ 1
					If nHeaders < 11
						Local ok:Int = (a0 = 1 Or a0 = 2)
						If Not ok Then ok = Abs(s.y) > TPitch.YardsToPixels(30.0)
						If ok Then Self.rating = Int(Self.rating + g_stats_match_float03)
					EndIf
				Case 7
					nTS :+ 1
					If nTS < 11 Then Self.rating = Int(Self.rating + g_stats_match_float08)
				Case 8
					nTS :+ 1
					' ORIGINAL BUG: adds g_stats_match_float08 (ratingtackles) again, not
					' g_stats_match_float07 (ratingsaves) -- see file header.
					If nTS < 11 Then Self.rating = Int(Self.rating + g_stats_match_float08)
				Case 11
					Self.rating = Int(Self.rating + g_stats_match_float09)
				Case 9
					Self.rating = Int(Self.rating + g_stats_match_float10)
				Case 10
					Self.rating = Int(Self.rating + g_stats_match_float11)
			End Select
		Next

		ClampInt(Varptr Self.rating, 1, 100)
		If playTime < 10 Then ClampInt(Varptr Self.rating, 50, 60)
		Return 0
	End Method

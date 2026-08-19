' TPlayer.AddStat   (KIND=Method, SIG=(i,f,f,f,f)i, SLOT=0x228)
' VA 0x004FF16A   1027 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe (1027/1027, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=1027/1027  reloc_masked=54  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   a0 = stat id, a1 = the rating/value passed straight through as the Float column,
'   a2 = a second value that is truncated, a3/a4 = an OPTIONAL pitch position that
'   overrides the player's own (x,y) when a3 is non-zero.
'   0x00C5B210 g_engine_int20:Int -- the match minute stamped into every stat row.
'   0x00C6B284 -> TList (slot 0x70 = TList.Count, class table 0x00CB0824).
'     globals_final guesses TBossMessage, which has no slot 0x70 at all; the guard is
'     "only shout when no boss message is queued", so the Global is the message LIST.
'   0x00C5DEA4 -> TBall (see codegen-patterns 11.2); field +0x6C = lastkickmatchstate.
'   TStats_Match.AddStat is slot 0x38 (i,i,i,i,f,i); CountStat is slot 0x3C;
'     TPlayer.AddPlayerRating is slot 0x234 (i,i,$).
'   TPitch.InsidePenaltyBox reached through the class-table slot at 0x00C5D988.
'   `Rand(4)` emits `push 1; push 4` -- brl.random's maxValue defaults to 1.
'   Literals read out of the exe (0x00C7A7D8, 0x00C7A810, 0x00C7A844, 0x00C7A87C,
'     0x00C72C34, 0x00C72CDC, 0x00C72D48); each is suffixed with a 1-of-4 variant number.
'   `sub esp,8` is exactly the two Float locals; a2/a3/a4 live on the x87 stack from
'     the prologue, which is why the override test is a bare fucom with no spill.

'!Global g_engine_int20:Int
'!Global g_bossmessages:TList
'!Global g_ball:TBall

	Method AddStat(a0:Int, a1:Float, a2:Float, a3:Float, a4:Float)
		Local xx:Float = Self.x
		Local yy:Float = Self.y
		If a3 <> 0.0
			xx = a3
			yy = a4
		End If
		Self.matchstats.AddStat(a0, g_engine_int20, Int(xx), Int(yy), a1, Int(a2))
		If Self.newstar And g_bossmessages.Count() = 0
			Select a0
				Case 8
					Self.AddPlayerRating(7, 1, "")
					Self.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODTACKLE" + Rand(4))
				Case 7
					Self.AddPlayerRating(7, 1, "")
					Self.AddPlayerRating(4, 1, "CBOSSSHOUT_GOODTACKLE" + Rand(4))
				Case 11
					If Self.matchstats.CountStat(11) Mod 3 = 0
						Self.AddPlayerRating(7, 2, "CBOSSSHOUT_CALMDOWN" + Rand(4))
					Else
						Self.AddPlayerRating(7, 2, "")
					End If
				Case 9
					Self.AddPlayerRating(7, 3, "CBOSSSHOUT_CALMDOWN" + Rand(4))
				Case 10
					Self.AddPlayerRating(7, 4, "CBOSSSHOUT_EXPLETIVE" + Rand(4))
				Case 5
					If TPitch.InsidePenaltyBox(Int(xx), Int(yy), 0)
						If g_ball.lastkickmatchstate = 7
							Self.AddPlayerRating(10, 7, "CBOSSSHOUT_GOODFINISH" + Rand(4))
						ElseIf g_ball.lastkickmatchstate = 4
							Self.AddPlayerRating(1, 7, "CBOSSSHOUT_GOODFREEKICK" + Rand(4))
						ElseIf g_ball.lastkickmatchstate = 5
							Self.AddPlayerRating(2, 5, "CBOSSSHOUT_GOODCORNER" + Rand(4))
						Else
							Self.AddPlayerRating(9, 5, "CBOSSSHOUT_GOODFINISH" + Rand(4))
						End If
					Else
						Self.AddPlayerRating(8, 3, "CBOSSSHOUT_GOODLONGSHOT" + Rand(4))
					End If
			End Select
		End If
	End Method

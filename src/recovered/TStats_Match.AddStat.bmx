' TStats_Match.AddStat
' VA 0x0056d827   207 bytes   vtable slot 0x38   sig (i,i,i,i,f,i)i
' byte-identical vs NSS5.exe (207/207, original length from Ghidra's inventory)
' Global: 0x00C6EFD4 Int (match clock) -- globals_final.tsv types it :TScreen with a
' flagged construction conflict; here it is plainly an Int. TStat.Create is TStat+0x30,
' TList.AddLast is slot 0x44. Both Create calls pass a0, not the literal 1.
' The 9/10 dispatch is a Select with no Default (If/ElseIf is 3 bytes short), and the
' clock test reads `g_matchtime > Self.lastdistancetime + 250` (cmp [g],ebx / jg).
	Method AddStat:Int(a0:Int, a1:Int, a2:Int, a3:Int, a4:Float, a5:Int)
		'!Global g_matchtime:Int
		If a0 = 1
			Self.distance = Self.distance + a5
			If g_matchtime > Self.lastdistancetime + 250
				Self.list.AddLast(TStat.Create(a0, a1, a2, a3, a4, a5))
				Self.lastdistancetime = g_matchtime
			EndIf
		Else
			Select a0
				Case 9
					Self.yellows :+ 1
				Case 10
					Self.reds :+ 1
			End Select
			Self.list.AddLast(TStat.Create(a0, a1, a2, a3, a4, a5))
		EndIf
		Return 0
	End Method

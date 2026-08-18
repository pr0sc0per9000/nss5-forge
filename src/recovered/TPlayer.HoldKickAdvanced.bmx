' TPlayer.HoldKickAdvanced  -- KIND=Method, slot 0x108, sig ()i
' VA 0x004F8487   591 bytes
' byte-identical vs NSS5.exe (591/591, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=23)
'
' ASSUMPTIONS
'  * Globals (names ours):
'      0x00C5B1FC -> g_matchstate:Int  (bare dword compares, no refcount traffic)
'      0x00C5DEA4 -> g_ball:TBall      (guide 11.2 records this address as mistyped
'                                       TPlayer in globals_final.tsv; slot 0x68 is
'                                       TBall.Kick(:TPlayer,f,f,i,i), which matches the
'                                       six-push call exactly)
'  * 0x005B9690 = _bbFloatToInt, emitted implicitly for each Float->Int argument
'    (Self.kickpower into DoAnimKick(i), and both Rand arguments). Nothing is written for
'    it in source. 0x0059F089 = Rand.
'  * TPlayer slot 0x1E4 = DoAnimKick(i).
'  * Both `Select Self.joy.activebutton` blocks are Selects, not If/ElseIf: the three
'    Case compares are emitted back to back with every target past the last (guide 10.2).
'  * Rand's arguments are evaluated right-to-left, so the NEGATIVE one is argument 1.
'  * The float constant at 0x00C79E74/78/7C/80 is 1.5 in all four slots.
'  * Each Case uses its OWN stack slot ([ebp-4], [ebp-8], [ebp-0xC]), so each declares its
'    own Float Local rather than sharing one.
	Method HoldKickAdvanced:Int()
		'!Global g_matchstate:Int
		'!Global g_ball:TBall
		LogLine("HoldKickAdvanced")
		Self.DoAnimKick(Self.kickpower)
		If g_matchstate <> 7 And g_matchstate <> 9 And g_matchstate <> 5 And g_matchstate <> 3
			Select Self.joy.activebutton
				Case 1
					Local d1:Float = Self.kickdirection
					d1 :+ Rand(-Self.shooting, Self.shooting)
					Self.kickdirection = d1
				Case 2
					Local d2:Float = Self.kickdirection
					d2 :+ Rand(-Self.passing * 1.5, Self.passing * 1.5)
					Self.kickdirection = d2
				Case 3
					Local d3:Float = Self.kickdirection
					d3 :+ Rand(-Self.passing * 1.5, Self.passing * 1.5)
					Self.kickdirection = d3
			End Select
		End If
		Select Self.joy.activebutton
			Case 1
				g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 2, 0)
			Case 2
				g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 1, 0)
			Case 3
				g_ball.Kick(Self, Self.kickdirection, Self.kickpower, 3, 0)
		End Select
	End Method

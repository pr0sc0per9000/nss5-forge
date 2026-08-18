' TCompetition.IsComplete
' VA 0x0050CF11   707 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (i)i, slot 0xa8
' ASSUMPTIONS
'  * No module Globals are touched (LogLine brings its own).
'  * The comptype test is an OR-CHAIN, not a Select: each `cmp` is followed by
'    sete/movzx and a `jne` forward to the next test (0x0050CF73..0x0050CFA4).
'  * Branch 3 is `ElseIf a0 <> 0` -- the `je` at 0x0050D020 targets the IsEmpty arm,
'    so the a0 = 0 case is the final Else.
'  * `Exit` in the last loop and the loop's normal end share one target (0x0050D119)
'    because nothing follows the loop in that branch.
'  * Both log lines are the left-associative `+` form (concat with the literal first),
'    not `:+` -- guide 16.1. All four literals read out of NSS5.exe.
'  * `anyplayed` is register-allocated (edi); `found`, `complete` and `anyunplayed`
'    are the three slots of `sub esp,0xc`.

Method IsComplete:Int(a0:Int)
	LogLine("IsComplete: " + Self.id + " " + Self.name)
	Local found:Int = 0
	Local complete:Int = 1
	If Self.comptype = 2 Or Self.comptype = 3 Or Self.comptype = 5
		found = 1
		For Local pp:TPromotionPlace = EachIn Self.lplacesthatpromotetome
			If TCompetition.SelectById(pp.parentid).IsComplete(1) = 0
				complete = 0
			End If
		Next
	ElseIf a0 <> 0
		Local anyplayed:Int = 0
		Local anyunplayed:Int = 0
		For Local f:TFixture = EachIn Self.lfixturelist
			found = 1
			If f.result = 1
				anyplayed = 1
			Else
				anyunplayed = 1
			End If
		Next
		If anyplayed And anyunplayed Then complete = 0
	Else
		If Self.lfixturelist.IsEmpty() = 0
			found = 1
			For Local f:TFixture = EachIn Self.lfixturelist
				If f.result = 0
					complete = 0
					Exit
				End If
			Next
		End If
	End If
	If found = 0 Or complete = 1
		LogLine(Self.id + ": " + Self.name + "  Complete")
		Return 1
	Else
		LogLine(Self.id + ": " + Self.name + "  Not Complete")
		Return 0
	End If
End Method

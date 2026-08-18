' TFixture.GetStringArray
' VA 0x004C31CB   1231 bytes   mode=reloc   byte-identical vs NSS5.exe (1231/1231, reloc_masked=91)
' Verified under NSS5_NO_LEARN=1 -- nothing was masked by a helper name this probe taught.
' KIND=Method, SIG (i)[]$, class-table slot 0x44
'
' NOTES
'   New String[5] -- element-type descriptor 0x00C70D8C passed to bbArrayNew1D.
'   The result-type cascade IS a Select (all four Case compares emitted back to back at
'   +0x10F..+0x125 with every target past the last compare, codegen-patterns 10.2); Case 1
'   has an EMPTY body and emits only the jump to End Select.
'   The "(aet)/(pens)/(a.g.)" marker is PREFIXED when the home side is ahead and SUFFIXED
'   otherwise -- the two branches differ only in operand ORDER, which is byte-observable via
'   the argument-evaluation order (16.2): the rightmost operand of a concat chain is
'   evaluated first.
'   Self.GetFirstLegScore has reflection sig (*i,*i)i so the probe declares Int Ptr; Varptr
'   emits the same `lea edx,[ebp-N] / push edx` the original does.
'   [ebp-4] is the FIRST out-parameter and [ebp-8] the second (push order proves it), so the
'   aggregate pairs Self.score1 with fs2 and Self.score2 with fs1.
'   String literals read out of NSS5.exe with harness.read_string at the addresses the
'   original pushes at the same code offsets.
Local arr:String[] = New String[5]
arr[0] = TMyDate.Create(Self.sdate, 1, 1).GetString("YY-WW-DDD")
arr[1] = Self.GetStringHomeTeam()
arr[3] = Self.GetStringAwayTeam()
Local s:String = GetText("sla_versus")
Local fs1:Int = 0
Local fs2:Int = 0
If Self.leg = 2 Then Self.GetFirstLegScore(Varptr fs1, Varptr fs2)
If Self.result <> 0
	s = Self.score1 + " - " + Self.score2
	Select Self.resulttype
		Case 1
		Case 2
			If Self.score1 > Self.score2
				s = GetText("sla_extratime") + Self.score1 + " - " + Self.score2
			Else
				s = Self.score1 + " - " + Self.score2 + GetText("sla_extratime")
			End If
		Case 3
			If Self.penscore1 > Self.penscore2
				s = GetText("sla_penalty") + Self.score1 + " - " + Self.score2
			Else
				s = Self.score1 + " - " + Self.score2 + GetText("sla_penalty")
			End If
		Case 4
			If fs2 * 2 + Self.score1 > fs1 + Self.score2 * 2
				s = GetText("sla_awaygoals") + Self.score1 + " - " + Self.score2
			Else
				s = Self.score1 + " - " + Self.score2 + GetText("sla_awaygoals")
			End If
	End Select
End If
arr[2] = s
If Self.leg = 2 And Self.result
	arr[4] = GetText("tla_Aggregate") + " " + (Self.score1 + fs2) + "-" + (Self.score2 + fs1)
Else
	If Self.matchtype = 3 And Self.round = 2
		arr[4] = GetText("Replay")
	ElseIf Self.leg > 0
		arr[4] = GetText("Leg") + " " + Self.leg
	ElseIf Self.groupno > 0 And a0
		arr[4] = GetText("Group") + " " + Self.groupno
	End If
End If
Return arr

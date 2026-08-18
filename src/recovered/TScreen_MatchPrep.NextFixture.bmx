' TScreen_MatchPrep.NextFixture
' VA 0x0055F262   652 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i)i, slot 0x54
' ASSUMPTIONS
'  * Global 0x00C6F028 g_profile:TProfile (typed from its construction site).
'  * The opening GetStat call's result is assigned to a DEAD Int Local. Written as a
'    bare expression statement the body is 640 bytes (12 short) -- the `Local` is what
'    emits the Float->Int conversion (_bbFloatToInt at 0x0055F288). The Local never
'    reaches the stack (the prologue has no `sub esp`), so it costs nothing else.
'  * The fixture-level branch is a SELECT (cmp 0/je, cmp 1/je, jmp at 0x0055F2BE).
'  * `If a0 <> 0 ... Else ...` -- the `je` at 0x0055F293 targets the PlayNextFixture(0)
'    arm, so the zero case is the ELSE, not the THEN.
'  * The four `-n` arguments are emitted `mov eax,ebx / neg eax`, and the LAST one
'    reuses ebx directly (`neg ebx`); that is register allocation, not a source
'    difference.
'  * Both news-key literals read out of NSS5.exe.

'!Global g_profile:TProfile

Function NextFixture:Int(a0:Int)
	Local dummy:Int = g_profile.GetStat(12, 3, 0, 0)
	If a0 <> 0
		If g_profile.selectedformatch > 0
			Select g_profile.GetNextFixture(0).level
				Case 0
					g_profile.bank = g_profile.bank - g_profile.contractwage
					If g_profile.bank < 0 Then g_profile.bank = 0
					g_profile.UpdateRelationship(1, -15)
					g_profile.UpdateRelationship(2, -10)
					g_profile.UpdateRelationship(3, -10)
					g_profile.UpdateRelationship(7, -5)
					g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_SKIPMATCHCLUB"), g_profile.myclub, Null, 0, 0)
				Case 1
					g_profile.UpdateRelationship(3, -15)
					g_profile.UpdateRelationship(7, -5)
					g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_SKIPMATCHINTERNATIONAL"), g_profile.mynation, Null, 0, 0)
			End Select
		ElseIf g_profile.selectedformatch = -7
			Local n:Int = 5
			If g_profile.matchskipped <> 0 Then n = 10
			g_profile.UpdateRelationship(1, -n)
			g_profile.UpdateRelationship(2, -n)
			g_profile.UpdateRelationship(3, -n)
			g_profile.UpdateRelationship(7, -n)
		End If
		g_profile.PlayNextFixture(1)
	Else
		g_profile.PlayNextFixture(0)
	End If
End Function

' TTeam.SelectRandomPlayer
' VA 0x004E1F20   627 bytes   vtable slot 0x9c   sig (i,i,i,i):TPlayer
' byte-identical vs NSS5.exe (627/627, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C6F028 g_contractoffer_tplayer:TProfile, field +0x16C injury
'   TPlayer +0x08 newstar, +0xBC selectionno, +0x188 matchstats:TStats_Match
'   TStats_Match +0x10 reds, +0x20 subbedofftime
'   0x0059F089 = _brl_random_Rand
' `If p.newstar And ...` is load-bearing: `<> 0` adds setne/movzx/cmp (9 bytes) per site
' and made the body 645. The three `Then Continue` guards each emit 74 02 / EB xx.
	Method SelectRandomPlayer:TPlayer(a0:Int, a1:Int, a2:Int, a3:Int)
		'!Global g_profile:TProfile
		Local ok:Int
		Local r:Int
		Repeat
			ok = 1
			r = Rand(0, 10)
			If r = 0 And a0 = 0 Then ok = 0
			If r > 0 And r < 5 And a1 = 0 Then ok = 0
			If r > 4 And r < 9 And a2 = 0 Then ok = 0
			If r > 8 And r < 11 And a3 = 0 Then ok = 0
		Until ok
		For Local p:TPlayer = EachIn Self.squad
			If p.selectionno = r And p.matchstats <> Null
				If p.newstar And g_profile.injury > 0 Then Continue
				If p.matchstats.subbedofftime > 0 Then Continue
				If p.matchstats.reds > 0 Then Continue
				Return p
			End If
		Next
		Repeat
			r = Rand(10)
			For Local p:TPlayer = EachIn Self.squad
				If p.selectionno = r And p.matchstats <> Null
					If p.newstar And g_profile.injury > 0 Then Continue
					If p.matchstats.subbedofftime > 0 Then Continue
					If p.matchstats.reds > 0 Then Continue
					Return p
				End If
			Next
		Forever
	End Method

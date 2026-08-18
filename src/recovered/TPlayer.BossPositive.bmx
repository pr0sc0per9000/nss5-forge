' TPlayer.BossPositive
' VA 0x005036fb   164 bytes   vtable slot 0x238   sig ()i
' byte-identical vs NSS5.exe (164/164, original length from Ghidra's inventory)
' assumptions: module Global 0x00c6f028 declared TProfile (globals_final, construction
'              site, 3 witnesses, high confidence). Field offsets confirm it:
'              +0x10 date:TMyDate, +0x20 clubid, +0x104 relationboss.
'              Slots: TMyDate+0x54 = GetYear()i, TProfile+0x88 = GetStat(i,i,i,i)f.
'              Float constant at 0x00c7b840 is 5.0.
' NOTE: the first test accumulates (`add esi,1`), it is not `n = 1`; declaring
'       `Local n:Int = (GetYear()=1)` gives a setcc and comes out 2 bytes short.
'       GetYear() is called TWICE -- bcc does no CSE, and the original source did not
'       hoist it into a Local either.
	Method BossPositive:Int()
		'!Global g_profile:TProfile
		Local n:Int = 0
		If g_profile.date.GetYear() = 1 Then n = n + 1
		If g_profile.GetStat(12,3,g_profile.clubid,g_profile.date.GetYear()) < 5.0 Then n = n + 1
		If g_profile.relationboss < 50 Then n = n - 1
		If Self.matchstats.rating < 50 Then n = n - 1
		Return n > 0
	End Method

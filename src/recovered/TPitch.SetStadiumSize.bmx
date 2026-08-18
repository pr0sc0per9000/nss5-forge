' TPitch.SetStadiumSize
' VA 0x004e5f63   177 bytes   vtable slot 0x38   sig (i,i)i
' byte-identical vs NSS5.exe (177/177, original length from Ghidra's inventory)
' Assumptions: module Global at 0x00c6f028 declared TProfile (name ours; proved by
'   .date:TMyDate at +0x10 and GetStat at slot 0x88), and 0x00c5d69c / 0x00c5d624 /
'   0x00c5d62c / 0x00c5d630 declared Int.
' The band test must be written high-first (>= 20000 ...) -- the low-first cascade compiles
' to jge/jl in the opposite order and misses 59 bytes at the same length.
' g_profile.date.GetYear() is written twice on purpose: bcc does no CSE and the original
' calls it twice.
	Function SetStadiumSize(a0:Int, a1:Int)
		'!Global g_profile:TProfile
		'!Global g_stadiumsize:Int
		'!Global g_pitch05:Int
		'!Global g_pitch06:Int
		'!Global g_pitch07:Int
		If a0 >= 20000
			g_stadiumsize = 3
		ElseIf a0 >= 10000
			g_stadiumsize = 2
		ElseIf a0 >= 5000
			g_stadiumsize = 1
		Else
			g_stadiumsize = 0
		EndIf
		g_pitch05 = a1
		g_pitch06 = (a0 + g_profile.date.GetYear()) Mod 3
		g_pitch07 = (a0 + g_profile.date.GetYear()) Mod 6
	End Function

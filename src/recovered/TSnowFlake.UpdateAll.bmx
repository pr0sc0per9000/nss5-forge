' TSnowFlake.UpdateAll  (KIND=Function -- static; a0 is the "snowing" flag, NOT Self)
' VA 0x0050567F   463 bytes   sig (i)i
' byte-identical vs NSS5.exe (463/463, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS.
'   `If a0` (mov eax,edx / cmp eax,0 / je, 7 bytes) -- `If a0 <> 0` is 14 and overshoots.
'   The wind If/Else pairs are INVERTED relative to Ghidra's rendering: bcc emits the
'   complement of the source condition as the setcc, so `setbe` means the source said
'   `> 0.1` with the subtract as the THEN branch.
'   Rnd's two arguments are qword constants; their values are masked by relocation, so
'   the pair 0.001 / 0.005 is read off the .rdata pool, not proved by the match.
'!Global g_snow_alpha:Float
'!Global g_snow_wind:Float
'!Global g_snow_winddir:Int
'!Global g_snow_windspeed:Float
'!Global g_snowflakes:TList
If a0 And g_snow_alpha < 1.0 Then g_snow_alpha :+ 0.01
If a0 = 0 And g_snow_alpha > 0.0 Then g_snow_alpha :- 0.01
If g_snow_winddir = 0
	If g_snow_wind > 0.1
		g_snow_wind :- g_snow_windspeed
	Else
		g_snow_winddir = 1
		g_snow_windspeed = Rnd(0.001, 0.005)
	EndIf
ElseIf g_snow_wind < 2.0
	g_snow_wind :+ g_snow_windspeed
Else
	g_snow_winddir = 0
	g_snow_windspeed = Rnd(0.001, 0.005)
EndIf
If Rand(1, 1000) = 1
	If g_snow_winddir = 1
		g_snow_winddir = 0
	Else
		g_snow_winddir = 1
	EndIf
EndIf
For Local s:TSnowFlake = EachIn g_snowflakes
	s.Update()
Next

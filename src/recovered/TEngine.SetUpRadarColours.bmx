' TEngine.SetUpRadarColours  -- KIND=Function (STATIC method on TEngine), slot 0x44, sig ()i
' VA 0x004CF11D   417 bytes   (original length from Ghidra's inventory)
' ORACLE: MATCH mode=reloc  417/417  reloc_masked=43
' byte-identical vs NSS5.exe
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_004A6A30 = _bbStringCompare (the `=` between two String Globals)
'   FUN_004A8590 = the GC free from inlined BBRELEASE -- never written in source
'   Globals (names ours, TYPES are load-bearing):
'     0x00C5B218 -> g_team_home:TTeam   0x00C5B21C -> g_team_away:TTeam
'       globals_final.tsv types 0x00C5B218 as TKit with a flagged construction-site
'       CONFLICT (TKit=2;TTeam=1). It is TTeam: the access chain is
'       [g+0x2C] -> [+0x10] -> [+0x1C], i.e. TTeam.kitplayer(+0x2C) . TKit.newcol(+0x10)
'       . BBArray data(+0x18) + 4  =  newcol[1].  TKit has no +0x2C field at all.
'     0x00C5B2A8 -> g_radarcol_home:String   0x00C5B2AC -> g_radarcol_away:String
'       globals_final.tsv calls both Int ('dword int access'). WRONG per §11.2 -- every
'       store carries full retain (inc [ebx+4]) / release (dec [eax+4] + bbGCFree)
'       traffic, and they are passed to _bbStringCompare. They are Strings.
'   Array indices: BBArray data starts at +0x18, so [+0x1C]=newcol[1], [+0x28]=newcol[4],
'   [+0x34]=newcol[7].
'   String literals read out of NSS5.exe BBString headers:
'       0x00C73C30 = "555555"   0x00C5D680 = "FFFFFF"
'
' NOTE (faithful, not a transcription slip): the FOURTH test re-assigns g_radarcol_away
' from g_team_away.kitplayer.newcol[1] -- the same expression as the second statement, so
' it can never change the outcome. The original really does this (0x004CF1D1 loads
' [0x00C5B21C] and reads +0x1C, byte-identical to 0x004CF14B). Preserved as-is.
	Function SetUpRadarColours:Int()
		'!Global g_radarcol_home:String
		'!Global g_team_home:TTeam
		'!Global g_radarcol_away:String
		'!Global g_team_away:TTeam
		g_radarcol_home = g_team_home.kitplayer.newcol[1]
		g_radarcol_away = g_team_away.kitplayer.newcol[1]
		If g_radarcol_home = g_radarcol_away Then g_radarcol_home = g_team_home.kitplayer.newcol[4]
		If g_radarcol_home = g_radarcol_away Then g_radarcol_away = g_team_away.kitplayer.newcol[1]
		If g_radarcol_home = g_radarcol_away Then g_radarcol_away = g_team_away.kitplayer.newcol[7]
		If g_radarcol_home = g_radarcol_away Then g_radarcol_away = "555555"
		If g_radarcol_home = g_radarcol_away Then g_radarcol_home = "FFFFFF"
		Return 0
	End Function

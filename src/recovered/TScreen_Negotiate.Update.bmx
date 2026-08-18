' TScreen_Negotiate.Update
' VA 0x0057A7E8   584 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (584/584, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only.
' Global types read off the call sites: arr02 elements take SetIcon (slot 0x90) and
' SetColour (slot 0x6c) => TButton[]; arr01 is the SetIcon argument => TImage[];
' arr03 is a plain Int[] index table. 0x00C6C550 / 0x00C6F090 are the PlaySound
' sound/channel pair (globals_final types both 'Object', low confidence).
'!Global g_screen_negotiate_arr01:TImage[]
'!Global g_screen_negotiate_arr02:TButton[]
'!Global g_screen_negotiate_arr03:Int[]
'!Global g_screen_negotiate_int02:Int
'!Global g_screen_negotiate_int03:Int
'!Global g_screen_negotiate_int04:Int
'!Global g_player_int50:Int
'!Global g_Object770:TSound
'!Global g_Object859:TChannel
'!Global g_Object782:TButton
'!Global g_Object783:TButton
'!Global g_Object786:TButton
If g_screen_negotiate_int02 > 1 And g_screen_negotiate_int04 <> 0 And g_player_int50 > g_screen_negotiate_int03 + 500 Then
	g_screen_negotiate_arr02[g_screen_negotiate_int02].SetIcon(g_screen_negotiate_arr01[g_screen_negotiate_arr03[g_screen_negotiate_int02]])
	If (g_screen_negotiate_arr03[g_screen_negotiate_int02] < g_screen_negotiate_arr03[g_screen_negotiate_int02-1] And g_screen_negotiate_int04 = -1) Or (g_screen_negotiate_arr03[g_screen_negotiate_int02] > g_screen_negotiate_arr03[g_screen_negotiate_int02-1] And g_screen_negotiate_int04 = 1) Then
		g_screen_negotiate_int04 = 0
		g_screen_negotiate_arr02[g_screen_negotiate_int02].SetColour("00FF00","FFFFFF")
		PlaySound(g_Object770, g_Object859)
		TScreen_Negotiate.UpdateInstrucs()
	Else
		g_screen_negotiate_int04 = 0
		g_screen_negotiate_arr02[g_screen_negotiate_int02].SetColour("FF0000","FFFFFF")
		TScreen_Negotiate.Fail()
		Return 0
	EndIf
	If g_screen_negotiate_int02 = 5 Then TScreen_Negotiate.Success()
EndIf
If g_screen_negotiate_int02 < 5 And g_Object782.alive = 0 And g_player_int50 > g_screen_negotiate_int03 + 1000 Then
	g_Object782.alive = 1
	g_Object782.SetAlph(1.0)
	g_Object783.alive = 1
	g_Object783.SetAlph(1.0)
	If g_screen_negotiate_int02 > 1 Then
		g_Object786.alive = 1
		g_Object786.SetAlph(1.0)
	EndIf
EndIf

' TScreen_Dilemma.Draw
' VA 0x00557d8c   134 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory, mode=reloc)
' Assumptions: two module Globals 0x00C68064/0x00C68068 declared :TImage (typed Object
' in globals_final.tsv; the DrawImageRect call sites fix them as images).
' FUN_00506456 is the verified module Function SetDrawStateHex($,f,f,f,i)i and
' FUN_005AD7C8 is _brl_max2d_DrawImageRect.
' VERIFIED: the colour string was flagged as a placeholder; harness.read_string(0x00C5D680) confirms "FFFFFF" exactly. No change needed.
	Function Draw:Int()
		'!Global g_dil_img1:TImage
		'!Global g_dil_img2:TImage
		SetDrawStateHex("FFFFFF",1.0,1.0,0,3)
		If g_dil_img1 <> Null Then DrawImageRect(g_dil_img1,0,50,400,440,0)
		If g_dil_img2 <> Null Then DrawImageRect(g_dil_img2,400,50,400,440,0)
	End Function

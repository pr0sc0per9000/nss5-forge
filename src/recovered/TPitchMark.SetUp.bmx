' TPitchMark.SetUp  -- KIND=Function (static method on TPitchMark, no implicit Self)
' VA 0x004EA150   118 bytes   sig ()i   slot 0x30
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=11)
'
' ASSUMPTIONS
'   Globals (names are ours; module Globals have no debug record):
'     0x00C5D9B0 -> g_pitchmark_image:TImage   (retain/release traffic => reference; the
'                   value stored is LoadAnimImageChecked's return, i.e. a TImage)
'     0x00C5D9AC -> g_pitchmarks:TList         (retain/release traffic; CreateList())
'   FUN_004BC664 = LoadAnimImageChecked (src/recovered_module/LoadAnimImageChecked.bmx)
'   FUN_005AE38D = _brl_max2d_MidHandleImage
'   FUN_005B40BF = alias set CreateList|CreateMap|TGNetHost.Create -- CreateList chosen
'                   (the Global is later enumerated as a list of pitch marks)
'   String literal read from the exe at 0x00C788C4 via harness.read_string:
'     "EngineMedia/Match/Pitch/Patch.png"
'!Global g_pitchmark_image:TImage
'!Global g_pitchmarks:TList
	Function SetUp()
		g_pitchmark_image = LoadAnimImageChecked("EngineMedia/Match/Pitch/Patch.png",64,64,0,2,-1)
		MidHandleImage(g_pitchmark_image)
		g_pitchmarks = CreateList()
	End Function

' TPhotographer.SetUp
' VA 0x004EA47D   443 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (443/443, original length from Ghidra's inventory, reloc_masked=41)
'
' ASSUMPTIONS
'   0x00C5DB1C g_Object77:TList  (globals_final 'Object, low'; CreateList() result)
'   0x00C5DB28 g_photographer_arr:TImage[]  (elements are LoadAnimImageChecked results)
'   0x00C5DB2C/30/34/38 g_photographer_int01..04:Int  (bbFloatToInt results)
'   0x42000000=32.0, 0x42E00000=112.0, 0x461C4000=10000.0, 0x50=80, 0x70=112.
'!Global g_Object77:TList
'!Global g_photographer_arr:TImage[]
'!Global g_photographer_int01:Int
'!Global g_photographer_int02:Int
'!Global g_photographer_int03:Int
'!Global g_photographer_int04:Int
g_Object77 = CreateList()
g_photographer_arr[0] = LoadAnimImageChecked("EngineMedia/Match/Pitch/Photographer.png",80,112,0,6,-1)
g_photographer_arr[1] = LoadAnimImageChecked("EngineMedia/Match/Pitch/Photographer.png",80,112,6,6,-1)
g_photographer_arr[2] = LoadAnimImageChecked("EngineMedia/Match/Pitch/Photographer.png",80,112,12,6,-1)
For Local i:Int = 0 To 2
	SetImageHandle(g_photographer_arr[i],32.0,112.0)
Next
g_photographer_int01 = Int(ReadSettingFloat("incbin::Inc/Engine.ini","camerax1",0,10000.0))
g_photographer_int02 = Int(ReadSettingFloat("incbin::Inc/Engine.ini","cameray1",0,10000.0))
g_photographer_int03 = Int(ReadSettingFloat("incbin::Inc/Engine.ini","camerax2",0,10000.0))
g_photographer_int04 = Int(ReadSettingFloat("incbin::Inc/Engine.ini","cameray2",0,10000.0))

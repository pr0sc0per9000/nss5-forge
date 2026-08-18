' TCameraMan.SetUp
' VA 0x004EB2F6   398 bytes  mode=reloc  byte-identical vs NSS5.exe (398/398, length from Ghidra)
' KIND=Function, SIG ()i, slot 0x30
' ASSUMPTIONS
'  * Global g_cameramen:TList  (0x00C5DCA0) -- same type already used by TCameraMan.UpdateAll.
'  * Global g_cameraman_images:TImage[] (0x00C5DCAC) -- element stores at data+0x18/+0x1c with
'    full retain/release traffic, so the elements are heap references; SetImageHandle is
'    called on them, so TImage.
'  * Globals g_camerax1..g_cameray2 (0x00C5DCB0..0x00C5DCBC) are Int -- each ReadSettingFloat
'    result goes straight through _bbFloatToInt into a bare dword store.
'  * Literals read out of NSS5.exe; the 10000.0 default is 0x461C4000.

	Function SetUp:Int()
		'!Global g_cameramen:TList
		'!Global g_cameraman_images:TImage[]
		'!Global g_camerax1:Int
		'!Global g_cameray1:Int
		'!Global g_camerax2:Int
		'!Global g_cameray2:Int
		g_cameramen = CreateList()
		g_cameraman_images[0] = LoadAnimImageChecked("EngineMedia/Match/Pitch/CameraMan.png", 64, 128, 0, 3, -1)
		SetImageHandle(g_cameraman_images[0], 48, 96)
		g_cameraman_images[1] = LoadAnimImageChecked("EngineMedia/Match/Pitch/Camera.png", 64, 64, 0, 3, -1)
		SetImageHandle(g_cameraman_images[1], 16, 32)
		g_camerax1 = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "camerax1", 0, 10000))
		g_cameray1 = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "cameray1", 0, 10000))
		g_camerax2 = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "camerax2", 0, 10000))
		g_cameray2 = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "cameray2", 0, 10000))
	End Function

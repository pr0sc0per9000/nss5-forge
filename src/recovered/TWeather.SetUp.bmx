' TWeather.SetUp
' VA 0x00504F6D   165 bytes   vtable slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (165/165, original length from Ghidra's inventory, mode=reloc)
' Global names are ours: 0x00C600C8 g_rainImage:TImage, 0x00C600D0 g_rainSound:TSound,
' 0x00C600CC g_snowImage:TImage. The three asset paths were read out of NSS5.exe.
' The tail call goes through TSnowFlake's class table + 0x30, a DIFFERENT Type's table,
' so it keeps the Type prefix.
	Function SetUp()
		'!Global g_rainImage:TImage
		'!Global g_rainSound:TSound
		'!Global g_snowImage:TImage
		g_rainImage = LoadAnimImageChecked("EngineMedia/Match/Pitch/Rain.png", 64, 64, 0, 8, -1)
		g_rainSound = LoadSoundChecked("EngineMedia/Match/Sounds/Rain.ogg", 1)
		g_snowImage = LoadImageChecked("EngineMedia/Match/Pitch/Snow.png", -1)
		TSnowFlake.SetUp()
	End Function

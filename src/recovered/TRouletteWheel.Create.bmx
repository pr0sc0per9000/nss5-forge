' TRouletteWheel.Create
' VA 0x00575aa3   203 bytes   vtable slot 0x30   sig ():TRouletteWheel
' byte-identical vs NSS5.exe (203/203, original length from Ghidra's inventory)
' Globals: g_path:String (0x00c6e950 -- holds a String pointer, NOT the Int the table says),
'          g_wheel:TImage (0x00c6bcb4), g_wheelinner:TImage (0x00c6bcb8)
	Function Create:TRouletteWheel()
		'!Global g_wheel:TImage
		'!Global g_path:String
		'!Global g_wheelinner:TImage
		Local w:TRouletteWheel = New TRouletteWheel
		If Not g_wheel
			g_wheel = LoadImageChecked(g_path + "GameMedia/Images/Casino/Roulette/Wheel.png",-1)
			g_wheelinner = LoadImageChecked(g_path + "GameMedia/Images/Casino/Roulette/Wheel_Inner.png",-1)
			MidHandleImage(g_wheel)
			MidHandleImage(g_wheelinner)
		EndIf
		Return w
	End Function

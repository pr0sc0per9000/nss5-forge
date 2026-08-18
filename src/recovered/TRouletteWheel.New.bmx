' TRouletteWheel.New
' VA 0x00575A44   81 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (81/81, original length from Ghidra's inventory)
' Empty New body. The 81 bytes are the field initialisers bcc emits for every field;
' the four non-zero defaults are carried on the Field declarations:
'   Field iWheelSize:Int = 150 / iRimSize:Int = 270 / fX:Float = 180.0 / fY:Float = 300.0
' (float constants read from .data at 0x00c90a14 / 0x00c90a18).
	Method New()
		'!Field iWheelSize = 150
		'!Field iRimSize = 270
		'!Field fX = 180.0
		'!Field fY = 300.0
	End Method

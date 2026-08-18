' TSnowFlake.ResetAll
' VA 0x00505975   177 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (177/177, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals -- names ours, declared types load-bearing):
'   * 0x00C60238 : Float (globals_final, x87 dword access, high) -- zeroed with fldz/fstp.
'   * 0x00C60220 : TList -- globals_final says `Object` (low); the loop is the standard
'     ObjectEnumerator/HasNext/NextObject shape and the downcast class table is
'     0x00C603D4 = TSnowFlake.
'   * 0x00C6EFE8 : Int. globals_final says Int and the original agrees -- it is read with
'     mov/mov/fild, not fld, so it is an integer converted to Float at the subtraction.
'     Declaring it Float loses 5 bytes (170/177).
'   * 0x00C6EFE4 : Int.
'   * -5.0 is the .rdata float constant at 0x00C7BB70 (0xC0A00000).
'   * fields x +0x08, y +0x0C (object_model.json); Rand = 0x0059F089.
	'!Global g_snow_f03:Float
	'!Global g_snowlist:TList
	'!Global g_snow_fall:Int
	'!Global g_snow_wid:Int
	Function ResetAll:Int()
		g_snow_f03 = 0
		For Local s:TSnowFlake = EachIn g_snowlist
			If s.y > -5.0
				s.y = s.y - g_snow_fall
				s.x = Rand(0, g_snow_wid)
			EndIf
		Next
	End Function

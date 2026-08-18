' TPole.Update
' VA 0x005839DA   118 bytes   vtable slot 0x38
' byte-identical vs NSS5.exe
' Requires the emit_type inherited-slot padding fix; without it the harness reports 117/118 because CheckHit lands at vtable 0x50 instead of 0x4C.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method Update:Int()
		CheckHit()
		If wobbling > 0
			wobbling = wobbling + 1
			Local f:Int = wobbling Mod 20
			If f < 5
				frame = 0
			ElseIf f < 10
				frame = 1
			ElseIf f < 15
				frame = 0
			Else
				frame = 2
			EndIf
			If wobbling > 60
				wobbling = 0
				frame = 0
			EndIf
		EndIf
	End Method

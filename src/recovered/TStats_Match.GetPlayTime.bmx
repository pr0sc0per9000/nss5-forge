' TStats_Match.GetPlayTime
' VA 0x0056E82B   62 bytes   vtable slot 0x4C
' byte-identical vs NSS5.exe
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method GetPlayTime:Int(a0:Int)
		If subbedontime > -1
			If subbedofftime > -1
				a0 = subbedofftime - subbedontime
			Else
				a0 = a0 - subbedontime
			EndIf
		ElseIf subbedofftime > -1
			If subbedofftime = 0
				a0 = 1
			Else
				a0 = subbedofftime
			EndIf
		EndIf
		Return a0
	End Method

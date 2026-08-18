' TMyGfxModes.Compare
' VA 0x00506d80   98 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory)
' tie-break is Super.Compare (bbObjectCompare); the operand order here is the mirror of TButtonPos.Compare - both were verified separately
	Method Compare:Int(a0:Object)
		If a0 = Self
			Return 0
		Else
			If w > TMyGfxModes(a0).w
				Return 1
			ElseIf w < TMyGfxModes(a0).w
				Return -1
			Else
				Return Super.Compare(a0)
			EndIf
		EndIf
	End Method

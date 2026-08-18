' TDrawOb.Compare
' VA 0x004CD87F   276 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (276/276, original length from Ghidra's inventory)
' The downcast MUST be the LEFT operand of every comparison. Writing it on the
' right ('y > TDrawOb(a0).y') makes bcc spill the x87 value across the downcast
' call and emit a 'sub esp,0x10' prologue the original does not have (+19 bytes).
	Method Compare:Int(a0:Object)
		If TDrawOb(a0).level < level
			Return 1
		ElseIf TDrawOb(a0).level > level
			Return -1
		ElseIf TDrawOb(a0).y < y
			Return 1
		ElseIf TDrawOb(a0).y > y
			Return -1
		ElseIf TDrawOb(a0).z < z
			Return 1
		ElseIf TDrawOb(a0).z > z
			Return -1
		Else
			Return Super.Compare(a0)
		EndIf
	End Method

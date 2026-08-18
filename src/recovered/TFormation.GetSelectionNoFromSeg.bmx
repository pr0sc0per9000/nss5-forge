' TFormation.GetSelectionNoFromSeg
' VA 0x004d8a4f   85 bytes   vtable slot 0x44   sig (i,i)i
' byte-identical vs NSS5.exe (85/85, original length from Ghidra's inventory)
' The early-return form below is load-bearing. Ending the loop with
'   If m_TacPos[a0] <> 1 Then no = -1
'   Return no
' is 83 bytes -- it emits `74 05` where the original has `75 02 EB 07`.
' Parameter names are harness placeholders; not recoverable from the binary.

	Method GetSelectionNoFromSeg:Int(a0:Int, a1:Int)
		Local no:Int = 0
		If a1 = -1 Then a0 = 34 - a0
		For Local i:Int = 0 To a0
			If m_TacPos[i] = 1 Then no :+ 1
		Next
		If m_TacPos[a0] = 1 Then Return no
		Return -1
	End Method

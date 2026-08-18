' TScreenMessage.DrawAll
' VA 0x0056ff7a   210 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (210/210, original length from Ghidra's inventory, mode=reloc)
' Assumptions: module Global 0x00C6AFDC is :TList (slot 0x8c ObjectEnumerator).
' The guard is the Not-form EARLY RETURN (setne/movzx/cmp/jne) -- as an enclosing
' If-block it comes out 195 bytes. The null test Ghidra shows inside the loop is the
' one For..EachIn emits for itself; do not write it.
' FUN_005AE0A8 is _brl_max2d_SetScale, FUN_005ADC28 is _brl_max2d_SetAlpha.
	Function DrawAll:Int()
		'!Global g_screenmessages:TList
		If Not g_screenmessages Then Return 0
		SetScale(1.0,1.0)
		Local y:Int = 0
		For Local m:TScreenMessage = EachIn g_screenmessages
			If m.starttime < y
				m.starttime = y + 250
				m.finishtime = y + 250 + m.delaytime
			EndIf
			m.Draw()
			y = m.finishtime
		Next
		SetAlpha(1.0)
	End Function

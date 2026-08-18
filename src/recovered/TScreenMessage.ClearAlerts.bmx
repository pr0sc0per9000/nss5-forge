' TScreenMessage.ClearAlerts
' VA 0x00570593   198 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (198/198, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6AFDC declared TList (ObjectEnumerator slot 0x8c at its call site).
'   Loop downcast class table is TScreenMessage. Guard is the 21-byte "If Not x" emission
'   (setne/movzx/cmp/jne) used as an EARLY RETURN, not an enclosing If-block; the plain
'   "If g <> Null" block form is 15 bytes shorter and was rejected.
'   PTR_PTR_00C5D284 is the empty string constant, so the message field is set to "".
	Function ClearAlerts:Int()
		'!Global g_messages:TList
		If Not g_messages Then Return 0
		LogLine("TScreenMessage.ClearAlerts")
		For Local m:TScreenMessage = EachIn g_messages
			If m.lbl <> Null
				m.finishtime = 0
				m.starttime = 0
				m.message = ""
			EndIf
		Next
	End Function

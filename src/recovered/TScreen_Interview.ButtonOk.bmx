' TScreen_Interview.ButtonOk
' VA 0x0057becd   34 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' assumes module global at 0x00C6CDE8 typed String (holds the screen to return to)
' Class table 0x00C61C88 = TScreen + 0x5c = SetActive($,$):TScreen.
	Function ButtonOk:Int()
		'!Global g_interview_ret:String
		TScreen.SetActive(g_interview_ret,"")
	End Function

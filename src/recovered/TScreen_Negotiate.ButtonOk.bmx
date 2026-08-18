' TScreen_Negotiate.ButtonOk
' VA 0x0057acd9   33 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (33/33, original length from Ghidra's inventory)
' string literals read directly out of NSS5.exe's data section
	Function ButtonOk:Int()
		TScreen.SetActive("contractoffer","")
	End Function

' TScreen_Controls.ButtonBack
' VA 0x00523872   39 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (class tables, string constants) differ by
'   construction between probe and NSS5.exe; the emitted code is identical.
' assumptions: PTR_FUN_00c5d564 = TOptions classtable + 0x4c = TOptions.LoadOptions;
'   PTR_FUN_00c61c88 = TScreen classtable + 0x5c = TScreen.SetActive($,$):TScreen.
'   String constants read from the image: 0x00c7ef70 = "options", 0x00c5d284 = "".
	Function ButtonBack:Int()
		TOptions.LoadOptions()
		TScreen.SetActive("options","")
	End Function

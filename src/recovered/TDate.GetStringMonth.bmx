' TDate.GetStringMonth
' VA 0x005370C4   216 bytes   vtable slot 0x5c   sig (i,i)$   KIND=Function (static)
' byte-identical vs NSS5.exe (216/216, original length from Ghidra's inventory, mode=reloc)
' a0 = 1..12 month number; a1 = 0 asks for the 3-letter abbreviation.
' The twelve locale keys were read out of NSS5.exe as BlitzMax string objects, not guessed.
' Early-return form, not If/Else: the then-branch jmp lands on the epilogue and the trailing
' statement's own jmp is EB 00.
	Function GetStringMonth:String(a0:Int, a1:Int)
		Local m:String[] = ["date_January","date_February","date_March","date_April","date_May","date_June","date_July","date_August","date_September","date_October","date_November","date_December"]
		If a1 <> 0 Then Return GetText(m[a0-1])
		Return GetText(m[a0-1])[..3]
	End Function

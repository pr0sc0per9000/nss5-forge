' TCombo.SelectItemByLetter
' VA 0x005190E6   332 bytes   vtable slot 0xB4   sig (i)i
' byte-identical vs NSS5.exe (332/332, original length from Ghidra's inventory)

LogLine("SelectItemByLetter" + a0)
itemoffset = 0
selecteditem = 0
For Local b:TButton = EachIn buttons
	ScrollDown()
	If Upper(Left(b.txt, 1)) = Chr(a0) Or Lower(Left(b.txt, 1)) = Chr(a0) Then Return 0
Next
LogLine("Letter not in list")
itemoffset = 0
selecteditem = 1

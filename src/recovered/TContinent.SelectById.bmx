' TContinent.SelectById
' VA 0x00508f2f   130 bytes   vtable slot 0x40   sig (i):TContinent
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory)
' assumes module global:  Global g_continents:TList  (0x00c6080c)
' `If Not g_continents` is load-bearing.  `If g_continents = Null` compiles to the
' memory-immediate peephole (cmp [mem],imm / je) and comes out 9 bytes short; `Not`
' materialises the boolean (mov / cmp / setne / movzx / cmp eax,0 / jne), which is
' what the original does.

	Function SelectById:TContinent(a0:Int)
		'!Global g_continents:TList
		If Not g_continents Then Return Null
		For Local c:TContinent = EachIn g_continents
			If c.id = a0 Then Return c
		Next
		Return Null
	End Function

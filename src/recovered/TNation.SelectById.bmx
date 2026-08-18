' TNation.SelectById
' VA 0x004bec06   130 bytes   vtable slot 0x58   sig (i):TNation
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory)
' 0x00C596F0 : TList
' If Not <global> materialises the boolean (cmp/setne/movzx/cmp0) -- If g=Null / If g<>Null / If g all fold to a direct cmp and are 9 bytes short
' the cmp-against-Null on the loop variable is emitted by For..EachIn itself; no explicit null test in source
' Global: Global g_nations:TList
	Function SelectById:TNation(a0:Int)
		'!Global g_nations:TList
		If Not g_nations Then Return Null
		For Local n:TNation = EachIn g_nations
			If n.id = a0 Then Return n
		Next
		Return Null
	End Function

' ClampInt  -- module-level Function (no Type)
' VA 0x00505f6d   35 bytes   sig (*i,i,i)i
' byte-identical vs NSS5.exe (35/35, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. Clamps the Int pointed at by a0 into [a1, a2] in place. 12 game
' functions call it. The original signature almost certainly used a Var parameter
' (`v:Int Var`), which compiles identically to the Int Ptr form used here.
	Function ClampInt:Int(a0:Int Ptr, a1:Int, a2:Int)
		If a0[0] < a1 Then a0[0] = a1
		If a0[0] > a2 Then a0[0] = a2
	End Function

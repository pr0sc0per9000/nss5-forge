' ClampFloat  -- module-level Function (no Type)
' VA 0x00505f90   75 bytes   sig (*f,f,f)i
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. The Float twin of ClampInt: clamps the Float pointed at by a0 into
' [a1, a2] in place. 8 game functions call it. As with ClampInt the original almost
' certainly declared a Var parameter, which compiles identically to Float Ptr.
	Function ClampFloat:Int(a0:Float Ptr, a1:Float, a2:Float)
		If a0[0] < a1 Then a0[0] = a1
		If a0[0] > a2 Then a0[0] = a2
	End Function

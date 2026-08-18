' Dist2D  -- module-level Function (no Type)
' VA 0x00505da2   51 bytes   sig (f,f,f,f)f
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. Euclidean distance between (a0,a1) and (a2,a3). 6 game functions call it.
'
' CODEGEN NOTE -- the Locals are load-bearing, not style. Written as the single
' expression Sqr((a0-a2)*(a0-a2) + (a1-a3)*(a1-a3)) this compiles to 61 bytes, because
' bcc does no CSE and subtracts twice. With the Locals it is 51 bytes and exact: bcc
' keeps a Float Local that is consumed by the following expression on the x87 stack with
' no memory slot at all, and `dx*dx` on such a value emits `fmul st(0)` (D8 C8).
	Function Dist2D:Float(a0:Float, a1:Float, a2:Float, a3:Float)
		Local dx:Float = a0 - a2
		Local dy:Float = a1 - a3
		Return Sqr(dx*dx + dy*dy)
	End Function

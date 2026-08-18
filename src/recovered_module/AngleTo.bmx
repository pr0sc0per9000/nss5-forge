' AngleTo  -- module-level Function (no Type)
' VA 0x0050639d   111 bytes   sig (f,f,f,f)f
' byte-identical vs NSS5.exe (111/111, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 3 game functions call it. Bearing in degrees from (a0,a1) to (a2,a3),
' normalised into [0,360).
'
' The callee at 0x004A1F90 is not in runtime_helpers.tsv; it was identified by reading it
' -- two qword loads, fpatan, then a multiply by the qword at 0x00CD26A0, i.e. the
' radians-to-degrees conversion, so it is _bbATan2 and the arguments are Doubles.
' The .rdata constants were read out of NSS5.exe: 0x00C7BBB8 = 359.0, 0x00C7BBBC and
' 0x00C7BBC0 both 360.0.
'
' The Float Local never gets a memory slot -- bcc keeps it on the x87 stack across all
' three statements, which is why the two If tests are fucom/fxch/fstp rather than loads.
	Function AngleTo:Float(a0:Float, a1:Float, a2:Float, a3:Float)
		Local a:Float = ATan2(a3-a1, a2-a0)
		If a > 359.0 Then a = a - 360.0
		If a < 0.0 Then a = a + 360.0
		Return a
	End Function

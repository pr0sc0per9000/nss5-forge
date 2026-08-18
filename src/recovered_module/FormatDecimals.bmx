' FormatDecimals  -- module-level Function (no Type)
' VA 0x0050640c   74 bytes   sig (f,i)$
' byte-identical vs NSS5.exe (74/74, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 2 game functions call it. Renders a Float and truncates it a1 places after
' the decimal point; a1 = 0 is remapped to -1, which drops the point itself.
'
' The callee at 0x004A79D0 is not in runtime_helpers.tsv, so it was identified by reading
' it: it loads a Float off the stack, widens it to a qword and sprintf()s it against the
' format string at 0x00CD29E1 -- i.e. _bbStringFromFloat. That is what fixes a0 as Float
' rather than String. The separator pushed to Instr is the 1-char BlitzMax string object
' at 0x00C7BBC4, which decodes to ".".
'
' String(a0) is emitted twice because bcc does no CSE, and the original calls 0x004A79D0
' twice as well -- writing it through a Local would not match.
	Function FormatDecimals:String(a0:Float, a1:Int)
		If a1 = 0 Then a1 = -1
		Return Left(String(a0), Instr(String(a0), ".") + a1)
	End Function

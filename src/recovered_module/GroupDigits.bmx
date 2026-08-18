' GroupDigits  -- module-level Function (no Type)
' VA 0x00507474   274 bytes   sig (i)$
' byte-identical vs NSS5.exe (274/274, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=13, verified with NSS5_NO_LEARN=1 -- codegen-patterns 13.1)
'
' NAME IS OURS. Renders a0 as decimal and inserts thousands separators, by calling
' InsertString (0x00507586) at four FIXED offsets from the right rather than looping. The
' separator is the literal "," read out of the exe at 0x00C710FC.
'
' ORIGINAL BEHAVIOUR, reproduced as written (VA 0x00507474): the four guards are unrolled
' and stop at 15, so an input of more than 19 digits is under-separated. Int cannot reach
' that, so it is unreachable rather than wrong -- but it is the original's shape, not a
' loop, and it is written that way here on purpose.
'
' Blocker under FormatMoney (0x0050720B, gates 18), which could not be attempted until this
' function was recovered.
	Function GroupDigits:String(a0:Int)
		Local s:String = String(a0)
		If s.Length > 3
			InsertString(s, ",", s.Length - 3)
		End If
		If s.Length > 7
			InsertString(s, ",", s.Length - 7)
		End If
		If s.Length > 11
			InsertString(s, ",", s.Length - 11)
		End If
		If s.Length > 15
			InsertString(s, ",", s.Length - 15)
		End If
		Return s
	End Function

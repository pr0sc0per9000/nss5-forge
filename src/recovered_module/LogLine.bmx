' LogLine  -- module-level Function (no Type)
' VA 0x00505b91   58 bytes   sig ($)i
' byte-identical vs NSS5.exe (58/58, original length from Ghidra's inventory, mode=reloc)
'
' NAME AND GLOBAL NAME ARE OURS -- module-level Functions and Globals carry no debug
' record. 47 game functions call 0x00505B91. The global at 0x00C6EFF0 is called at
' vtable slot 0x90, which is TStream.WriteLine($)i, so it is an open log stream.
'!Global g_logstream:TStream
	Function LogLine:Int(a0:String)
		If g_logstream <> Null Then
			g_logstream.WriteLine(a0)
			Print a0
		End If
	End Function

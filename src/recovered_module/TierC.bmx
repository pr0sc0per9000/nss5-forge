' TierC  -- module-level Function (no Type)
' VA 0x00507c8f   139 bytes   sig (i)i
' byte-identical vs NSS5.exe (139/139, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. Third tier table indexed 1..10 (250 up to 50k).
' One of three same-shaped 139-byte siblings at 0x00507B79 / 0x00507C04 / 0x00507C8F that
' differ only in their ten constants; all three are exact.
'
' The compare chain is a Select with no Default: an unmatched value falls out of the
' Select into the function end, and bcc's implicit `mov eax,0 / jmp epilogue` supplies
' the 0. Writing a `Default Return 0` would be a second, separate statement.
	Function TierC:Int(a0:Int)
		Select a0
			Case 1
				Return 250
			Case 2
				Return 500
			Case 3
				Return 750
			Case 4
				Return 1000
			Case 5
				Return 2500
			Case 6
				Return 5000
			Case 7
				Return 7500
			Case 8
				Return 10000
			Case 9
				Return 25000
			Case 10
				Return 50000
		End Select
	End Function

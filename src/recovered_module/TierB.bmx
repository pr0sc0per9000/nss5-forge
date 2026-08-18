' TierB  -- module-level Function (no Type)
' VA 0x00507c04   139 bytes   sig (i)i
' byte-identical vs NSS5.exe (139/139, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. Second tier table indexed 1..10 (5k up to 10m).
' One of three same-shaped 139-byte siblings at 0x00507B79 / 0x00507C04 / 0x00507C8F that
' differ only in their ten constants; all three are exact.
'
' The compare chain is a Select with no Default: an unmatched value falls out of the
' Select into the function end, and bcc's implicit `mov eax,0 / jmp epilogue` supplies
' the 0. Writing a `Default Return 0` would be a second, separate statement.
	Function TierB:Int(a0:Int)
		Select a0
			Case 1
				Return 5000
			Case 2
				Return 10000
			Case 3
				Return 25000
			Case 4
				Return 50000
			Case 5
				Return 100000
			Case 6
				Return 250000
			Case 7
				Return 500000
			Case 8
				Return 1000000
			Case 9
				Return 5000000
			Case 10
				Return 10000000
		End Select
	End Function

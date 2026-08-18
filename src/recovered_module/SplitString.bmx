' SplitString  -- module-level Function (no Type)
' VA 0x005070dd   230 bytes   sig ($,$)[]$
' byte-identical vs NSS5.exe (230/230, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Splits a0 on the separator a1 into a String array, growing the array one
' element at a time with the `arr = arr[..n+1]` resize idiom. Uses brl.retro's Left/Right
' (0x0059C843 / 0x0059C866) rather than slices.
'
' FAMILY: SplitString2 (0x005062B7) is byte-for-byte the same body -- the two differ only in
' the address of the array type descriptor passed to _bbArrayNew1D, which is a per-site
' literal, not a semantic difference. Both verified from this one body.
'
' The loop is Repeat/Forever with a leading `If ... Exit`, NOT While/Wend: bcc puts a While
' test at the BOTTOM of the loop, which comes out one byte shorter (229 vs 230).
	Function SplitString:String[](a0:String, a1:String)
		Local arr:String[] = New String[1]
		Local s:String = a0
		Local n:Int = 0
		Repeat
			If s.Length = 0 Then Exit
			Local i:Int = s.Find(a1)
			If i = -1 Then
				arr[n] = s
				Exit
			End If
			arr[n] = Left(s, i)
			s = Right(s, s.Length - i - 1)
			n = n + 1
			arr = arr[..n+1]
		Forever
		Return arr
	End Function

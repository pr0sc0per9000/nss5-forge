' SplitString2  -- module-level Function (no Type)
' VA 0x005062b7   230 bytes   sig ($,$)[]$
' byte-identical vs NSS5.exe (230/230, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Byte-for-byte the same body as SplitString (0x005070DD) -- the source had
' two separate copies of the same splitter. The only difference between the two compiled
' bodies is the address of the array type descriptor handed to _bbArrayNew1D, which is a
' per-site literal, not a semantic difference; the same body verifies exact at both VAs.
'
' Splits a0 on the separator a1, growing the result with the `arr = arr[..n+1]` idiom and
' using brl.retro's Left/Right rather than slices. Repeat/Forever with a leading `If ... Exit`,
' NOT While/Wend: bcc puts a While test at the bottom, which is one byte shorter.
	Function SplitString2:String[](a0:String, a1:String)
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

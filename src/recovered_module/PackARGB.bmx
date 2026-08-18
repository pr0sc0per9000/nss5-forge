' PackARGB  -- module-level Function (no Type)
' VA 0x005071e5   38 bytes   sig (i,i,i,i)i
' byte-identical vs NSS5.exe (38/38, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. 13 call sites across 4 game functions (TTable.CreateTableImage,
' TCombo/TPanel image builders and the TScreen boot path). Packs four 0..255 channels
' into one BlitzMax ARGB pixel word for TPixmap.WritePixel.
'
' The parameter ORDER is read off the shifts, not guessed: [ebp+8] shifts left 16 (red),
' [ebp+0xc] shifts left 8 (green), [ebp+0x10] is not shifted (blue) and [ebp+0x14]
' shifts left 24 (alpha) -- so alpha is the LAST parameter, which is why every call site
' pushes 0xff first. The Or chain is emitted strictly left to right, so the source has to
' be written in that order too.
	Function PackARGB:Int(a0:Int, a1:Int, a2:Int, a3:Int)
		Return (a3 Shl 24) | (a0 Shl 16) | (a1 Shl 8) | a2
	End Function

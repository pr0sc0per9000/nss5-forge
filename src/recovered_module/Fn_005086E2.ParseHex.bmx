' ParseHex  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x005086e2   60 bytes   sig ($)i
' byte-identical vs NSS5.exe (60/60, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Parses a hexadecimal string. BlitzMax's Int() reads hex when the text starts with "$",
' so the whole body is "put a $ on the front if there is not one there already, then
' convert". The same "$"-prefix idiom is already verified in SetColourHex (0x00505CEA)
' and ParseColourHex (0x005064ED), which use the identical literal at 0x00C7529C.
'
' ITS ONE CALLER is URLDecode (0x005085FF), which is itself unrecovered and uncalled; see
' docs/reference/unrecovered-inventory.md. Found by the unrecovered-function audit.
'
'     005086E9  6A 00           push 0
'     005086EB  68 9C 52 C7 00  push 0x00C7529C       ; "$"
'     005086F0  53              push ebx              ; a0
'     005086F1  E8 ..           call 0x004A6B60       ; _bbStringFind(a0, "$", 0)
'     005086F9  83 F8 00        cmp eax, 0
'     005086FC  74 10           je  0050870E          ; already at index 0 -> skip
'     005086FE  53              push ebx
'     005086FF  68 9C 52 C7 00  push 0x00C7529C
'     00508704  E8 ..           call 0x004A7C20       ; _bbStringConcat("$", a0)
'     0050870E  53              push ebx
'     0050870F  E8 ..           call 0x004A7130       ; _bbStringToInt
'
' The guard is Find(...) <> 0, not StartsWith: Find returns -1 when the "$" is absent and
' 0 when it is already leading, so the one test covers both. Helper names come from
' extracted/runtime_helpers.tsv (_bbStringFind, _bbStringConcat, _bbStringToInt).
	Function ParseHex:Int(a0:String)
		If a0.Find("$") <> 0 Then a0 = "$" + a0
		Return Int(a0)
	End Function

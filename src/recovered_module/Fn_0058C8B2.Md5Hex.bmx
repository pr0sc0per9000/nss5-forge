' Md5Hex  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c8b2   174 bytes   sig (i)$
' byte-identical vs NSS5.exe (174/174, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Formats one 32-bit MD5 state word as eight lowercase hex digits in LITTLE-ENDIAN byte
' order, which is how an MD5 digest is written out. Called four times from the digest body
' at 0x0058BC02, once per state word. Part of the dead MD5 implementation described in
' Fn_0058C722.Md5F.bmx and in docs/reference/unrecovered-inventory.md.
'
' It builds the hex by hand rather than calling BRL.Retro's Hex(): the nibble loop reads
' the LOW nibble first and PREPENDS each digit, so the string comes out most-significant
' first; the four slices at the end then reverse the byte pairs.
'
'     0058C8D0  D3 E8           shr eax, cl           ; a0 Shr (i * 4)
'     0058C8D2  83 E0 0F        and eax, 0xF
'     0058C8D5  56              push esi              ; <- s pushed FIRST
'     0058C8D6  89 C2           mov edx, eax
'     0058C8D8  83 C2 30        add edx, 0x30         ; n + 48
'     0058C8DB  83 F8 09        cmp eax, 9
'     0058C8DE  0F 9F C0        setg al               ; (n > 9)
'     0058C8E4  6B C0 27        imul eax, eax, 0x27   ;   * 39
'     0058C8EA  E8 ..           call 0x004A7B50       ; _bbStringFromChar
'     0058C8F3  E8 ..           call 0x004A7C20       ; _bbStringConcat(chr, s)
'
' THE PUSH ORDER IS THE WHOLE EVIDENCE FOR THE PREPEND. cdecl puts the first argument at
' the lowest address, i.e. the LAST push, so `push esi` before the character is computed
' makes s the SECOND argument of bbStringConcat: chr + s, not s + chr. Written the natural
' way round (`s :+ Chr(...)`) the body is still 174 bytes and still 117/174 matched, and
' the only difference in the whole function is where that one `push esi` lands. Measured.
'
' 39 is 'a'-'9'-1: for n > 9 the digit becomes 48+n+39, which is 97 ('a') at n = 10, so the
' digits are LOWERCASE.
	Function Md5Hex:String(a0:Int)
		Local s:String = ""
		For Local i:Int = 0 To 7
			Local n:Int = (a0 Shr (i * 4)) & 15
			s = Chr(n + 48 + (n > 9) * 39) + s
		Next
		Return s[6..8] + s[4..6] + s[2..4] + s[0..2]
	End Function

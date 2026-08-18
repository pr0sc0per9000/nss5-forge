' ColourGreen  -- module-level Function (no Type)
' VA 0x00507dc1   14 bytes   sig (i)$
' byte-identical vs NSS5.exe (14/14, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Returns the constant String at 0x00C6E904, whose BlitzMax string object
' decodes to "00FF00" -- a hex colour. 5 game functions call it.
'
' THE SIGNATURE IS (i)$, NOT ()$.
' The body is unaffected -- the parameter is never read, so the 14 emitted bytes are the
' same either way and the oracle certifies both (re-driven: MATCH 14/14, mode=reloc).
' The arity is decided by the CALL SITES, not by this body: all 15 of them push exactly one
' dword and clean up with `add esp,4` (e.g. TScreen_MyContract.ButtonRequestLoan at
' 0x00555CFB pushes TProfile.relationboss). Declared ()$ the probe rejects every caller with
' "Too many function parameters", which reads like a bad caller body rather than a wrong
' declaration here. The argument really is ignored: 14 bytes is push ebp / mov ebp,esp /
' mov eax,<string> / jmp+0 / mov esp,ebp / pop ebp / ret, with no [ebp+8] access at all.
	Function ColourGreen:String(a0:Int)
		Return "00FF00"
	End Function

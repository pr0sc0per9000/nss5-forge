' RGBToHex  -- module-level Function (no Type)
' VA 0x005065a5   117 bytes   sig (i,i,i)$
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 1 game function calls it. Formats an r,g,b triple as a 6-character hex
' string by taking the low two digits of each Hex() -- the inverse of SetColourHex.
'
' CASE DIRECTION CORRECTED 2026-08-22. The runtime-helper table used to name 0x004A7410
' `_brl_retro_Lower` and 0x004A74E0 `_brl_retro_Upper`; both were wrong and neither address
' is a brl.retro wrapper. 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is
' `_bbStringToLower` -- proved from the instructions (`and edi,0xFFFFFFDF` vs `or edi,0x20`),
' from blitz_string.c's 181/192 ASCII gates, and above all from NSS5.exe's own retro
' wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper), which are 21 bytes each and CALL
' 0x004A74E0 and 0x004A7410 respectively. A wrapper cannot be the function it calls.
' See docs/reference/codegen-patterns.md 15.6.
' So this returns an UPPERCASE hex colour, which is also what every colour literal in the
' corpus looks like ("FFFFFF", "00FF00", "FF0000"); a lowercase one would never compare
' equal to them. Measured on worker 380 under NSS5_NO_LEARN=1: `Lower(...)` is now
' MISMATCH 89/117 at first_diff=102 -- the exact figures this header used to attribute to
' `Upper`, because the wrong row simply swapped which spelling passed.
'
' The three operands are evaluated right to left (a2 first), which is bcc's argument and
' concat-operand order, and the concat is left-associative: (h0 + h1) + h2.
	Function RGBToHex:String(a0:Int, a1:Int, a2:Int)
		Return (Hex(a0)[6..8] + Hex(a1)[6..8] + Hex(a2)[6..8]).ToUpper()
	End Function

' RGBToHex  -- module-level Function (no Type)
' VA 0x005065a5   117 bytes   sig (i,i,i)$
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 1 game function calls it. Formats an r,g,b triple as a 6-character hex
' string by taking the low two digits of each Hex() -- the inverse of SetColourHex.
'
' Lower vs Upper is measured, not assumed: Upper is a genuine MISMATCH (89/117, first
' diff at 102), Lower is exact. That is the negative control for the callee at 0x004A7410,
' which is a per-character String transform in the C runtime.
'
' The three operands are evaluated right to left (a2 first), which is bcc's argument and
' concat-operand order, and the concat is left-associative: (h0 + h1) + h2.
	Function RGBToHex:String(a0:Int, a1:Int, a2:Int)
		Return Lower(Hex(a0)[6..8] + Hex(a1)[6..8] + Hex(a2)[6..8])
	End Function

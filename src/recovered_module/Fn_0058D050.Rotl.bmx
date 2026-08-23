' Rotl  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058d050   34 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The rotate-left twin of the already-verified Rotr (0x0058D072), and byte-identical to
' Md5Rotl (0x0058C890). It sits immediately AFTER Sha256Hex (0x0058C960, 1776 bytes, ends
' at 0x0058D050) and immediately BEFORE Rotr, i.e. inside the SHA-256 group -- but nothing
' in the exe calls it. Verified by a brute scan of every E8/E9 rel32 in the code sections:
' zero call sites. SHA-256 needs only right-rotates, so the left-rotate written next to it
' was never used.
'
' Found by the unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
	Function Rotl:Int(a0:Int, a1:Int)
		Return (a0 Shl a1) | (a0 Shr (32 - a1))
	End Function

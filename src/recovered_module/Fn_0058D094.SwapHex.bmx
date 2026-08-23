' SwapHex  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058d094   107 bytes   sig (i)$
' byte-identical vs NSS5.exe (107/107, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The SHA-256 group's byte-order swap: Hex() the word, then re-emit the four byte pairs
' back to front. Functionally the same as Md5Hex (0x0058C8B2) but written the short way,
' leaning on BRL.Retro's Hex() (0x0059C927, the same helper HexPad.bmx already uses)
' instead of building the digits by hand.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites). It sits between Rotr (0x0058D072) and the next dead body in the SHA-256 group;
' Sha256Hex (0x0058C960) is already verified and does its own formatting. Found by the
' unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
'
' THE CONCATENATION ORDER IS THE REVERSAL. The four slices are evaluated left to right and
' pushed in that order, but cdecl takes the LAST push as the first argument, so the first
' bbStringConcat pairs h[6..8] with h[4..6], not h[0..2] with h[2..4]. Reading the pushes
' in source order would give a no-op that returns h unchanged.
	Function SwapHex:String(a0:Int)
		Local h:String = Hex(a0)
		Return h[6..8] + h[4..6] + h[2..4] + h[0..2]
	End Function

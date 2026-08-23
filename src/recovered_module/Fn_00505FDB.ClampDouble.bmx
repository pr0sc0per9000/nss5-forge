' ClampDouble  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x00505fdb   75 bytes   sig (*d,d,d)i
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The Double twin of the already-verified ClampInt (0x00505F6D, 35 bytes) and ClampFloat
' (0x00505F90, 75 bytes), sitting immediately after ClampFloat in the image -- the three
' were plainly written together. Same shape, same in-place semantics, x87 qword loads
' instead of dword ones.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites), which is why it was never reached through a blocked caller and why nothing in
' the corpus knew it existed. ClampInt has 12 game callers and ClampFloat 8. Found by the
' unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
'
' As with ClampInt and ClampFloat the original almost certainly declared a Var parameter;
' a scalar Var and a Ptr are the same four bytes and the same codegen.
	Function ClampDouble:Int(a0:Double Ptr, a1:Double, a2:Double)
		If a0[0] < a1 Then a0[0] = a1
		If a0[0] > a2 Then a0[0] = a2
	End Function

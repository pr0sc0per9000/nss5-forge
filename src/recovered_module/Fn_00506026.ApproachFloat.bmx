' ApproachFloat  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x00506026   35 bytes   sig (*f,f,f)i
' byte-identical vs NSS5.exe (35/35, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Moves the Float at a0 a fraction a2 of the way towards a1, in place -- the linear
' interpolation used as an ease/smoothing step. It sits in the small-maths run that
' already holds ClampInt, ClampFloat, ClampDouble, Dist2D, Cross2D and WrapAngle, between
' ClampDouble (0x00505FDB) and AngleDiff (0x00506049).
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites). Found by the unrecovered-function audit; see
' docs/reference/unrecovered-inventory.md.
'
'     00506029  8B 45 08        mov eax, [ebp+8]      ; a0 (Float Ptr / Var)
'     0050602C  D9 45 0C        fld  dword [ebp+0xC]  ; a1  target
'     0050602F  D9 45 10        fld  dword [ebp+0x10] ; a2  fraction
'     00506032  D9 00           fld  dword [eax]      ; a0[0]
'     00506034  D9 CA           fxch st(2)
'     00506036  D8 20           fsub dword [eax]      ; target - a0[0]
'     00506038  DE C9           fmulp st(1)           ; * fraction
'     0050603A  DE C1           faddp st(1)           ; + a0[0]
'     0050603C  D9 18           fstp dword [eax]
'
' TWO SPELLINGS BOTH REACH 35/35, recorded so the next person does not re-run it:
'     a0[0] = a0[0] + (a1 - a0[0]) * a2          <- this file
'     a0[0] :+ (a1 - a0[0]) * a2
' bcc emits the same x87 sequence for both, so the bytes cannot choose between them.
	Function ApproachFloat:Int(a0:Float Ptr, a1:Float, a2:Float)
		a0[0] = a0[0] + (a1 - a0[0]) * a2
	End Function

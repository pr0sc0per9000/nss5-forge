' IntPow  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0050885e   33 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (33/33, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Integer exponentiation by repeated multiplication. BlitzMax's own ^ is exponentiation
' but yields a Double, so a whole-number power needs either a cast or this.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites). It is the last body in the 0x00505B91..0x00508880 module-Function run. Found by
' the unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
'
'     00508861  8B 4D 08        mov ecx, [ebp+8]      ; base
'     00508864  8B 55 0C        mov edx, [ebp+0xC]    ; exponent
'     00508867  B8 01 00 00 00  mov eax, 1
'     0050886C  EB 06           jmp 00508874          ; pre-tested loop
'     0050886E  0F AF C1        imul eax, ecx
'     00508871  83 EA 01        sub edx, 1
'     00508874  83 FA 00        cmp edx, 0
'     00508877  75 F5           jne 0050886E
'
' The guard is jne, so the source tests <> 0 (or the bare truthiness that compiles to the
' same thing) -- NOT > 0, which would emit jg. A negative exponent therefore spins 2^32
' times; preserved, since that is what the original does.
	Function IntPow:Int(a0:Int, a1:Int)
		Local r:Int = 1
		While a1 <> 0
			r :* a0
			a1 :- 1
		Wend
		Return r
	End Function

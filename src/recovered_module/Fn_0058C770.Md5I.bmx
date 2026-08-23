' Md5I  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c770   24 bytes   sig (i,i,i)i
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The MD5 round function I, part of the dead MD5 implementation described in
' Fn_0058C722.Md5F.bmx and in docs/reference/unrecovered-inventory.md.
'
'     0058C773  8B 4D 08        mov ecx, [ebp+8]      ; x
'     0058C776  8B 45 0C        mov eax, [ebp+0xC]    ; y
'     0058C779  8B 55 10        mov edx, [ebp+0x10]   ; z
'     0058C77C  F7 D2           not edx               ; ~z
'     0058C77E  09 D1           or  ecx, edx          ; x | ~z
'     0058C780  31 C8           xor eax, ecx          ; y ~ (x | ~z)
'
' One line mixes both arities of `~`: the inner one is unary complement, the outer binary
' XOR. That is legal and is what the original emits.
	Function Md5I:Int(a0:Int, a1:Int, a2:Int)
		Return a1 ~ (a0 | ~a2)
	End Function

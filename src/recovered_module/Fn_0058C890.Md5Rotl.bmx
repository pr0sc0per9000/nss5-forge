' Md5Rotl  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c890   34 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Rotate-LEFT, the MD5 primitive. Called four times, once from each of Md5FF/GG/HH/II.
' Part of the dead MD5 implementation described in Fn_0058C722.Md5F.bmx.
'
' The exact mirror of the already-verified Rotr (0x0058D072), and byte-for-byte identical
' to Rotl (0x0058D050) which sits in the SHA-256 group 1KB further on. The original source
' therefore declared the same rotate twice under two different names -- a module cannot
' declare one Function twice, and bcc does not fold identical bodies, so two copies in the
' image means two declarations. Which of the two the MD5 code used is fixed by the call
' sites, not by the bytes.
'
'     0058C89A  89 D0           mov eax, edx
'     0058C89C  D3 E0           shl eax, cl           ; x Shl n
'     0058C89E  BB 20 00 00 00  mov ebx, 32
'     0058C8A3  29 CB           sub ebx, ecx
'     0058C8A5  89 D9           mov ecx, ebx
'     0058C8A7  D3 EA           shr edx, cl           ; x Shr (32-n)  -- LOGICAL shift
'     0058C8A9  09 D0           or  eax, edx
'
' `Shr` is BlitzMax's logical right shift (`Sar` is the arithmetic one); the original emits
' `shr`, so `Sar` would be wrong for any input with the high bit set. `|` and not `Or`:
' `Or` is the short-circuiting logical operator and yields 0/1 (Rotr.bmx measured 37 bytes
' for that spelling).
	Function Md5Rotl:Int(a0:Int, a1:Int)
		Return (a0 Shl a1) | (a0 Shr (32 - a1))
	End Function

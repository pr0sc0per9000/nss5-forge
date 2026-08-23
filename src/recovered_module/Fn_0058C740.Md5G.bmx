' Md5G  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c740   26 bytes   sig (i,i,i)i
' byte-identical vs NSS5.exe (26/26, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The MD5 round function G, part of the dead MD5 implementation described in
' Fn_0058C722.Md5F.bmx and in docs/reference/unrecovered-inventory.md. Called 16 times
' from Md5GG (0x0058C7CA), which is itself called 16 times from 0x0058BC02.
'
'     0058C743  8B 45 08        mov eax, [ebp+8]      ; x
'     0058C746  8B 4D 0C        mov ecx, [ebp+0xC]    ; y
'     0058C749  8B 55 10        mov edx, [ebp+0x10]   ; z
'     0058C74C  21 D0           and eax, edx          ; x & z
'     0058C74E  F7 D2           not edx               ; ~z
'     0058C750  21 D1           and ecx, edx          ; y & ~z
'     0058C752  09 C8           or  eax, ecx
'
' Note the operand order differs from Md5F: G reads its own first parameter only once, so
' bcc needs no ebx and the frame is 4 bytes shorter than F's.
	Function Md5G:Int(a0:Int, a1:Int, a2:Int)
		Return (a0 & a2) | (a1 & ~a2)
	End Function

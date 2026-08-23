' Md5H  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c75a   22 bytes   sig (i,i,i)i
' byte-identical vs NSS5.exe (22/22, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The MD5 round function H, part of the dead MD5 implementation described in
' Fn_0058C722.Md5F.bmx and in docs/reference/unrecovered-inventory.md.
'
'     0058C766  31 C8           xor eax, ecx          ; x ~ y
'     0058C768  31 D0           xor eax, edx          ; ~ z
'
' Both tildes here are the BINARY `~` (XOR). Writing `Xor` instead is not an option --
' BlitzMax has no `Xor` keyword; `~` is the only spelling.
	Function Md5H:Int(a0:Int, a1:Int, a2:Int)
		Return a0 ~ a1 ~ a2
	End Function

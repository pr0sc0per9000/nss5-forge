' Md5F  -- module-level Function (no Type). NAME IS OURS: module Functions carry no
' BBDebugScope record, so the original identifier is unrecoverable and names have no
' effect on codegen.
' VA 0x0058c722   30 bytes   sig (i,i,i)i
' byte-identical vs NSS5.exe (30/30, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' FOUND BY THE UNRECOVERED-FUNCTION AUDIT, not by a blocked caller: absent from
' vtable_map.tsv, from extracted/brl_functions*.tsv, from extracted/decomp and from every
' tree under src/ before this file. See docs/reference/unrecovered-inventory.md.
'
' The MD5 round function F. This is one of eleven functions forming a complete, entirely
' DEAD MD5 implementation the game's own module carries at 0x0058BC02..0x0058C960 -- the
' 2,848-byte digest body at 0x0058BC02 has zero callers anywhere in the exe (verified by a
' brute scan of every E8/E9 rel32 in the code sections, not just callgraph_resolved.tsv).
' Its 16-call-sites-each use of FF/GG/HH/II is what identifies it: 4 rounds x 16 steps.
'
'     0058C722  55              push ebp
'     0058C723  89 E5           mov ebp, esp
'     0058C725  53              push ebx
'     0058C726  8B 55 08        mov edx, [ebp+8]      ; a0 = x
'     0058C729  8B 5D 0C        mov ebx, [ebp+0xC]    ; a1 = y
'     0058C72C  8B 4D 10        mov ecx, [ebp+0x10]   ; a2 = z
'     0058C72F  89 D0           mov eax, edx
'     0058C731  21 D8           and eax, ebx          ; x & y
'     0058C733  F7 D2           not edx               ; ~x
'     0058C735  21 CA           and edx, ecx          ; ~x & z
'     0058C737  09 D0           or  eax, edx
'     0058C739  EB 00           jmp 0058C73B
'     ... pop ebx / leave / ret
'
' `~` is BlitzMax's UNARY bitwise complement here (it is overloaded by arity: binary `~`
' is XOR). The unary form is what emits the bare `not edx`.
	Function Md5F:Int(a0:Int, a1:Int, a2:Int)
		Return (a0 & a1) | (~a0 & a2)
	End Function

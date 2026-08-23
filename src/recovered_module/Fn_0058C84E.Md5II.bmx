' Md5II  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058c84e   66 bytes   sig (i,i,i,i,i,i,i)i
' byte-identical vs NSS5.exe (66/66, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' MD5 round step II: one of the four seven-argument step macros, expanded here as a real
' Function. Part of the dead MD5 implementation described in Fn_0058C722.Md5F.bmx and in
' docs/reference/unrecovered-inventory.md. The 2,848-byte digest body at 0x0058BC02 calls
' this one SIXTEEN times -- 4 rounds x 16 steps is what identifies the algorithm.
'
' Parameters, read off the frame: a0=a, a1=b, a2=c, a3=d, a4=x, a5=s, a6=ac.
'
'     0058C866  E8 ..           call 0x0058C770     ; Md5I(b, c, d)
'     0058C86E  01 F8           add eax, edi          ; + x
'     0058C870  03 45 20        add eax, [ebp+0x20]   ; + ac
'     0058C873  01 C6           add esi, eax          ; a :+ ...
'     0058C879  E8 ..           call 0x0058C890       ; Md5Rotl(a, s)
'     ...         01 D8           add eax, ebx          ; Return a + b
'
' The compound `:+` is load-bearing. Written out as `a0 = a0 + Md5I(...) + a4 + a6` bcc
' would associate left and emit ((a+F)+x)+ac; the original adds F+x+ac first and then adds
' the running value once, which is exactly what `:+` compiles to.
	Function Md5II:Int(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int, a5:Int, a6:Int)
		a0 :+ Md5I(a1, a2, a3) + a4 + a6
		a0 = Md5Rotl(a0, a5)
		Return a0 + a1
	End Function

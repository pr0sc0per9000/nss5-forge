' Fn_00598160  --  volumes module Function (BaH.Volumes 1.06 name: bbStringFromUTF8String)
' VA 0x00598160   284 bytes   sig (*b)$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (284/284, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: bbStringFromUTF8String.
' a0 is `s` in 1.06. Dead in NSS5 (zero E8/E9 callers).
' strlen 0x004B4500 (cdecl, add esp,4), New Short[l] (bbArrayNew1D, tag 0x00C9ABC4),
' bc=-1 in edi, i in ecx, l copied to [ebp-8] as the loop limit; c/d/e live in
' esi/ebx/eax. Tail: bbStringFromShorts(b+0x18, bc+1). `Return ""` is this unit's own
' empty literal 0x00C9ABC8, not bbEmptyString. strlen_ comes from Fn_00598051.bmx.

Function Fn_00598160:String(a0:Byte Ptr)
	If a0 Then
		Local l:Int = strlen_(a0)
		Local b:Short[] = New Short[l]
		Local bc:Int = -1, c:Int, d:Int, e:Int
		For Local i:Int = 0 Until l
			bc:+1
			c = a0[i]
			If c<128
				b[bc] = c
				Continue
			End If
			i:+1
			d=a0[i]
			If c<224
				b[bc] = (c-192)*64+(d-128)
				Continue
			End If
			i:+1
			e = a0[i]
			If c < 240
				b[bc] = (c-224)*4096+(d-128)*64+(e-128)
				Continue
			End If
		Next
		Return String.fromshorts(b, bc + 1)
	End If

	Return ""

End Function

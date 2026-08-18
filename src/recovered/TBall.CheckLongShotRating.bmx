' TBall.CheckLongShotRating
' VA 0x004cd177   228 bytes   vtable slot 0xd0   sig ()i
' byte-identical vs NSS5.exe (228/228, original length from Ghidra's inventory)
' ASSUMPTIONS: PTR_FUN_00c5d988 resolves to TPitch+0x5c = InsidePenaltyBox(i,i,i)i;
' TPlayer slot 0x234 = AddPlayerRating(i,i,$). FUN_0059f089 = _brl_random_Rand,
' FUN_004a7ac0 = _bbStringFromInt, FUN_004a7c20 = _bbStringConcat -- together they are one
' String-plus-Int concatenation. The two rating-key literals are masked addresses; their
' VALUES are not proven.
'
' NOTES -- two shape corrections the oracle forced:
'  * The three tests are ONE short-circuit And chain, not the cascade of zero-initialised
'    Locals the decompilation shows. The first term emits setne/movzx and the falsy exit
'    simply leaves that 0 in eax, which is why no "mov reg,0" appears anywhere.
'  * Rand is called with ONE argument. bcc pushes the defaulted max=1 first and then 4
'    (6A 01 6A 04), which Ghidra renders as Rand(4,1); Rand(1,4) emits the pushes the other
'    way round and diverges.
' harness mode=reloc, 10 addresses masked.
	Method CheckLongShotRating:Int()
		If lastkickedby And lastkickedby.newstar And lastkickedby.ihadashot
			If TPitch.InsidePenaltyBox(lastkickedby.kickx, lastkickedby.kicky, 0) <> 0
				lastkickedby.AddPlayerRating(9, -1, "CBOSSSHOUT_BADFINISHING" + Rand(4))
			Else
				lastkickedby.AddPlayerRating(8, 1, "CBOSSSHOUT_GOODEFFORT" + Rand(4))
			End If
			lastkickedby.ihadashot = 0
		End If
	End Method

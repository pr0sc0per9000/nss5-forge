' HexPad  -- module-level Function (no Type)
' VA 0x0050871e   44 bytes   sig (i,i)$
' byte-identical vs NSS5.exe (44/44, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. called_by_count=1 in the inventory (only URLEncode uses it), calls_count=2
' (Hex$ at 0x0059c927 = _brl_retro_Hex, then bbStringSlice at 0x004a7c90).
'
' The original does NOT call BRL.Retro's Right$ -- it computes the slice bounds itself
' (push [eax+8] length; sub edx,ebx; call bbStringSlice), i.e. the source is a plain
' slice expression `h[h.Length - a1..]`, not `Right(h, a1)`. Confirmed: writing it as
' `Right(Hex(a0), a1)` compiles NG's Right$ to a single different call and comes out
' 34 bytes, 10 short.
	Function HexPad:String(a0:Int, a1:Int)
		Local h:String = Hex(a0)
		Return h[h.Length - a1..]
	End Function

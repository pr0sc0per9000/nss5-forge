' ShiftColourHex  -- module-level Function (no Type)
' VA 0x0050661a   145 bytes   sig ($,i)$
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Brightens or darkens a hex colour: parse, add a1 to each component, clamp
' each to 0..255, re-format. Three already-verified module Functions are called through
' and mask by name -- ParseColourHex (0x005064ED), ClampInt (0x00505F6D) and RGBToHex
' (0x005065A5).
'
' ClampInt was recovered with an Int Ptr parameter, so the call sites here are spelled
' Varptr; the original almost certainly wrote a Var, which compiles identically.
' The three r :+ a1 are memory operands (add [ebp-N], ebx), so the :+ form is required.
	Function ShiftColourHex:String(a0:String, a1:Int)
		Local r:Int
		Local g:Int
		Local b:Int
		ParseColourHex(a0, r, g, b)
		r :+ a1
		g :+ a1
		b :+ a1
		ClampInt(Varptr r, 0, 255)
		ClampInt(Varptr g, 0, 255)
		ClampInt(Varptr b, 0, 255)
		Return RGBToHex(r, g, b)
	End Function

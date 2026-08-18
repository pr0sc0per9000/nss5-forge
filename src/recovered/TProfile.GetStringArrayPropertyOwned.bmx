' TProfile.GetStringArrayPropertyOwned
' VA 0x0056B55C   126 bytes   vtable slot 0xF0   sig (i)[]$
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory, mode=reloc)
'
' The three stores land at [arr+0x18], [arr+0x1c], [arr+0x20] with NO bounds checks, so this
' is an ARRAY LITERAL, not `Local s:String[] = New String[3]` + three indexed assignments
' (that form is 186 bytes -- 60 longer, 20 per bounds check).
' 0x00C59058 is the BBArray element-type descriptor for String (first byte 0x24 = '$').

	Method GetStringArrayPropertyOwned:String[](a0:Int)
		Return [ PropertyName(a0), String(Self.property[a0-1]), FormatMoney(TierA(a0) * Self.property[a0-1], 0) ]
	End Method

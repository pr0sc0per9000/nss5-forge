' TProfile.GetStringArrayItemsOwned
' VA 0x0056B0E2   126 bytes   vtable slot 0xE4   sig (i)[]$
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory, mode=reloc)
'
' Exact twin of TProfile.GetStringArrayPropertyOwned -- same array literal, with
' ItemName/TierC/items in place of PropertyName/TierA/property.
' Three stores at [arr+0x18/0x1c/0x20] with NO bounds checks => array literal.

	Method GetStringArrayItemsOwned:String[](a0:Int)
		Return [ ItemName(a0), String(Self.items[a0-1]), FormatMoney(TierC(a0) * Self.items[a0-1], 0) ]
	End Method

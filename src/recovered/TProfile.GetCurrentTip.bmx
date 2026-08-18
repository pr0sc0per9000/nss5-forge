' TProfile.GetCurrentTip
' VA 0x005690a3   99 bytes   vtable slot 0x7c   sig ()$
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory, mode=reloc)
' assumptions: TProfile field +0x1c4 = tipcount:Int;
'              FUN_004a7ac0 = _bbStringFromInt, FUN_004a7c20 = _bbStringConcat,
'              FUN_004c5549 = recovered module Function GetText;
'              string literal 0x00c8e738 = "CTIP_".
' The Ghidra `bVar1 = x < 1; if (!bVar1) bVar1 = 50 < x;` shape is a short-circuit Or.
	Method GetCurrentTip:String()
		If Self.tipcount < 1 Or Self.tipcount > 50 Then Self.tipcount = 1
		Return GetText("CTIP_" + Self.tipcount)
	End Method

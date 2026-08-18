' TGadget.CreateToolTip
' VA 0x00514c81   239 bytes   vtable slot 0x80   sig ($)i
' byte-identical vs NSS5.exe (239/239, original length from Ghidra's inventory, mode=reloc)
' Global: 0x00C61710 g_fonts:TImageFont[] (globals_final types it Object[], init=bbEmptyArray;
'         the +0x1c load is element 1 past the 0x18-byte BBArray header).
' PTR_FUN_00C634C0 is TLabel's class table + 0x88 = the 21-arg CreateLabel; literals
' 0x00C73A70 "888888", 0x00C5D680 "FFFFFF", 0x00C7E000 "tt_", 0x005C7D40 "" read out of NSS5.exe.
' BRL: 0x005AE14F SetImageFont, 0x005AE1AB TextWidth, 0x005AE23C TextHeight.
' Both `+ 10` values are Locals INCLUDING the addition -- w spills to esi and h stays in eax.
' Inlining both gives 237 with the wrong register for Self; `Local w = TextWidth(a0)` with the
' `+ 10` at the call site gives 241.
	Method CreateToolTip:Int(a0:String)
		'!Global g_fonts:TImageFont[]
		If lbl_ToolTip <> Null Then lbl_ToolTip = Null
		SetImageFont(g_fonts[1])
		Local w:Int = TextWidth(a0) + 10
		Local h:Int = TextHeight(a0) + 10
		lbl_ToolTip = TLabel.CreateLabel("tt_" + name, a0, Int(x), Int(y), w, h, 2, "888888", "FFFFFF", 0, 1, 0, 1, 1, Null, 0, 0, 0, 0, "", 0)
	End Method

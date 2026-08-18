' TGadget.UpdateToolTip
' VA 0x00513892   676 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method (implicit Self at [ebp+8]), SIG ()i, class-table slot 0x3C
'
' ASSUMPTIONS  (module Global names are ours; the declared TYPES are load-bearing)
'   0x00C5D258 g_options_tooltips:Int
'   0x00C6173C g_screen_usemouse:Int
'   0x00C61CF8 g_activegadget:TGadget   (compared for identity against Self)
'   0x00C61724 g_screen_mousex:Float  0x00C61728 g_screen_mousey:Float
'   0x00C61740 g_screen_scrollx:Float 0x00C61744 g_screen_scrolly:Float
'   0x00C6EFE4 g_screen_w:Int         0x00C6EFE8 g_screen_h:Int  (bare dword reads)
'   Fields used: TGadget +0x20 x, +0x24 y, +0x28 h, +0x2C w, +0x50 lbl_ToolTip:TLabel;
'   TLabel inherits x/y/h/w/alph (+0x44) from TGadget.  Slot 0x60 = TGadget.MouseOver.
'   Float constants read from .rdata: 0.1, 16.0, 24.0, 16.0, 8.0, 0.1, 2.0, 2.0, 4.0,
'   4.0, 0.1 (0x00C7DF74..0x00C7DF9C).  Every Float->Int conversion goes through
'   0x005B9690 _bbFloatToInt, which bcc emits implicitly -- no Int() in the source.
'
' MEASURED SHAPE
'   * There are NO flag Locals.  `If lbl_ToolTip And g_options_tooltips` and
'     `If g_screen_usemouse And MouseOver()` are And-chains; Ghidra renders each as a
'     zero-initialised int that a nested If overwrites, which is the same bytes.
'   * `x + w / 2.0 - lbl_ToolTip.w / 2.0` -- x is loaded FIRST (fld [esi+0x20] before
'     fld [esi+0x2c]).  Writing `w / 2.0 + x - ...` is 2 bytes short.
'   * The two mouse-branch tests really are `x > g_screen_w / 2` / `y > g_screen_h / 2`
'     (the gadget coordinate is fld'd first), even though Ghidra prints them reversed.
'!Global g_options_tooltips:Int
'!Global g_screen_usemouse:Int
'!Global g_activegadget:TGadget
'!Global g_screen_mousex:Float
'!Global g_screen_mousey:Float
'!Global g_screen_scrollx:Float
'!Global g_screen_scrolly:Float
'!Global g_screen_w:Int
'!Global g_screen_h:Int
If lbl_ToolTip And g_options_tooltips
	If g_screen_usemouse And MouseOver()
		If lbl_ToolTip.alph < 1.0 Then lbl_ToolTip.alph = lbl_ToolTip.alph + 0.1
		Local tx:Int = g_screen_scrollx + 16.0
		Local ty:Int = g_screen_scrolly + 24.0
		If x > g_screen_w / 2 Then tx = g_screen_scrollx - 16.0 - lbl_ToolTip.w
		If y > g_screen_h / 2 Then ty = g_screen_scrolly - 8.0 - lbl_ToolTip.h
		lbl_ToolTip.x = tx - g_screen_mousex
		lbl_ToolTip.y = ty - g_screen_mousey
	Else
		If g_screen_usemouse = 0 And g_activegadget = Self
			If lbl_ToolTip.alph < 1.0 Then lbl_ToolTip.alph = lbl_ToolTip.alph + 0.1
			Local tx2:Int = x + w / 2.0 - lbl_ToolTip.w / 2.0
			Local ty2:Int = y - 4.0 - lbl_ToolTip.h
			If y < g_screen_h / 2 Then ty2 = y + h + 4.0
			lbl_ToolTip.x = tx2
			lbl_ToolTip.y = ty2
		ElseIf lbl_ToolTip.alph > 0.0
			lbl_ToolTip.alph = lbl_ToolTip.alph - 0.1
		End If
	End If
End If

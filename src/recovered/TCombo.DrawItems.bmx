' TCombo.DrawItems
' VA 0x00518D28   459 bytes   vtable slot 0xA8   sig ()i
' byte-identical vs NSS5.exe (459/459, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only, Self implicit.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Globals (names ours, types load-bearing):
'      0x00C61D00 TImage g_combo_img1   0x00C61D04 TImage g_combo_img2
'        -- globals_final.tsv has both as plain `Object` (usage/low); TImage is forced by
'        the DrawImage() call sites (0x005AD711 = _brl_max2d_DrawImage).
'      0x00C6173C Int   g_screen_int03  0x00C6EFE8 Int   g_engine_int163
'      0x00C61728 Float g_screen_float02
'  * The loop element type is TButton (class table 0x00C62344 pushed to bbObjectDowncast).
'    Slots used on it: 0x44 Draw, 0x60 MouseOver, 0x50 RenderHighlight -- 0x50 and 0x60 are
'    INHERITED from TGadget (TButton declares neither); walked via class_tables.tsv.
'  * Self.y / Self.h / b.x / b.y / b.h are TGadget fields at +0x24 / +0x28 / +0x20 / +0x24 /
'    +0x28; Self.buttons +0x60, Self.itemoffset +0x70 are TCombo's own.
'  * 0x00C7E110/114/118/11C are .rdata FLOAT CONSTANTS (8.0 and 12.0), not Globals --
'    `_DAT_` in the decompilation. They are literals in the source.
'  * `If n > Self.itemoffset` (cmp [n],eax -> field-on-the-right); the Ghidra-normalised
'    `Self.itemoffset < n` would put the operands the other way round.
'  * The last guard is `>` even though bcc emits `setbe` + inverted `jne`: for an x87
'    compare bcc picks the complementary setcc and flips the branch.
'  * `If g_screen_int03 And ...` is a BARE truth test -- no setne/movzx is emitted for it,
'    unlike the `sel <> Null` operand next to it.
'  * `n :+ 1` (add dword [n],1), not `n = n + 1`.
'!Global g_combo_img1:TImage
'!Global g_combo_img2:TImage
'!Global g_screen_int03:Int
'!Global g_engine_int163:Int
'!Global g_screen_float02:Float
Local n:Int = 1
Local yy:Int = Int(Self.y + Self.h)
Local sel:TButton = Null
For Local b:TButton = EachIn Self.buttons
	b.y = yy
	If n > Self.itemoffset
		b.Draw()
		If Self.itemoffset > 0 And yy = Self.y + Self.h
			DrawImage(g_combo_img1, b.x + 12.0, b.y + 8.0, 0)
		EndIf
		If b.MouseOver() Then sel = b
		yy = Int(yy + Self.h)
	EndIf
	n :+ 1
	If yy + Self.h > g_engine_int163 - g_screen_float02
		DrawImage(g_combo_img2, b.x + 12.0, b.y + b.h - 8.0)
	EndIf
Next
If g_screen_int03 And sel <> Null
	sel.RenderHighlight()
EndIf

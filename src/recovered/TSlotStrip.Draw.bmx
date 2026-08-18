' TSlotStrip.Draw
' VA 0x00578c28   186 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (186/186, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C6C658 = the strip sprite, declared TImage (globals_final.tsv says bare
'   Object; DrawImage fixes it). 0x00C61724/0x00C61728 are Float (globals_final, high conf).
'   0x00C913FC / 0x00C91400 / 0x00C91404 are three further Float Globals not in
'   globals_final.tsv -- typed Float from the x87 adds. FUN_005B9690 is _bbFloatToInt, i.e.
'   the Int() casts on the SetViewport arguments; Ghidra models it as variadic and folds the
'   four SetViewport arguments into it.
'!Global g_slotstrip_image:TImage
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
' g_slot_viewx/g_slot_viewy1/g_slot_viewy2 original data-section values are
' 215.0 / 20.0 / 20.0 (0x00C913FC / 0x00C91400 / 0x00C91404). Never stored to anywhere in
' the corpus -- see codegen-patterns 21.1.
'!Global g_slot_viewx:Float = 215.0
'!Global g_slot_viewy1:Float = 20.0
'!Global g_slot_viewy2:Float = 20.0
	Method Draw()
		SetViewport(Int(Self.xPos + g_screen_float01), Int(g_slot_viewx + g_screen_float02), 86, 214)
		DrawImage(g_slotstrip_image, Self.xPos, Self.yPos1 + g_slot_viewy1, 0)
		DrawImage(g_slotstrip_image, Self.xPos, Self.yPos2 + g_slot_viewy2, 0)
	End Method

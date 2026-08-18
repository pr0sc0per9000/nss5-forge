' TCombo.Draw
' VA 0x00518cc9   95 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (95/95, original length from Ghidra's inventory)
' harness mode=reloc.
' The `hidden` guard is an EARLY RETURN (cmp [self+0x3c],0 / je body / mov eax,0 / jmp end).
'   Written as an If-block wrapping the two statements it comes out at 86 bytes.
' The y argument is `y + h / 2.0`, NOT `h / 2.0 + y` -- Ghidra prints the x87 sum in FPU
'   pop order, so the decompiled order is reversed. The wrong order emits fld [self+0x28]
'   where the original has fld [self+0x24], and lands 2 bytes short.
' hidden/x/y/h are TGadget fields (0x3c/0x20/0x24/0x28); btn_head is TCombo 0x5c and
'   slot 0x44 on TButton is TButton.Draw.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TImage -> BRL.Max2D (same as
'   TButton.SetIcon), otherwise the probe fails with "Unable to convert from 'TImage' to
'   'TImage'" because the harness emits a game placeholder Type that shadows BRL's.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_combo_arrow:TImage    ' 0x00c62d9c
	Method Draw:Int()
		'!Global g_combo_arrow:TImage
		If hidden Then Return 0
		btn_head.Draw()
		DrawImage(g_combo_arrow, x + 1.0, y + h / 2.0, 0)
	End Method

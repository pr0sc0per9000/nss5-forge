' TScreen.Draw
' VA 0x00510DFC   618 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method (implicit Self at [ebp+8]), SIG=()i, class-table slot 0x6C
' ORACLE 618/618 reloc_masked=39, first attempt.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (names are OURS; the TYPES are load-bearing):
'     0x00C61724 -> g_screen_float01:Float   0x00C61728 -> g_screen_float02:Float
'       (the screen's draw origin -- pushed straight into SetOrigin's Float parameters)
'     0x00C6EFDC -> g_screenw:Int   0x00C6EFE0 -> g_screenh:Int   (same pair TBlackJack.Draw
'       divides by two; here they widen into DrawImageRect's Float w/h)
'     0x00C6EFE4 -> g_gfxw:Int      0x00C6EFE8 -> g_gfxh:Int      (full-canvas viewport)
'     0x00C61CF8 -> g_activegadget:TGadget -- slot 0x4C is dispatched on it, and 0x4C is
'       TGadget.DrawHighlight(). Other files in the tree declare this address as bare
'       Object; that spelling cannot emit this call, so TGadget is the load-bearing one.
'     0x00C5D258 -> g_options_tooltips:Int
'   Calls: 0x00506456 = SetDrawStateHex($,f,f,f,i) (module Function),
'     0x005ADFD5 = _brl_max2d_SetOrigin, 0x005AD7C8 = _brl_max2d_DrawImageRect,
'     0x005ADE6F = _brl_max2d_SetViewport, 0x005B9690 = _bbFloatToInt (for Int(x)),
'     0x004A8F60 = _bbObjectDowncast, [TScreenMessage+0x38] = DrawAll().
'   TScreen fields +0x10 bg:TImage, +0x14 fDraw:()i. TGadget +0x3C hidden, +0x50
'   lbl_ToolTip:TLabel. TCombo +0x64 activated, slot 0xA8 DrawItems().
'
' CODEGEN NOTES
'   TScreen.RenderBorder is a static Function at slot 0x70, yet bcc calls it from an
'   instance Method as `mov eax,[Self] / call [eax+0x70]` -- no Self push, no Type prefix.
'   `If Self.fDraw` compiles to `cmp dword [edi+0x14], 0x005B95D0` -- the empty-function
'   sentinel, not zero (section 10.6).
'   Each of the three loops re-issues Self.GetGadgetList(); bcc does no CSE.
	Method Draw:Int()
		'!Global g_screen_float01:Float
		'!Global g_screen_float02:Float
		' g_screenw/g_screenh are a third alias for the screen width/height
		' (0x00C6EFDC=800, 0x00C6EFE0=600 -- see TScreen.CreateScreen.bmx's g_screenwidth).
		'!Global g_screenw:Int = 800
		'!Global g_screenh:Int = 600
		'!Global g_gfxw:Int
		'!Global g_gfxh:Int
		'!Global g_activegadget:TGadget
		'!Global g_options_tooltips:Int
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		SetOrigin(0, 0)
		RenderBorder()
		If Self.bg <> Null
			DrawImageRect(Self.bg, g_screen_float01, g_screen_float02, g_screenw, g_screenh, 0)
		EndIf
		SetOrigin(g_screen_float01, g_screen_float02)
		If Self.fDraw
			SetViewport(Int(g_screen_float01), Int(g_screen_float02), g_screenw, g_screenh)
			Self.fDraw()
			SetViewport(0, 0, g_gfxw, g_gfxh)
		EndIf
		For Local g:TGadget = EachIn Self.GetGadgetList()
			g.Draw()
		Next
		For Local c:TCombo = EachIn Self.GetGadgetList()
			If c.activated
				c.DrawItems()
			EndIf
		Next
		If g_activegadget <> Null
			g_activegadget.DrawHighlight()
		EndIf
		If g_options_tooltips
			For Local g2:TGadget = EachIn Self.GetGadgetList()
				If g2.lbl_ToolTip <> Null And g2.hidden = 0
					g2.lbl_ToolTip.Draw()
				EndIf
			Next
		EndIf
		SetOrigin(0, 0)
		TScreenMessage.DrawAll()
	End Method

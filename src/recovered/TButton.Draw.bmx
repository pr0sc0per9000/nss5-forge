' TButton.Draw
' VA 0x005151B5   724 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (724/724, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=32, NSS5_NO_LEARN=1, no learned helpers.
'
' ASSUMPTIONS
'  * Fields (TGadget/TButton, offsets confirmed against TButton.CreateButton/SetButtonStyle):
'    hidden +0x3C, x +0x20, y +0x24, h +0x28, w +0x2C, colour +0x30, txtcolour +0x34,
'    alph +0x44, txt +0x10 (TGadget); TButton.image +0x60, imageoverride +0x64, icon +0x68.
'  * g_engine_int163:Int, g_screen_float02:Float are module Globals (usage-typed).
'    g_Object108:TGadget corrected in globals_corrections.tsv (hand-verified) -- the object
'    the button is compared against to decide whether it may draw past the screen's bottom
'    edge (e.g. the gadget currently being dragged).
'  * SetColourHex = module Function at 0x00505CEA (src/recovered_module/SetColourHex.bmx),
'    called for its side effect (sets the current draw colour from a hex String), return
'    discarded.
'  * DrawGadgetText = TGadget.DrawGadgetText, slot 0x68, sig ($,i)i.
'  * 0x00C7E01C = 0.3 (shadow-image alpha multiplier), read directly from the exe's data
'    section (section 21: masked constants are unverified until read out of the image).
'  * The two relational tests (`edge` vs iy, and the trailing screen-bottom clamp) each
'    needed the LEFT operand to be `Float(iy)` (matching the original's fild-iy-first FP
'    stack order, section 10.1/17) to reproduce the exact fucompp/setcc byte sequence; the
'    clamp is written as a guard (`If ... Then Return 0`) rather than a wrapping `If`, and
'    the `icon <> Null` branch is written with the drawing code as the fallthrough Then and
'    the plain-text-only path as Else, matching where bcc places each block in memory.
'  * The icon x-position build (`icx = ix + Int(w/14.0)`, then `:+ iw/2`) needed the
'    intermediate `Int(w/14.0)` result in its OWN named Local (`t`), not reassigned through
'    `icx` twice, to land the temporary in the same register class the original uses.
'  * The final `DrawGadgetText(txtcolour, ImageWidth(icon))` call passes the ImageWidth
'    result directly (no named Local) -- matches the original, which keeps the value in eax
'    and pushes it straight through (section 16.2: a value consumed by the very next
'    statement costs nothing extra).

	Method Draw:Int()
		'!Global g_engine_int163:Int
		'!Global g_screen_float02:Float
		'!Global g_Object108:TGadget
		If Self.hidden <> 0 Then Return 0
		Local ix:Int = Int(Self.x)
		Local iy:Int = Int(Self.y)
		Local below:Int = Float(iy) > (Float(g_engine_int163) - g_screen_float02) - Self.h
		If below Then below = (g_Object108 = Self)
		If below Then iy = Int((Float(g_engine_int163) - g_screen_float02) - Self.h)
		If Float(iy) > Float(g_engine_int163) - g_screen_float02 Then Return 0
		If Self.image <> Null Then
			SetColor(0, 0, 0)
			SetAlpha(Self.alph * 0.3)
			DrawImage(Self.image, Float(ix + 1), Float(iy + 1), 0)
			SetColourHex(Self.colour)
			SetAlpha(Self.alph)
			DrawImage(Self.image, Float(ix), Float(iy), 0)
			If Self.imageoverride <> 0 Then Return 0
		End If
		SetAlpha(Self.alph)
		If Self.icon <> Null Then
			Local icx:Int = Int(Float(ix) + Self.w / 2.0)
			Local icy:Int = Int(Float(iy) + Self.h / 2.0)
			If Self.txt.Length <> 0 Then
				Local t:Int = Int(Self.w / 14.0)
				icx = ix + t
				Local iw:Int = ImageWidth(Self.icon)
				icx :+ iw / 2
			End If
			SetColor(255, 255, 255)
			DrawImage(Self.icon, Float(icx), Float(icy), 0)
			If Self.txt.Length <> 0 Then Self.DrawGadgetText(Self.txtcolour, ImageWidth(Self.icon))
		Else
			If Self.txt.Length <> 0 Then Self.DrawGadgetText(Self.txtcolour, 0)
		End If
		SetScale(1.0, 1.0)
		SetColor(255, 255, 255)
		Return 0
	End Method

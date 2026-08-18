' TLabel.Draw   (KIND=Method, SIG=()i)
' VA 0x00519BD7   1882 bytes   vtable slot 0x44   (Ghidra-authoritative length)
' ORACLE: mode=reloc  matched=1882/1882  reloc_masked=99  STATUS=MATCH
' NSS5_NO_LEARN=1, no learned helpers -- every E8 named on both sides beforehand.
'
' ASSUMPTIONS / RESOLUTIONS
'   Fields: TGadget (super) hidden +0x3C, x +0x20, y +0x24, h +0x28, w +0x2C, colour +0x30,
'     txtcolour +0x34, txt +0x10, txtalignx +0x14, alph +0x44, forcetxtalpha +0x48,
'     fntSize +0x4C; TLabel (own) image +0x5C, imgborder +0x60, style +0x64, icon +0x68,
'     pointer +0x6C, pointerxoff +0x70, pointeryoff +0x74, scrolltext +0x78, scrollx +0x7C.
'   DrawGadgetText = TGadget.DrawGadgetText, slot 0x68, sig ($,i)i.
'   SetFontSize = TGadget.SetFontSize, slot 0x5C, sig (i)i.
'   ShiftColourHex/SetColourHex/SetDrawStateHex = already-verified module Functions in
'     src/recovered_module/; their E8 operands mask by name.
'   g_ptrImage:TImage @0x00C6329C -- the tooltip-pointer arrow image, lazily loaded from
'     "GameMedia/Images/Interface/Pointer.png" in TLabel.CreateLabel (same address named
'     there; kept consistent). Construction site confirmed via CreateLabel's decompilation
'     (LoadImageChecked into this Global). globals_final.tsv's "Object, low confidence" is
'     upgraded to TImage by that direct evidence.
'   g_screen_float01/02:Float @0x00C61724/28 and g_engine_int162/163:Int @0x00C6EFE4/E8 are
'     the already-established screen-origin-offset and backbuffer-width/height Globals used
'     identically in TButton.Draw / TProgressBar.Draw (usage-typed, high/medium confidence).
'   All float literals (the five +1.0 shadow offsets in the style dispatch, the 2.0/8.0/4.0/
'     10.0/14.0/0.3/0.5 divisors and multipliers) were read directly out of NSS5.exe's data
'     section at each masked fld operand's address (0x00C7E1FC..0x00C7E25C), not guessed --
'     section 21 of codegen-patterns.md: a MATCH never certifies a masked constant's value.
'   Literal "FFFFFF" at 0x00C5D680 read with harness.read_string().
'
'   THREE two-branch If/Else pairs in this body all need the solo-relational
'   swap (codegen-patterns.md section 21): the source reads the NEGATION of the natural
'   comparison with the Then/Else content swapped, to match which physical block bcc places
'   as the fallthrough. All three are object-identity (<>Null) or float (<>0.0) tests, not
'   just the arithmetic relationals the rule was first found on:
'     - imgborder: `If imgborder <> Null Then <shadowed> Else <plain>` (not `= Null`)
'     - icon:      `If icon <> Null Then <icon-draw> Else <text-draw>` (not `= Null`)
'     - scrolltext:`If scrolltext <> 0.0 Then <scrolling> Else <plain text>` (not `= 0.0`)
'
'   The style (2/3/4/5+Default), pointer (1/2/3/4, no Default) and txtalignx (0/1/2, no
'   Default) dispatches are all `Select`, not If/ElseIf -- section 10.2's tell (a run of
'   cmp/je with every je target past the LAST compare) is unambiguous in the disassembly
'   even though Ghidra's C prints all three as nested if/else-if chains. The style Select's
'   Default clause is written INSIDE the Select (not as a trailing statement after End
'   Select) -- that form reproduces the original's zero-byte fallthrough from the compare
'   cascade directly into the default body; a trailing-statement form cost 5 extra bytes
'   (a redundant `jmp` to the very next instruction).
'
'   Left-to-right operand evaluation order in every `A + B` matters and is NOT always
'   "the term written first in the natural English reading" -- e.g. pointer style 1/2 use
'   `x + w/2.0` (x first) while the icon-txt-align w/14.0 term needs a named
'   `Local t:Int = Int(w/14.0)` evaluated BEFORE `x`, i.e. `t + x`, to get the international
'   int-to-float promotion (mov/fild) sequenced the same way the original's does. Matched by
'   iteration against scripts/localise_diff.py, not derived a priori.
'
'   `TextWidth(Self.txt)` immediately after `TextHeight(Self.txt)` in the scrolling-text
'   branch has its return value genuinely DISCARDED in the original (a standalone call,
'   confirmed by the CALL list's own `add esp,4` after it) -- reproduced faithfully, not
'   "improved away".

'!Global g_ptrImage:TImage
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int

	Method Draw:Int()
		If Self.hidden Then Return 0
		If Self.image <> Null
			If Self.imgborder <> Null
				SetAlpha(Self.alph)
				SetColourHex(ShiftColourHex(Self.colour, -32))
				DrawImage(Self.imgborder, Self.x, Self.y, 0)
				SetAlpha(Self.alph * 0.5)
				SetColourHex(Self.colour)
				Select Self.style
					Case 2
						DrawImage(Self.image, Self.x + 1.0, Self.y + 1.0, 0)
					Case 3
						DrawImage(Self.image, Self.x + 1.0, Self.y, 0)
					Case 4
						DrawImage(Self.image, Self.x + 1.0, Self.y + 1.0, 0)
					Case 5
						DrawImage(Self.image, Self.x, Self.y + 1.0, 0)
					Default
						DrawImage(Self.image, Self.x + 1.0, Self.y + 1.0, 0)
				End Select
			Else
				SetColourHex(Self.colour)
				SetAlpha(Self.alph)
				DrawImage(Self.image, Self.x, Self.y, 0)
			End If
			If Self.pointer > 0
				Local px:Int = 0
				Local py:Int = 0
				Select Self.pointer
					Case 1
						px = Int(Self.x + Self.w / 2.0)
						py = Int(Self.y)
					Case 2
						SetRotation(180.0)
						px = Int(Self.x + Self.w / 2.0)
						py = Int(Self.y + Self.h)
					Case 3
						SetRotation(270.0)
						px = Int(Self.x)
						py = Int(Self.y + Self.h / 2.0)
					Case 4
						SetRotation(90.0)
						px = Int(Self.x + Self.w)
						py = Int(Self.y + Self.h / 2.0)
				End Select
				If Self.pointerxoff <> 0 Then px = px + Self.pointerxoff
				If Self.pointeryoff <> 0 Then py = py + Self.pointeryoff
				If Self.imgborder <> Null
					DrawImage(g_ptrImage, Float(px), Float(py), 0)
				End If
				DrawImage(g_ptrImage, Float(px), Float(py), 0)
				SetRotation(0)
			End If
		End If
		If Self.icon <> Null
			SetAlpha(Self.alph)
			If Self.forcetxtalpha <> 0 Then SetAlpha(1.0)
			Local ix:Int = 0
			Local iy:Int = Int(Self.y + Self.h / 2.0)
			Select Self.txtalignx
				Case 0
					ix = Int(Self.x + 10.0 + (ImageWidth(Self.icon) / 2))
				Case 1
					ix = Int(Self.x + Self.w / 2.0)
					If Self.txt.Length <> 0
						Local t:Int = Int(Self.w / 14.0)
						ix = Int(Self.x + t + (ImageWidth(Self.icon) / 2))
					End If
				Case 2
					ix = Int((Self.x + Self.w - 10.0) - (ImageWidth(Self.icon) / 2))
			End Select
			SetColor(255, 255, 255)
			DrawImage(Self.icon, Float(ix), Float(iy), 0)
			If Self.txt.Length <> 0
				Self.DrawGadgetText(Self.txtcolour, ImageWidth(Self.icon))
			End If
		Else
			If Self.txt.Length <> 0
				If Self.scrolltext <> 0.0
					SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
					Self.SetFontSize(Self.fntSize)
					Local th:Int = TextHeight(Self.txt)
					TextWidth(Self.txt)
					Local sx:Int = Int(Self.scrollx)
					Local sy:Int = Int((Self.y - 1.0) + Self.h / 2.0 - (th / 2))
					SetViewport(Int(g_screen_float01 + Self.x + 4.0), Int(g_screen_float02 + Self.y + 4.0), Int(Self.w - 8.0), Int(Self.h - 8.0))
					SetColor(0, 0, 0)
					SetAlpha(0.3 * Self.alph)
					If Self.forcetxtalpha <> 0 Then SetAlpha(0.3)
					DrawText(Self.txt, Float(sx - 1), Float(sy - 1))
					SetColourHex(Self.txtcolour)
					SetAlpha(Self.alph)
					If Self.forcetxtalpha <> 0 Then SetAlpha(1.0)
					DrawText(Self.txt, Float(sx), Float(sy))
					SetColor(255, 255, 255)
					SetViewport(0, 0, g_engine_int162, g_engine_int163)
				Else
					Self.DrawGadgetText(Self.txtcolour, 0)
				End If
			End If
		End If
		SetAlpha(1.0)
	End Method

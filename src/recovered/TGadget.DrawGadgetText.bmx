' TGadget.DrawGadgetText
' VA 0x00514514   1485 bytes   vtable slot 0x68   sig ($,i)i
' byte-identical vs NSS5.exe (1485/1485, mode=reloc, reloc_masked=59)
' NSS5_NO_LEARN=1, every E8 named on both sides beforehand.
'
' Draws every button/label/panel/progress-bar caption in the game -- shared by every TGadget
' subclass through slot 0x68 (TButton, TLabel, TPanel, TProgressBar all reach it via
' Self.DrawGadgetText(colour, xoff) from their own Draw). a0 = text colour hex string,
' a1 = an x-offset in pixels (icon width when a caption is drawn next to an icon; 0 otherwise).
'
' TWO DRAW PATHS, chosen by whether the caption has already been word-wrapped:
'   Self.txtlines <> Null And Not Self.txtlines.IsEmpty()  -> multi-line: centre a block of
'     pre-wrapped lines (built by TGadget.SetText) inside the gadget, shrinking the font via
'     SetScale if the lines do not fit vertically.
'   ElseIf Self.txt.Length <> 0                              -> single line: TGadget.txtalignx
'     (0 left / 1 centre / 2 right) positions it directly, with a1 nudging a centred caption
'     to make room for an icon.
' Every drawn line gets a 1px-down-and-right black drop shadow first (SetColor 0,0,0, alpha
' 0.3*Self.alph, forced to a flat 0.3 when Self.forcetxtalpha is set) then the real text in
' a0's colour at full Self.alph (forced to 1.0 under forcetxtalpha).
'
' FIELDS (TGadget, already established by TGadget.SetText / TLabel.Draw):
'   +0x10 txt:String   +0x14 txtalignx:Int   +0x18 txtlines:TList   +0x20 x:Float
'   +0x24 y:Float   +0x28 h:Float   +0x2C w:Float   +0x44 alph:Float   +0x48 forcetxtalpha:Int
'   +0x4C fntSize:Int.  Self.SetFontSize = slot 0x5C.
' TList.Count = slot 0x70, TList.IsEmpty = slot 0x38, TList.ObjectEnumerator = slot 0x8C
'   (all from vtable_map.tsv). `For Local ln:String = EachIn Self.txtlines` is an ordinary
'   EachIn over a TList of Strings -- the classtable literal bcc pushes ahead of the
'   downcast (0x005C7D60 on the original side) is BlitzMax's built-in String class
'   descriptor, not a game Type, and it masks by the oracle's "both resolve to an address
'   inside their own image" rule like any other absolute operand.
' SetDrawStateHex/SetColourHex are already-verified module Functions (src/recovered_module/);
'   their E8 operands mask by name. Literal "FFFFFF" @0x00C5D680 and "I" @0x00C7DFC0 (the
'   line-height probe glyph) read with harness.read_string(). All Float constants (4.0, three
'   different 2.0's, 10.0 (x2), 14.0, the two 0.3's, three 1.0's) read directly out of
'   NSS5.exe's data section at each masked fld operand -- section 21 of codegen-patterns.md:
'   a MATCH never certifies a masked constant's value, never guessed.
'
' CODEGEN NOTES, in the order they were needed to close the last 4 bytes/2 bytes of diff:
'   - `n * lineh` and `lineh * n` are NOT the same bytes when n is Int and lineh is a
'     spilled Float Local. Int-first (`n * lineh`) lets bcc fuse the promotion straight into
'     `fmul dword [lineh]` (6 bytes). Float-first (`lineh * n`) forces `fld [lineh]; fild
'     [n]; fmulp` (8 bytes) because the memory operand cannot be the second factor of
'     a fused fmul. The multi-line box-height test and its recompute both use the Float-first
'     (8-byte) form; the later `Self.txtlines.Count() * lineh` for the vertical centre uses
'     the Int-first (6-byte) form. Same operator, different source order, different bytes --
'     both are real, just at different call sites.
'   - `If lineh * n > Self.h` (not `If Self.h < lineh * n`): a solo relational condition's
'     LHS is evaluated first, and the original loads `lineh*n` before `Self.h`. Written with
'     Self.h first, bcc reverses the load order and the setcc byte then disagrees too.
'   - `tx = tx + (a1 + 10)` (not `tx = tx + a1 + 10`, which left-associates to `(tx+a1)+10`
'     and costs 2 extra bytes): the original computes `a1 + 10` as its own value and adds it
'     to tx in one instruction.
'   - The vertical-centre line `cy = Int(Self.y + Self.h/2.0 - (Self.txtlines.Count()*lineh)/2.0)`
'     must be ONE expression, not split into named Locals for `Self.y+Self.h/2.0` or for
'     `Self.txtlines` -- either split changes which of {the txtlines pointer, the reloaded
'     Self pointer} lands in eax vs edx (both are same-length, same-shape instructions, just
'     a colour swap) and the two builds disagree on 5 bytes even though everything else about
'     the body already matched. Written as one expression, the allocator's tie-break lines up
'     with the original with no further nudging.
' `Right()` needs BRL.Retro (already imported project-wide for other TGadget files).

	Method DrawGadgetText:Int(a0:String, a1:Int)
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		Self.SetFontSize(Self.fntSize)
		If Self.txtlines <> Null And Not Self.txtlines.IsEmpty()
			Local scale:Float = 1.0
			Local lineh:Float = Float(TextHeight("I"))
			Local n:Int = Self.txtlines.Count()
			If lineh * n > Self.h
				scale = (Self.h - 4.0) / (lineh * n)
				lineh = lineh * scale
			EndIf
			SetScale scale, scale
			Local cx:Int = Int(Self.x + Self.w / 2.0)
			Local cy:Int = Int(Self.y + Self.h / 2.0 - (Self.txtlines.Count() * lineh) / 2.0)
			For Local ln:String = EachIn Self.txtlines
				If Right(ln, 1) = " "
					ln = ln[0..ln.length - 1]
				EndIf
				Local tx:Int = Int(cx - (TextWidth(ln) / 2) * scale)
				SetColor 0, 0, 0
				SetAlpha 0.3 * Self.alph
				If Self.forcetxtalpha <> 0 Then SetAlpha 0.3
				DrawText ln, Float(tx - 1), Float(cy - 1)
				SetColourHex a0
				SetAlpha Self.alph
				If Self.forcetxtalpha <> 0 Then SetAlpha 1.0
				DrawText ln, Float(tx), Float(cy)
				cy = Int(cy + lineh)
			Next
		ElseIf Self.txt.length <> 0
			Local th:Int = TextHeight(Self.txt)
			Local tw:Int = TextWidth(Self.txt)
			Local tx:Int = Int(Self.x)
			Local ty:Int = Int((Self.y - 1.0) + Self.h / 2.0 - th / 2)
			Select Self.txtalignx
			Case 0
				tx = Int(Self.x + 10.0)
				If a1 <> 0 Then tx = tx + (a1 + 10)
			Case 1
				tx = Int(Self.x + Self.w / 2.0 - tw / 2)
				If a1 <> 0
					Local wa:Int = Int(Self.w - a1)
					Local w14:Int = Int(Self.w / 14.0)
					Local diff:Int = wa - w14
					tx = Int(Self.x + a1 + w14)
					tx = tx + (diff / 2 - tw / 2)
				EndIf
			Case 2
				tx = Int(Self.x + Self.w - 10.0 - tw)
			End Select
			SetColor 0, 0, 0
			SetAlpha 0.3 * Self.alph
			If Self.forcetxtalpha <> 0 Then SetAlpha 0.3
			DrawText Self.txt, Float(tx - 1), Float(ty - 1)
			SetColourHex a0
			SetAlpha Self.alph
			If Self.forcetxtalpha <> 0 Then SetAlpha 1.0
			DrawText Self.txt, Float(tx), Float(ty)
			SetColor 255, 255, 255
		EndIf
		SetScale 1.0, 1.0
	End Method

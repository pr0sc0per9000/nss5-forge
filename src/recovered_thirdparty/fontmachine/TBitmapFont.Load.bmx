' TBitmapFont.Load
' VA 0x005900B7   1855 bytes   vtable slot 0x44   sig (:Object,i)i
' byte-identical vs NSS5.exe (1855/1855, mode=reloc, reloc_masked=58, NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Reads a Font Machine .fmf: a flat stream of records, each `Int charcode`, a line naming
' the layer ("SHADOW" / "BORDER" / "FACE"), an Int, an embedded PNG, another Int, and the
' per-character metrics. Nothing here is guessed at the format level -- every read is the
' original's own call sequence, in its order.
'
' ASSUMPTIONS
'  * a0 = the .fmf url (any Object OpenStream accepts), a1 = the image flags handed on to
'    LoadImage. Parameter names are not recoverable; a0.. as emitted.
'  * `OpenStream(a0, 1, 0)` is the literal call (readable, not writeable), not ReadStream:
'    the E8 targets 0x005B7F99 _brl_stream_OpenStream directly.
'  * 0x004A8560 / 0x004A8570 are GCSuspend / GCResume -- inc and dec of the SAME counter
'    at 0x00CF4324, four instructions each. 0x004A9320 is bbExThrow. Both new names were
'    recorded by the oracle's own learn pass and the body then re-verified with
'    NSS5_NO_LEARN=1, so the MATCH is decided by the table, not by the learn.
'
' SHAPE NOTES (each of these changes the bytes):
'  * The three layer tests are a `Select`, not If/ElseIf: the three _bbStringCompare
'    calls are back to back and every target is past the last compare (codegen-patterns
'    10.2). Written as ElseIf it is shorter.
'  * The masked-FACE path must be THREE statements. Written as the single nested
'    expression `LoadImage(MaskPixmap(LoadPixmap(s), ...), 1)` bcc pushes the outer
'    arguments before evaluating the inner call, which interleaves the pushes; the
'    original evaluates each call and passes its result straight out of eax.
'  * `Float(c) / PrivateData.Face.Length` needs the cast. Both operands are Int, so
'    without it bcc emits `idiv` where the original has fild/fild/fdivp.
'  * `PrivateData.Progress <> Null` compiles to a compare against 0x005B95D0, the stock
'    NullFunctionError thrower an un-assigned function field defaults to -- see
'    TPrivateBitmapFont.New.bmx for why that is the field's default and not a body store.
'  * The `100.0` literal appears twice and gets two constant slots; one shared Local
'    would be one slot and a different shape.
'
' BUG (original): in the FACE case SetImageHandle runs BEFORE LoadDrawRenderingData, so
' the handle is set from the PREVIOUS record's DrawOffsetX/Y (zero on the first). SHADOW
' and BORDER do it the other way round and are correct. Preserved.
'
' BUG (original): the widen-to-65536 guard tests `PrivateData.Face.Length <= 256` but then
' widens all three arrays, so a font whose first >255 codepoint arrives while Face is
' already wide leaves Shadow and Border short. Preserved.
'
' The three `s.ReadInt()` / `s.ReadLine()` calls whose results are discarded are the
' original's; they skip fields this loader does not use.

	Method Load:Int(a0:Object, a1:Int)
		Local s:TStream = OpenStream(a0, 1, 0)
		Local lastp:Int = 0
		If s = Null Then Return 0
		GCSuspend()
		While Not s.Eof()
			Local c:Int = s.ReadInt()
			If c > 255 And PrivateData.Face.Length <= 256
				PrivateData.Face = PrivateData.Face[0..65536]
				PrivateData.Border = PrivateData.Border[0..65536]
				PrivateData.Shadow = PrivateData.Shadow[0..65536]
			End If
			If PrivateData.Shadow[c] = Null Then PrivateData.Shadow[c] = New TBitMapChar
			If PrivateData.Border[c] = Null Then PrivateData.Border[c] = New TBitMapChar
			If PrivateData.Face[c] = Null Then PrivateData.Face[c] = New TBitMapChar
			Select s.ReadLine()
			Case "SHADOW"
				s.ReadInt()
				PrivateData.Shadow[c].Image = LoadImage(s, a1)
				PrivateData.Shadow[c].Image.handle_x = 0
				PrivateData.Shadow[c].Image.handle_y = 0
				s.ReadLine()
				If PrivateData.Shadow[c].Image = Null Then Print "ERROR LOADING PNG"
				s.ReadInt()
				PrivateData.Shadow[c].LoadDrawRenderingData(s)
				SetImageHandle(PrivateData.Shadow[c].Image, -PrivateData.Shadow[c].DrawOffsetX, -PrivateData.Shadow[c].DrawOffsetY)
				s.ReadLine()
			Case "BORDER"
				s.ReadInt()
				PrivateData.Border[c].Image = LoadImage(s, a1)
				PrivateData.Border[c].Image.handle_x = 0
				PrivateData.Border[c].Image.handle_y = 0
				s.ReadLine()
				s.ReadInt()
				PrivateData.Border[c].LoadDrawRenderingData(s)
				SetImageHandle(PrivateData.Border[c].Image, -PrivateData.Border[c].DrawOffsetX, -PrivateData.Border[c].DrawOffsetY)
				s.ReadLine()
			Case "FACE"
				s.ReadInt()
				If UseMask = 0
					PrivateData.Face[c].Image = LoadImage(s, a1)
				Else
					Local pm:TPixmap = LoadPixmap(s)
					pm = MaskPixmap(pm, MaskColorRed, MaskColorGreen, MaskColorBlue)
					PrivateData.Face[c].Image = LoadImage(pm, 1)
				End If
				PrivateData.Face[c].Image.handle_x = 0
				PrivateData.Face[c].Image.handle_y = 0
				SetImageHandle(PrivateData.Face[c].Image, -PrivateData.Face[c].DrawOffsetX, -PrivateData.Face[c].DrawOffsetY)
				s.ReadLine()
				s.ReadInt()
				PrivateData.Face[c].LoadDrawRenderingData(s)
				s.ReadLine()
			Default
				GCResume()
				Local ex:TBitmapFontLoadException = New TBitmapFontLoadException
				ex.PrivateData.Description = "Unable to load the bitmapfont due to corrupted or unsuported file format"
				ex.PrivateData.Offending = Self
				Throw ex
			End Select
			If PrivateData.Progress <> Null
				If lastp <> Int(Float(c) / PrivateData.Face.Length * 100.0)
					lastp = c
					PrivateData.Progress(Float(c) / PrivateData.Face.Length * 100.0)
				End If
			End If
		Wend
		s.Close()
		PrivateData.FontLoaded = 1
		GCResume()
	End Method

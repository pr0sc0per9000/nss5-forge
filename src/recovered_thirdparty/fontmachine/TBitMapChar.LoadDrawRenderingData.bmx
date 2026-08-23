' TBitMapChar.LoadDrawRenderingData
' VA 0x00592476   108 bytes   vtable slot 0x30   sig (:Object)i
' byte-identical vs NSS5.exe (108/108, mode=reloc)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Reads one glyph's five metrics off the stream, in field order. TBitmapFont.Load calls it
' once per record with the SAME already-open stream it is reading the font from, so the
' `OpenStream` here re-wraps that stream rather than opening a file (OpenStream returns a
' TStream unchanged), and the trailing Close() closes the wrapper.
'
' This method is why the reflection parser had to learn namespaced signatures: its own
' record sits behind `Image:brl.max2d.TImage` in TBitMapChar's scope, so the old
' TYPE_ATOM truncated the Type before reaching it and this method did not exist as far as
' any of the tooling was concerned. Without it TBitmapFont.Load cannot be written at all,
' and every glyph would draw with zero width at offset 0.
'
' Parameter name is not recoverable; a0 as emitted.

	Method LoadDrawRenderingData:Int(a0:Object)
		Local s:TStream = OpenStream(a0, 1, 0)
		DrawOffsetX = s.ReadInt()
		DrawOffsetY = s.ReadInt()
		DrawWidth = s.ReadInt()
		DrawHeight = s.ReadInt()
		Charwidth = s.ReadInt()
		s.Close()
	End Method

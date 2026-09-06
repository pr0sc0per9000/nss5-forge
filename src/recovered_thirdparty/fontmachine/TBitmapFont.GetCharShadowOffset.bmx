' TBitmapFont.GetCharShadowOffset
' VA 0x00590F9D   142 bytes   vtable slot 0x7C   sig (b):TDrawingPoint
' byte-identical vs NSS5.exe (142/142, mode=reloc)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' The Byte parameter is spilled to its own frame slot ([ebp-4]) by bcc before first use
' (`movzx eax,[ebp+0xC]; mov eax,eax; mov [ebp-4],al`). That is the compiler's own
' parameter handling for a Byte argument, not a source-level Local.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted.
'
' TBitmapFont FIELD LAYOUT -- read ONCE for the whole Type from extracted/object_model.json
' and then confirmed against each individual body's own disassembly:
'   TBitmapFont         Kerning:TFontKerning +0x08, UseMask +0x0C, MaskColorRed +0x10,
'                       MaskColorGreen +0x14, MaskColorBlue +0x18,
'                       PhisicalPixelRounding +0x1C, RenderFX:iTextRendererFXBase +0x20,
'                       PrivateData:TPrivateBitmapFont +0x24
'   TPrivateBitmapFont  Shadow[] +0x08, Border[] +0x0C, Face[] +0x10, Progress:(f)i +0x14,
'                       DrawShadow +0x18, DrawBorder +0x1C, FontLoaded +0x20,
'                       ShadowBlend +0x24, FaceBlend +0x28, BorderBlend +0x2C,
'                       RenderStatus:TRenderStatus +0x30
'   TBitMapChar         DrawOffsetX +0x08, DrawOffsetY +0x0C, DrawWidth +0x10,
'                       DrawHeight +0x14, Charwidth +0x18, Image:TImage +0x1C
'   TRectangle          X +0x08, Y +0x0C, Width +0x10, Height +0x14   (all Float)
'   TDrawingPoint       X +0x08, Y +0x0C                              (both Float)
'
' Reads PrivateData+0x08 (Shadow), confirmed from this body's own disassembly.
'
' This one calls nothing. Both exits do `New TDrawingPoint` (bbObjectNew 0x004A8F20 on
' class table 0x00C97E88) and store X and Y directly, so the missing-glyph path is two
' `fldz`/`fstp` pairs rather than a call with folded zero arguments. Each exit has its
' own Local and the object never leaves eax.
'
' There is NO TBitMapChar Local here -- the `PrivateData.Shadow[a0]` chain is emitted in
' full TWICE, once per coordinate. That is the direct evidence that bcc does no
' common-subexpression elimination on this chain, and hence that the SINGLE chain in
' GetCharBorderOffset and in the three Get*Info bodies has to come from a source-level
' Local rather than from the compiler.
'
	Method GetCharShadowOffset:TDrawingPoint(a0:Byte)
		If PrivateData.Shadow[a0] = Null
			Local p:TDrawingPoint = New TDrawingPoint
			p.X = 0
			p.Y = 0
			Return p
		End If
		Local q:TDrawingPoint = New TDrawingPoint
		q.X = PrivateData.Shadow[a0].DrawOffsetX
		q.Y = PrivateData.Shadow[a0].DrawOffsetY
		Return q
	End Method

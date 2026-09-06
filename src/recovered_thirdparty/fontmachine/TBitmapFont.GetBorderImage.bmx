' TBitmapFont.GetBorderImage
' VA 0x00590CC7   72 bytes   vtable slot 0x60   sig (b):brl.max2d.TImage
' byte-identical vs NSS5.exe (72/72, mode=reloc)
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
' One of three near-identical 72-byte getters. This one reaches PrivateData+0x0C
' (Border); the offset is read from THIS body's disassembly, not assumed from the
' stride of its siblings.
'
	Method GetBorderImage:TImage(a0:Byte)
		If PrivateData.Border[a0] = Null Then Return Null
		Return PrivateData.Border[a0].Image
	End Method

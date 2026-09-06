' TBitmapFont.GetFaceInfo
' VA 0x00590D57   132 bytes   vtable slot 0x68   sig (b):TRectangle
' byte-identical vs NSS5.exe (132/132, mode=reloc)
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
' One of three near-identical 132-byte getters. This one reaches PrivateData+0x10
' (Face); the offset is read from THIS body's disassembly, not assumed from the
' stride of its siblings.
'
' SHAPE. `New TRectangle` (bbObjectNew 0x004A8F20 on TRectangle's class table 0x00C97DB0)
' is emitted BEFORE the array lookup, so the TRectangle Local is declared first. The
' TBitMapChar Local is real and not compiler CSE: the `PrivateData.Face[a0]` chain costs 16
' bytes and appears exactly ONCE after the null test, where writing it out in all four
' assignments would add 48 and overshoot 132. Neither Local takes a frame slot -- the
' 8-byte frame is the spilled Byte param at [ebp-4] plus the Int->Float conversion temp at
' [ebp-8] that every `fild dword`/`fstp dword` pair goes through; both objects live in
' registers (eax, ecx).
'
' The four source fields are Int on TBitMapChar and Float on TRectangle, which is what the
' four fild/fstp pairs are. That widening is implicit in the source, not a written cast.
'
	Method GetFaceInfo:TRectangle(a0:Byte)
		If PrivateData.Face[a0] = Null Then Return Null
		Local r:TRectangle = New TRectangle
		Local c:TBitMapChar = PrivateData.Face[a0]
		r.X = c.DrawOffsetX
		r.Y = c.DrawOffsetY
		r.Width = c.DrawWidth
		r.Height = c.DrawHeight
		Return r
	End Method

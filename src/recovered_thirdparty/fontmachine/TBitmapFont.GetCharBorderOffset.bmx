' TBitmapFont.GetCharBorderOffset
' VA 0x00590F2B   114 bytes   vtable slot 0x78   sig (b):TDrawingPoint
' byte-identical vs NSS5.exe (114/114, mode=reloc)
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
' Reads PrivateData+0x0C (Border), confirmed from this body's own disassembly.
'
' Builds its result through the module Function Fn_00592A13 (`call 0x00592A13`, the
' one-line wrapper over TDrawingPoint.Create -- see Fn_00592A13.bmx), NOT through
' TDrawingPoint.Create directly and NOT with an inline `New TDrawingPoint`. Its sibling
' GetCharShadowOffset does the opposite on both counts; that asymmetry is in the
' original source, not a codegen artefact, and it is why two functions doing the same
' job differ by 28 bytes.
'
' The missing-glyph path is `Fn_00592A13(0, 0)`: bcc folds the two Float 0.0 arguments
' to `push 0` / `push 0` rather than emitting fldz/fstp.
'
' The TBitMapChar Local is real -- the lookup chain is emitted once and held in edx
' across both `sub esp,4; fstp [esp]` argument pushes.
'
	Method GetCharBorderOffset:TDrawingPoint(a0:Byte)
		If PrivateData.Border[a0] = Null Then Return Fn_00592A13(0, 0)
		Local c:TBitMapChar = PrivateData.Border[a0]
		Return Fn_00592A13(c.DrawOffsetX, c.DrawOffsetY)
	End Method

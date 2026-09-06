' TDrawingPoint.Clone
' VA 0x005929F9   26 bytes   vtable slot 0x34   sig ():TDrawingPoint
' byte-identical vs NSS5.exe (26/26, mode=reloc, reloc_masked=1)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Same shape as TRectangle.Clone: the two fields are pushed into the module-level
' wrapper Fn_00592A13 (an `E8 rel32`), not into TDrawingPoint.Create.

	Method Clone:TDrawingPoint()
		Return Fn_00592A13(X, Y)
	End Method

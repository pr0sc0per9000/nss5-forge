' TRectangle.Clone
' VA 0x00592947   32 bytes   vtable slot 0x34   sig ():TRectangle
' byte-identical vs NSS5.exe (32/32, mode=reloc, reloc_masked=1)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' The four fields go out as a right-to-left push run into the module-level wrapper
' Fn_00592967, not into TRectangle.Create directly: the call is `E8 rel32`, a direct
' call to module code, where a `TRectangle.Create(...)` written here would compile to
' `call dword ptr [classtable+0x30]`.

	Method Clone:TRectangle()
		Return Fn_00592967(X, Y, Width, Height)
	End Method

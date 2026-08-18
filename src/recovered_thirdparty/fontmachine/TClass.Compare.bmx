' TClass.Compare
' VA 0x00592F5D   39 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (39/39)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method Compare:Int(a0:Object)
		Return _class - TClass(a0)._class
	End Method

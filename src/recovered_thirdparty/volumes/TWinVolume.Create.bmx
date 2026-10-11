' TWinVolume.Create
' VA 0x005983C8   22 bytes   vtable slot 0x58   sig ():TWinVolume
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (22/22, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' bbObjectNew(0x00C9AE88) and return. The 1.06 Local `this` is kept: a Local object
' is not refcounted, so it emits the same 22 bytes as `Return New TWinVolume`.
	Function Create:TWinVolume()
		Local this:TWinVolume = New TWinVolume

		Return this
	End Function

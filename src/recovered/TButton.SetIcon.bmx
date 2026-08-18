' TButton.SetIcon
' VA 0x005154F7   77 bytes   vtable slot 0x90   sig (:TImage)i
' byte-identical vs NSS5.exe (77/77, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' The trailing GCCollect() is real: the original ends with a bare 5-byte E8 into the GC helper
'   at 0x004A8650 with no arguments and no stack cleanup.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TImage -> BRL.Max2D. Without it the
'   harness emits a local placeholder `Type TImage` that shadows BRL.Max2D's, and the probe
'   fails to build with "Unable to convert from 'TImage' to 'TImage'".

	Method SetIcon:Int(a0:TImage)
		icon = a0
		If a0 <> Null Then MidHandleImage(icon)
		GCCollect()
	End Method

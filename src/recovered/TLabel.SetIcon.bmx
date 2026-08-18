' TLabel.SetIcon
' VA 0x0051A348   72 bytes   vtable slot 0x8C   sig (:TImage)i
' byte-identical vs NSS5.exe (72/72, original length from Ghidra's inventory), harness mode=reloc
' Assumptions:
'   * field `icon` at +0x68 (object model). The retain/release around the store is the
'     compiler-inlined BBRETAIN/BBRELEASE, not source.
'   * MidHandleImage = BRL call at 0x005AE38D.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TImage -> BRL.Max2D, exactly as
'   TButton.SetIcon already records. Without it the probe fails to build with
'   "Unable to convert from 'TImage' to 'TImage'".
	Method SetIcon:Int(a0:TImage)
		icon = a0
		If a0 <> Null Then MidHandleImage(icon)
	End Method

' TButton.SetImage
' VA 0x00515489   110 bytes   vtable slot 0x8C   sig (:TImage)i
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory), harness mode=reloc
' Assumptions:
'   * fields: image +0x60, imageoverride +0x64 (TButton); w +0x2C, h +0x28 (inherited TGadget).
'   * 0x005AE3C5 / 0x005AE3D4 are BRL alias sets; ImageWidth / ImageHeight are the members
'     that fit -- the results are converted with fild into the Float w/h fields.
'   * MidHandleImage = 0x005AE38D.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TImage -> BRL.Max2D.
	Method SetImage:Int(a0:TImage)
		image = a0
		imageoverride = 1
		w = ImageWidth(a0)
		h = ImageHeight(a0)
		MidHandleImage(image)
	End Method

' TButton.SetButtonStyle
' VA 0x00515544   108 bytes   vtable slot 0x94   sig (i)i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=4, NSS5_NO_LEARN=1, no learned helpers.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'  * fields: bstyle +0x5C, image +0x60 (TButton); h +0x28, w +0x2C (inherited TGadget) --
'    same layout the verified TButton.SetImage relies on.
'  * 0x0051AC96 = CreateGadgetImage (src/recovered_module/, 1787/1787 exact). Its five
'    arguments are pushed right-to-left as 0, 1, [ebx+0x5C], Int(h), Int(w).
'  * 0x005B9690 = _bbFloatToInt, so both fld/fstp-qword pairs are Int(Float) conversions of
'    the Float fields h and w -- NOT float arguments. 0x004A8590 = _bbGCFree; the
'    retain / dec-and-free / store around +0x60 is bcc's inlined BBRELEASE for the field
'    assignment, not source.
'  * The guard tests the PARAMETER, not the field: `cmp eax,0xA` reuses the register still
'    holding a0 rather than re-reading [ebx+0x5C], so it is `If a0 <> 10` even though the
'    assignment to Self.bstyle happens first. The builder call then does re-read the field.
'  * No Globals used.
	Method SetButtonStyle:Int(a0:Int)
		bstyle = a0
		If a0 <> 10
			image = CreateGadgetImage(Int(w), Int(h), bstyle, 1, 0)
		EndIf
	End Method

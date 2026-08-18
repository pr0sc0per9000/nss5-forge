' TPanel.CreateBody
' VA 0x0051964F   84 bytes   vtable slot 0x8C   sig (i,i)i
' byte-identical vs NSS5.exe (84/84, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=3, NSS5_NO_LEARN=1, no learned helpers.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'  * fields: bodyimage +0x60 (TPanel); w +0x2C (inherited TGadget) -- same layout the
'    verified TButton.SetButtonStyle relies on.
'  * 0x0051AC96 = CreateGadgetImage (src/recovered_module/, 1787/1787 exact); its arguments
'    are w=Int(Self.w), h=a0, style=a1, button=0, savepng=0.
'  * 0x005B9690 = _bbFloatToInt (Int(Self.w)); 0x004A8590 = _bbGCFree, the retain/
'    dec-and-free/store around bodyimage is bcc's inlined BBRELEASE for the field
'    assignment, not source.
	Method CreateBody:Int(a0:Int, a1:Int)
		bodyimage = CreateGadgetImage(Int(w), a0, a1, 0, 0)
	End Method

' TPitchMark.Render
' VA 0x004EA2A9   180 bytes   vtable slot 0x3C   sig ()i
' byte-identical vs NSS5.exe (180/180, original length from Ghidra's inventory, mode=reloc)
' assumptions: Global 0x00C5D9AC TList (it is called at slot 0x8C = ObjectEnumerator),
' Global 0x00C5D9B0 TImage (first argument of AddDrawOb).
' PTR_FUN_00C5B1B4 resolves to TDrawOb class table + slot 0x34 =
' TDrawOb.AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i).
' Literals read out of .rdata: 0x00C5D680 = "FFFFFF", 0x005C7D40 = "" (bbEmptyString).
' The `if (puVar3 != Null)` guard Ghidra prints is the null-skip that For..EachIn emits by
' itself -- writing it explicitly would add bytes.
	Function Render:Int()
		'!Global g_pitchmarks:TList
		'!Global g_pitchmarkimage:TImage
		For Local m:TPitchMark = EachIn g_pitchmarks
			TDrawOb.AddDrawOb(g_pitchmarkimage, m.x, m.y, 1.0, m.frm, 0, m.a, m.rot, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
		Next
	End Function

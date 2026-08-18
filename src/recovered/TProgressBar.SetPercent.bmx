' TProgressBar.SetPercent
' VA 0x0051aba1   100 bytes   vtable slot 0x8c   sig (f,i)i
' byte-identical vs NSS5.exe (100/100, original length from Ghidra's inventory)
' assumptions: field names/offsets from extracted/object_model.json (percent +0x6c,
' livepercent +0x70, oldpercent +0x74, oldfillalpha +0x7c, oldfillfade +0x80);
' 0x00505F90 = recovered module Function ClampFloat (Float Ptr form).
' The branch is If a1 <> 0 ... Else -- the reversed form emits je/jmp and is 100 bytes;
' the If a1 = 0 form emits jne and mismatches at byte 16.
	Method SetPercent:Int(a0:Float, a1:Int)
		If a1 <> 0
			percent = a0
			livepercent = a0
		Else
			oldpercent = percent
			oldfillfade = 1
			oldfillalpha = 1.0
			percent = a0
		EndIf
		ClampFloat(Varptr percent, 0, 100)
		ClampFloat(Varptr oldpercent, 0, 100)
	End Method

' TProgressBar.Update
' VA 0x0051a5f3   256 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (256/256, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_005B9690 = _bbFloatToInt, emitted by Int(x).  FUN_00505F6D =
'   recovered module Function ClampInt(*i,i,i).  Globals 0x00C7E260 / 0x00C7E264 are
'   Floats (x87 dword access).
'   The guard is an early return (cmp/je body + mov eax,0/jmp), not an enclosing If.
'   Operand ORDER is byte-observable on the two float tests: the second one loads
'   livepercent (+0x70) first, so it is "livepercent > percent", not "percent < livepercent"
'   -- the latter is the same length but differs at byte 159.
	Method Update:Int()
		' g_pbf1/g_pbf2 original data-section values are 0.03 / 0.0025
		' (0x00C7E260 / 0x00C7E264). Never stored to anywhere in the corpus -- see
		' codegen-patterns 21.1.
		'!Global g_pbf1:Float = 0.03
		'!Global g_pbf2:Float = 0.0025
		If Self.hidden Then Return 0
		Local d:Int = Int(Self.percent - Self.livepercent)
		If d < 0 Then d = Int(Self.livepercent - Self.percent)
		Local sp:Int = Int(Float(d) * g_pbf1)
		ClampInt(Varptr sp,1,5)
		If Self.livepercent < Self.percent Then Self.livepercent = Self.livepercent + Float(sp)
		If Self.livepercent > Self.percent Then Self.livepercent = Self.livepercent - Float(sp)
		If Self.oldfillalpha > 0.0 And Self.oldfillfade
			Self.oldfillalpha = Self.oldfillalpha - g_pbf2
		EndIf
	End Method

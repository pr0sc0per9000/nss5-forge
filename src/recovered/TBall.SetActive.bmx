' TBall.SetActive
' VA 0x004C8004   193 bytes   vtable slot 0x40   sig (:TBall)i   KIND=Function (static)
' byte-identical vs NSS5.exe (193/193, mode=reloc, reloc_masked=9)
'
' ASSUMPTIONS (module Global names are ours; the DECLARED TYPES are load-bearing):
'   g_balls      = 0x00C5A4C0  TList  (slot 0x8C ObjectEnumerator at the call site)
'   g_activeball = 0x00C5DEA4  TBall  (see codegen-patterns 11.2 -- globals_final says
'                                      TPlayer, the code says TBall)
' The guard is the `If Not x` emission (setne/movzx/cmp/jne, codegen-patterns 10.3)
' in EARLY-RETURN form.

	Function SetActive:Int(a0:TBall)
		'!Global g_balls:TList
		'!Global g_activeball:TBall
		If Not g_balls Then Return 0
		For Local b:TBall = EachIn g_balls
			If b <> a0
				b.ResetControllers()
				b.active = 0
			EndIf
		Next
		a0.active = 1
		g_activeball = a0
	End Function

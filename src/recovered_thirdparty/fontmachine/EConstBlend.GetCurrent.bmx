' EConstBlend.GetCurrent
' VA 0x00592281   14 bytes   sig ()i   (Function, no Self)
' byte-identical vs NSS5.exe (14/14, verified via try_function)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Same root-Type gap as EConstBlend.Delete (see that file's header): no class_tables.tsv
' row, object_model.json's offset (5841537 = 0x00592281) is the raw VA, and try_method
' cannot locate it. Verified with harness.try_function using the real VA and the plain-
' Function wrapper (no dotted name passed in -- try_function rejects those -- the identity
' below is recovered separately from object_model.json, not from the probe).
'
' Body: calls extracted/callgraph_resolved.tsv-confirmed target 0x005adc17 =
' `_brl_max2d_GetBlend` (extracted/brl_functions.tsv:512, max2d.release.win32.x86.a) with
' zero arguments -- i.e. BRL.Max2D's GetBlend().

	Function GetCurrent:Int()
		Return GetBlend()
	End Function

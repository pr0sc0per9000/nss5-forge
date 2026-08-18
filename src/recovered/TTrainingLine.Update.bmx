' TTrainingLine.Update
' VA 0x0058406d   107 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (107/107, original length from Ghidra's inventory)
' early-return guard is required (wrapping the body in 'If alive' is 7 bytes short). alive/alph are the inherited TTrainingObject fields at 0x18/0x1c.
' CONSTANT CORRECTED: the multiplier was written 0.0005 as a guess (relocation-
'   masked .rdata address). scripts/check_floats.py + direct disassembly (code offset +53)
'   show the exe holds 0.001. The second constant, 2.0 in `alph = 2.0 - alph` (code offset
'   +85), was already correct -- confirmed by direct read, not flagged as it agreed.
'   Re-verified MATCH 107/107.
	Method Update:Int()
		'!Global g_gametime:Int
		If alive = 0 Then Return 0
		CheckSplit()
		alph = (g_gametime Mod 2000) * 0.001
		If alph > 1.0
			alph = 2.0 - alph
		EndIf
	End Method

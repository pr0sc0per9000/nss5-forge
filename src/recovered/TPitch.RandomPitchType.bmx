' TPitch.RandomPitchType
' VA 0x004E5F33   48 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Globals at 0x00c5d62c / 0x00c5d630 declared Int.
' FUN_0059f089 = _brl_random_Rand (brl_functions.tsv).

	Function RandomPitchType:Int()
		'!Global g_pitchtype:Int
		'!Global g_pitchcond:Int
		g_pitchtype=Rand(0,2)
		g_pitchcond=Rand(0,5)
	End Function

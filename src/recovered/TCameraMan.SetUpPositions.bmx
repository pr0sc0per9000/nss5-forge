' TCameraMan.SetUpPositions
' VA 0x004EB4AB   399 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (399/399, original length from Ghidra's inventory, mode=reloc)
' ASSUMPTION: five module Globals, ALL declared Int (names from globals_named.tsv):
'   g_cameraman_int01 @ 0x00C5DCB0   g_cameraman_int02 @ 0x00C5DCB4
'   g_cameraman_int03 @ 0x00C5DCB8   g_cameraman_int04 @ 0x00C5DCBC
'   g_pitch_int21     @ 0x00C5D69C
' They are Int and not Float: the original emits 'mov eax,[g] / neg eax /
' mov [ebp-4],eax / fild [ebp-4]' -- an integer-to-float conversion through a
' stack slot -- for every one of the sixteen arguments.
' Create(f,f) is TCameraMan's own Type Function; bcc reaches it indirectly
' through the class table (call dword ptr [0x00C5DDF4] = TCameraMan table + 0x34).
'
' Verified from scratch with the five '!Global pragmas below ->
' MATCH 399/399, reloc_masked=26. A BUILD_FAIL without them is a harness
' limitation (it cannot bind a Global from prose alone), not a body defect.
	Function SetUpPositions:Int()
		'!Global g_cameraman_int01:Int
		'!Global g_cameraman_int02:Int
		'!Global g_cameraman_int03:Int
		'!Global g_cameraman_int04:Int
		'!Global g_pitch_int21:Int
		Create(-g_cameraman_int01, -g_cameraman_int02)
		Create(-g_cameraman_int01, g_cameraman_int02)
		If g_pitch_int21 > 0
			Create(g_cameraman_int01, -g_cameraman_int02)
			Create(g_cameraman_int01, g_cameraman_int02)
		EndIf
		If g_pitch_int21 > 1
			Create(-g_cameraman_int03, -g_cameraman_int04)
			Create(g_cameraman_int03, -g_cameraman_int04)
			Create(-g_cameraman_int03, g_cameraman_int04)
			Create(g_cameraman_int03, g_cameraman_int04)
		EndIf
	End Function

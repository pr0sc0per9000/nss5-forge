' TEngine.ResetStats
' VA 0x004D7BA9   190 bytes   vtable slot 0xfc   sig ()i
' byte-identical vs NSS5.exe (190/190, original length from Ghidra's inventory)
' 18 module globals; the first two are x87 Float, the remaining 16 Int.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_engine_float07:Float
'   Global g_engine_float08:Float
'   Global g_engine_int29:Int
'   Global g_engine_int30:Int
'   Global g_engine_int31:Int
'   Global g_engine_int32:Int
'   Global g_engine_int33:Int
'   Global g_engine_int34:Int
'   Global g_engine_int35:Int
'   Global g_engine_int36:Int
'   Global g_engine_int37:Int
'   Global g_engine_int38:Int
'   Global g_engine_int39:Int
'   Global g_engine_int40:Int
'   Global g_engine_int41:Int
'   Global g_engine_int42:Int
'   Global g_engine_int43:Int
'   Global g_engine_int44:Int

	Function ResetStats:Int()
		'!Global g_engine_float07:Float
		'!Global g_engine_float08:Float
		'!Global g_engine_int29:Int
		'!Global g_engine_int30:Int
		'!Global g_engine_int31:Int
		'!Global g_engine_int32:Int
		'!Global g_engine_int33:Int
		'!Global g_engine_int34:Int
		'!Global g_engine_int35:Int
		'!Global g_engine_int36:Int
		'!Global g_engine_int37:Int
		'!Global g_engine_int38:Int
		'!Global g_engine_int39:Int
		'!Global g_engine_int40:Int
		'!Global g_engine_int41:Int
		'!Global g_engine_int42:Int
		'!Global g_engine_int43:Int
		'!Global g_engine_int44:Int
		g_engine_float07 = 0
		g_engine_float08 = 0
		g_engine_int29 = 0
		g_engine_int30 = 0
		g_engine_int31 = 0
		g_engine_int32 = 0
		g_engine_int33 = 0
		g_engine_int34 = 0
		g_engine_int35 = 0
		g_engine_int36 = 0
		g_engine_int37 = 0
		g_engine_int38 = 0
		g_engine_int39 = 0
		g_engine_int40 = 0
		g_engine_int41 = 0
		g_engine_int42 = 0
		g_engine_int43 = 0
		g_engine_int44 = 0
	End Function

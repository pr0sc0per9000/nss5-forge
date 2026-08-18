' TSnowFlake.SetUp
' VA 0x00505494   189 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (189/189, original length from Ghidra's inventory, mode=reloc)
' Assumes six module Globals (original names unrecoverable):
'   g_snow_img:TImage  (0x00C6021C)   g_snow_list:TList  (0x00C60220)
'   g_snow_alph:Float  (0x00C6022C) -- stored as the immediate 0x3F800000 = 1.0
'   g_snow_i2:Int      (0x00C60230)   g_snow_wind:Float  (0x00C60234) = Rnd(lo,hi)
'   g_snow_count:Int   (0x00C6EFE4)
' CONSTANTS CORRECTED: Rnd() was written Rnd(-0.25, 0.25) as a placeholder (the
'   oracle masks the .rdata ADDRESS of both args, so any pair of the right length matched
'   equally). scripts/check_floats.py flagged the first-pushed arg (code offset +105, our
'   0.25 vs the original's 0.005) directly; hand-reading the exe at the second arg's address
'   (0x00C7BAC8, code offset +117) showed it too is wrong (ours -0.25, original 0.001) --
'   check_floats.py's own conservative classifier had excluded it as a false-positive
'   "Global" (present in extracted/globals_final.tsv, which is wrong about this address).
'   Original call is Rnd(0.001, 0.005). Re-verified MATCH 189/189.
' The LoadImageChecked() path is a .rdata String constant; relocation-masked, unaffected.
' 0x004BC372 = LoadImageChecked($,i):TImage (src/recovered_module)
' 0x005B40BF = CreateList()   0x0059F048 = Rnd()
' 0x00C60408 = TSnowFlake own class table + 0x?? = TSnowFlake.Create()
	Function SetUp:Int()
		'!Global g_snow_img:TImage
		'!Global g_snow_list:TList
		'!Global g_snow_alph:Float
		'!Global g_snow_i2:Int
		'!Global g_snow_wind:Float
		'!Global g_snow_count:Int
		g_snow_img = LoadImageChecked("EngineMedia/Match/Pitch/Snow.png", -1)
		g_snow_list = CreateList()
		g_snow_alph = 1.0
		g_snow_i2 = 0
		g_snow_wind = Rnd(0.001, 0.005)
		For Local i:Int = 0 To g_snow_count / 6
			TSnowFlake.Create()
		Next
	End Function

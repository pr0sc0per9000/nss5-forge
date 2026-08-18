' TRoulette.SetUp  (KIND=Function -- static)
' VA 0x00575511   293 bytes   sig ()i
' byte-identical vs NSS5.exe (293/293, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS.  0x00C6BBCC/D0/D4 are TSound (globals_final.tsv
' calls them untyped Object).  0x00C6E950 is a String path prefix; the table calls it Int.
' decomp_annotated prints `if (PTR_DAT_00c6bbcc == Null)` but the bytes are
' cmp/setne/movzx/cmp/jne -- the 21-byte `If Not` form.  `= Null` is 9 bytes short.
'!Global g_roulette_wheel:TRouletteWheel
'!Global g_roulette_ball:TRouletteBall
'!Global g_roulette_sndland:TSound
'!Global g_roulette_sndhit:TSound
'!Global g_roulette_sndspin:TSound
'!Global g_mediaPrefix:String
g_roulette_wheel = TRouletteWheel.Create()
g_roulette_ball = TRouletteBall.Create()
If Not g_roulette_sndland
	g_roulette_sndland = LoadSoundChecked(g_mediaPrefix + "GameMedia/Sounds/Casino/RouletteLand.ogg", 0)
	g_roulette_sndhit = LoadSoundChecked(g_mediaPrefix + "GameMedia/Sounds/Casino/RouletteHit.ogg", 0)
	g_roulette_sndspin = LoadSoundChecked(g_mediaPrefix + "GameMedia/Sounds/Casino/RouletteSpin.ogg", 1)
EndIf

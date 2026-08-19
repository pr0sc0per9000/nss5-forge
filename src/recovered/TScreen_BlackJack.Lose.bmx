' TScreen_BlackJack.Lose
' VA 0x00576B77   34 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Globals assumed (names ours, types load-bearing):
'   Global g_snd_lose:TSound      (BRL.Audio TSound)
'   Global g_chan_sfx:TChannel    (BRL.Audio TChannel)
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TSound/TChannel -> BRL.Audio,
'   otherwise the local placeholder Types shadow BRL's and the probe will not build.

	Function Lose:Int()
		'!Global g_snd_lose:TSound
		'!Global g_object859:TChannel
		PlaySound(g_snd_lose, g_object859)
	End Function

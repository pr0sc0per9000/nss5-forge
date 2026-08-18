' TRouletteBall.Reset
' VA 0x00575ed2   126 bytes   vtable slot 0x34   sig (:TRouletteWheel)i
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' harness mode=reloc.
' HARNESS NOTE: needs harness.MODULE_TYPES patched with TSound -> BRL.Audio and
'   TChannel -> BRL.Audio, exactly as TButton.SetIcon needed TImage -> BRL.Max2D.
'   Without it the harness emits local placeholder Types that shadow BRL's and the
'   probe fails to build with "Unable to convert from 'TSound' to 'TSound'".
' FUN_0059f089 = _brl_random_Rand; Rand(360) compiles to Rand(360,1).
' float constants read from the image: 0x00c90b78 = -6.0, 0x00c90b7c = -0.06.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_roulette_snd:TSound      ' 0x00c6bbd4
'   Global g_roulette_chan:TChannel   ' 0x00c6f090
'   Global g_rouletteball_int:Int     ' 0x00c6be5c
	Method Reset:Int(a0:TRouletteWheel)
		'!Global g_rouletteball_int:Int
		'!Global g_roulette_snd:TSound
		'!Global g_roulette_chan:TChannel
		fLineRot = Rand(360)
		fSpeed = -6.0
		fDist = a0.iRimSize / 2
		fVel = -0.06
		g_rouletteball_int = 0
		bStopped = 0
		PlaySound(g_roulette_snd, g_roulette_chan)
	End Method

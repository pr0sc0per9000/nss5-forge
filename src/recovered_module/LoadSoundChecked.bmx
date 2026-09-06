' LoadSoundChecked  -- module-level Function (no Type)
' VA 0x004bc564   256 bytes   sig ($,i):TSound
' NOT byte-identical AS COMPILED, and deliberately so: this file carries a BOOT SHIM.
' Measured, harness.try_function under NSS5_NO_LEARN=1, against the body this file
' actually compiles:
'     MISMATCH   our_len=253  orig_len=256  first_diff=+6
'
' THE ORIGINAL BODY IS RECONSTRUCTED AND PROVEN. Restore the two DebugStops -- and note
' the branches are NOT symmetric, which is what the length turns on:
'     "cannot see sound" branch  ->  DebugStop  then  Return Null
'     "could not be loaded"      ->  DebugStop  (falls through to Return snd)
' changing nothing else, and the same oracle reports
'     MATCH  256/256  mode=reloc  reloc_masked=25
'
' So the 256 bytes are recovered work and the shipped build declines to use them. Counted
' by scripts/progress.py under VERIFIED_ORIGINAL_SUBSTITUTED: out of the headline (which
' measures what the tree compiles) and into the separately-labelled reconstruction figure.
'
' ############################################################################
' # DELIBERATE DIVERGENCE FROM THE ORIGINAL -- BOOT SHIM.                    #
' # Both DebugStops are removed. Restore the two branches above to get the   #
' # original behaviour back. This file is in src/recovered_module/, which    #
' # scripts/reverify.py does not walk -- scripts/reverify_module.py does,    #
' # and it is what caught this marker.                                       #
' ############################################################################
'
' NAME AND GLOBAL NAMES ARE OURS. Third member of the asset-loader family, alongside
' LoadImageChecked (0x004BC372) and LoadAnimImageChecked (0x004BC664): same path
' resolution, same "incbin" bypass, same four-message logging shape, differing only in the
' literals and the loader called.
' The first guard operand is the SAVE root 0x00C6E9A8, not a second install root:
' 0x004BC586 pushes it, and the install root 0x00C6E950 is the second operand.
' src/recovered_module/LoadImageChecked.bmx carries the full evidence and the reason the
' g_pathPrefix spelling silently tested the install root twice.
'!Global g_userpath:String
'!Global g_dataDir:String
' 0x005B9660 IDENTIFIED: brl.blitz DebugStop, NOT GCCollect. Spelling it GCCollect reaches
'   MATCH only because the harness LEARNS the operand from this very body -- circular. With
'   DebugStop it is MATCH under NSS5_NO_LEARN=1 with no learning at all.
'   The evidence is independent of any game body:
'     1. 0x005B9660 is 20 bytes and byte-identical to our own brl.blitz build
'        (___bb_blitz_blitz+0x3c4) except bytes 6-7, the relocated operand of its FF 15.
'     2. brl.blitz declares  Global OnDebugStop()="bbOnDebugStop"  -- a function-POINTER
'        Global, which is exactly what compiles to  call dword ptr [abs]  rather than E8.
'        Function DebugStop() / OnDebugStop / End Function is the only body in brl.blitz
'        with this shape, and it is 20 bytes.
'     3. GCCollect is ruled OUT: brl.blitz declares  Function GCCollect()="bbGCCollect" ,
'        an extern alias, so it compiles to a DIRECT call to the C symbol and can never be
'        a 20-byte BlitzMax wrapper.
'     4. helper_map.brl_table() independently already carried 0x005b9660=_brl_blitz_DebugStop.
'   The discrimination is real in both directions: TButton.SetIcon and TEngine.EndMatch
'   MATCH with GCCollect and MISMATCH with DebugStop, so this is not a case where either
'   spelling would pass.
' THE PREDICATE IS .Contains, NOT .StartsWith. extracted/runtime_helpers.tsv named
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and that wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row right, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Function LoadSoundChecked:TSound(a0:String, a1:Int)
		Local snd:TSound
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_userpath) And Not a0.Contains(g_dataDir)
				a0 = g_dataDir + a0
			End If
			If FileType(a0) = 1
				LogLine("Loading sound: " + a0)
			Else
				LogLine("WARNING! >>>>>>>>>>>> Cannot see sound: " + a0)
				' BOOT SHIM: DebugStop removed -- it halts every -d build on the first
				' missing asset, and missing assets are expected while functions are stubs.
				' The WARNING/ERROR LogLine above still names the file.
				Return Null
			End If
		End If
		snd = LoadSound(a0, a1)
		If snd <> Null
			LogLine("Sound loaded")
		Else
			LogLine("ERROR! >>>>>>>>>>>>>> Sound could not be loaded: " + a0)
			' BOOT SHIM: DebugStop removed -- it halts every -d build on the first
			' missing asset, and missing assets are expected while functions are stubs.
			' The WARNING/ERROR LogLine above still names the file.
			Return Null
		End If
		Return snd
	End Function

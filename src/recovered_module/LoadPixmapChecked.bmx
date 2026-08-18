' LoadPixmapChecked  -- module-level Function (no Type)
' VA 0x004bc46d   247 bytes   sig ($):TPixmap
' byte-identical vs NSS5.exe (247/247, original length from Ghidra's inventory, mode=reloc)
'
' NAME AND GLOBAL NAMES ARE OURS. Fourth member of the asset-loader family, alongside
' LoadImageChecked (0x004BC372), LoadSoundChecked (0x004BC564) and LoadAnimImageChecked
' (0x004BC664): same path resolution, same "incbin" bypass, same four-message logging shape.
' Differs from the others in taking no flags parameter and in NOT calling GCCollect on the
' "cannot see" path -- confirmed by length (247, not 251).
'
' The loader is brl.pngloader's LoadPixmapPNG, NOT brl.pixmap's LoadPixmap. With
' LoadPixmap(a0) the body is the right length (247) and every byte agrees except the four
' operand bytes of that one E8; with LoadPixmapPNG(a0) it is exact. 0x0059BFED is named
' _brl_pngloader_LoadPixmapPNG in brl_functions.tsv and the game calls it directly.
'!Global g_pathPrefix:String
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
	Function LoadPixmapChecked:TPixmap(a0:String)
		Local pix:TPixmap
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_pathPrefix) And Not a0.Contains(g_dataDir)
				a0 = g_dataDir + a0
			End If
			If FileType(a0) = 1
				LogLine("Loading pixmap: " + a0)
			Else
				LogLine("WARNING! >>>>>>>>>>>> Cannot see pixmap: " + a0)
				Return Null
			End If
		End If
		pix = LoadPixmapPNG(a0)
		If pix <> Null
			LogLine("Pixmap loaded")
		Else
			LogLine("ERROR! >>>>>>>>>>>>>> Pixmap could not be loaded: " + a0)
			DebugStop
		End If
		Return pix
	End Function

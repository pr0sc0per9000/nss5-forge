' LoadImageChecked  -- module-level Function (no Type)
' VA 0x004bc372   251 bytes   sig ($,i):TImage
' byte-identical vs NSS5.exe (251/251, mode=reloc, reloc_masked=24, harness.try_function
' under NSS5_NO_LEARN=1). The original body: no boot shim.
'
' NAME AND GLOBAL NAMES ARE OURS. On the BOOT PATH: called 12 times from the module body
' at 0x004BA034, and gates 8 further functions.
'
' The "incbin" test is the asset system showing through -- embedded resources skip the
' filesystem check entirely, which matches the nine incbin'd assets extracted from the exe.
' GCCollect is confirmed by length: without that call the body is 246 bytes, with it 251.
' THE FIRST GUARD OPERAND IS THE SAVE ROOT, 0x00C6E9A8, NOT A SECOND INSTALL ROOT.
' Read out of the original: 0x004BC394 `ff35a8e9c600 push dword ptr [0xc6e9a8]` is the first
' _bbStringContains argument, 0x004BC3B1 `ff3550e9c600 push dword ptr [0xc6e950]` is the
' second, and the concat that builds the fallback path at 0x004BC3CF pushes 0xc6e950, which
' is what fixes 0x00C6E950 as g_dataDir. The four sibling loaders push the same pair in the
' same order (0x004BC68A/0x004BC6A7, 0x004BC586/0x004BC5A3, 0x004BC799/0x004BC7B6,
' 0x004BC48C/0x004BC4A9).
' The name g_pathPrefix stands for 0x00C6E950 in the rest of the corpus (THorse.Create,
' TCard.CreateCard), and extracted/global_alias_map.tsv:249 resolves it there, so one
' identifier covered two slots and the assembler emitted one variable for both. Spelled that
' way the guard tests the install root twice and has no save-root arm, so a path already
' under the user's save directory gets the install root prepended and the open fails. Every
' asset asked of these loaders today is install-relative and the second arm catches all of
' them, which is why nothing is observably wrong; it stops being true the moment anything
' loads an asset out of the save root. 0x00C6E9A8 is g_userpath in TOptions.SetUp,
' TOptions.WriteNewOptionsIni, TProfile.LoadSavedGame and TReplay.CreateReplay, so that is
' the spelling used here.
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
	Function LoadImageChecked:TImage(a0:String, a1:Int)
		Local img:TImage
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_userpath) And Not a0.Contains(g_dataDir)
				a0 = g_dataDir + a0
			End If
			If FileType(a0) = 1
				LogLine("Loading image: " + a0)
			Else
				LogLine("WARNING! >>>>>>>>>>>> Cannot see image: " + a0)
				Return Null
			End If
		End If
		img = LoadImage(a0, a1)
		If img <> Null
			LogLine("Image loaded")
		Else
			LogLine("ERROR! >>>>>>>>>>>>>> Image could not be loaded: " + a0)
			DebugStop
		End If
		Return img
	End Function

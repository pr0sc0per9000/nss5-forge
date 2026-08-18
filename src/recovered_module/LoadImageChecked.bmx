' LoadImageChecked  -- module-level Function (no Type)
' VA 0x004bc372   251 bytes   sig ($,i):TImage
' byte-identical vs NSS5.exe (251/251, original length from Ghidra's inventory, mode=reloc)
'
' NAME AND GLOBAL NAMES ARE OURS. On the BOOT PATH: called 12 times from the module body
' at 0x004BA034, and gates 8 further functions.
'
' The "incbin" test is the asset system showing through -- embedded resources skip the
' filesystem check entirely, which matches the nine incbin'd assets extracted from the exe.
' GCCollect is confirmed by length: without that call the body is 246 bytes, with it 251.
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
' ############################################################################
' # BOOT SHIM -- DELIBERATE DIVERGENCE. Both failure paths now return a       #
' # visible placeholder image instead of Null (and the DebugStop is gone).    #
' # Delete MissingArtImage() and restore `Return Null` / `DebugStop` to get   #
' # the original behaviour back. This file is in src/recovered_module/ and is #
' # NOT covered by scripts/reverify.py, so nothing will flag it -- which is   #
' # exactly why it is written down here.                                      #
' ############################################################################
'
' WHY. A missing image returned Null, and essentially every caller immediately does
' MidHandleImage(img) / DrawImage(img) / ImageWidth(img), all of which throw "Attempt to
' access field or method of Null object". One absent PNG therefore killed the whole boot,
' repeatedly and in a different place each time.
'
' The images are not absent by accident, and this shim does not paper over a mistake in the
' asset copy. They are absent because of a real corpus defect: the same original Global is
' spelled differently in different recovered bodies, and two of those names collide.
' 0x00C6F170 (the GameMedia/Images/Icons/ root) is called g_mediapath in TEngine.SetUp and
' TScreen_Abilities, g_ach_imgpath in TScreen_Achievements, and g_screen_achievements_int03
' by the decoder -- while 0x00C6E950 (the install root) is ALSO called g_mediapath, in
' TScreen_Clubs, TScreen_EditClubs, TScreen_EditContinents, TScreen_EditKits,
' TScreen_EditNations and more. One identifier, two different slots, so NO value assigned to
' g_mediapath can be correct at every call site. Per-body verification cannot see any of
' this: a Global reaches the compiled code only as an absolute address and the byte oracle
' masks those. Fixing it properly means renaming per file, per address, with each body read
' -- see scripts/unify_globals.py, which reports the class and deliberately refuses to
' rewrite it automatically.
'
' Until that is done, some paths resolve wrong and the file genuinely is not there. A
' placeholder turns "dies at boot" into "renders a magenta square where the art should be",
' which is both survivable and self-documenting on screen. The WARNING/ERROR log lines are
' unchanged, so the debug log still names every missing file.
'
'!Global g_missingart:TImage
	Function MissingArtImage:TImage()
		If g_missingart = Null
			' 8x8 opaque magenta. Deliberately ugly: missing art should be obvious in a
			' screenshot, not quietly invisible.
			Local pm:TPixmap = CreatePixmap(8, 8, PF_RGBA8888)
			pm.ClearPixels($FFFF00FF)
			g_missingart = LoadImage(pm, 0)
		EndIf
		Return g_missingart
	End Function

	Function LoadImageChecked:TImage(a0:String, a1:Int)
		Local img:TImage
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_pathPrefix) And Not a0.Contains(g_dataDir)
				a0 = g_dataDir + a0
			End If
			If FileType(a0) = 1
				LogLine("Loading image: " + a0)
			Else
				LogLine("WARNING! >>>>>>>>>>>> Cannot see image: " + a0)
				Return MissingArtImage()      ' BOOT SHIM -- original: Return Null
			End If
		End If
		img = LoadImage(a0, a1)
		If img <> Null
			LogLine("Image loaded")
		Else
			LogLine("ERROR! >>>>>>>>>>>>>> Image could not be loaded: " + a0)
			Return MissingArtImage()          ' BOOT SHIM -- original: DebugStop
		End If
		Return img
	End Function

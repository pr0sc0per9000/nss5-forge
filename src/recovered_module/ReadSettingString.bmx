' ReadSettingString  -- module-level Function (no Type)
' VA 0x004bc1d1   417 bytes   sig ($,$)$
' byte-identical vs NSS5.exe (417/417, original length from Ghidra's inventory, mode=reloc)
'
' NAME AND GLOBAL NAMES ARE OURS. On the BOOT PATH: 2 callers, both in the module body at
' 0x004BA034 (offsets 5623 and 6348) -- it brackets the directory work.
'
' The String twin of ReadSettingFloat (0x004BBFC1). Same .ini scan, same key match, same
' Mid(line, key.Length + 2, -1) value slice. Three differences, all visible in the bytes:
'   * the "Load variable: " log happens BEFORE ReadFile, not after the scan
'   * no clamp arguments
'   * the accumulator is a String slot (mov [ebp-4], <empty string>) not a Float slot
' Found by family resemblance to ReadSettingFloat; matched on the first build.
' NAME SPLIT RESOLVED -- THE SECOND PATH GLOBAL HERE IS THE SAVE ROOT, NOT A SECOND
' INSTALL ROOT. The original's two pushes are 0x00C6E950 (install root, g_dataDir) at
' +0x1F and 0x00C6E9A8 (save root) at +0x3C, in that order. The corpus spells
' 0x00C6E9A8 g_userpath in TOptions.SetUp / LoadOptions / SaveOptions / WriteNewOptionsIni,
' TProfile.SaveGame and TReplay.LoadReplayFile, and 0x00C6E950 g_pathPrefix in
' THorse.Create and TCard.CreateCard -- so the one name g_pathPrefix stood for both
' addresses depending on the body, and extracted/global_alias_map.tsv row 249 resolves
' it to 0x00C6E950. Spelled that way this guard tests the install root twice and has no
' save-root arm, which silently requires the save root to sit underneath the install
' directory: an Options.ini anywhere else gets the install root prepended to an
' already-absolute path and the open fails. Measured, that is not a graceful fallback --
' the `If Not s` arm returns 0.0 BEFORE the two clamps run, so every setting comes back
' 0 whatever its legal range, window included, which is the exclusive-fullscreen lockup
' scripts/play.py's header describes. Named for the address it is, the way TOptions' own
' bodies name it, there is one Global again.
'!Global g_userpath:String
'!Global g_dataDir:String
' PREDICATE CORRECTED: .StartsWith -> .Contains. extracted/runtime_helpers.tsv named
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row corrected, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Function ReadSettingString:String(a0:String, a1:String)
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_dataDir) And Not a0.Contains(g_userpath)
				a0 = g_dataDir + a0
			End If
		End If
		a1 = Lower(a1)
		LogLine("Load variable: " + a1)
		Local v:String = ""
		Local s:TStream = ReadFile(a0)
		If Not s
			LogLine("Could not open file: " + a0 + ": " + a1)
			Return ""
		End If
		Local found:Int = 0
		While Not Eof(s) And Not found
			Local ln:String = ReadLine(s)
			ln = Lower(ln)
			If Left(ln, a1.Length) = a1
				v = Mid(ln, a1.Length + 2, -1)
				found = 1
			End If
		Wend
		CloseStream s
		If Not found
			LogLine("Could not load variable: " + a1)
		End If
		Return v
	End Function

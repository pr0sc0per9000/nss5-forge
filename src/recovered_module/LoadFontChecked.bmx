' LoadFontChecked  -- module-level Function (no Type)
' VA 0x004bc773   257 bytes   sig ($,i,i):TImageFont
' byte-identical vs NSS5.exe (257/257, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=24)
'
' NAME AND GLOBAL NAMES ARE OURS. Structurally identical to LoadImageChecked
' (src/recovered_module/LoadImageChecked.bmx) with LoadImageFont in place of LoadImage and
' TImageFont in place of TImage; only the log-message string literals differ ("Loading
' font: " / "Cannot see font: " / "Font loaded" / "Font could not be loaded: "). Called (at
' least) 4 times from TScreen.SetUpFonts, which is the only caller Ghidra records
' (function_inventory.tsv called_by_count=1).
'!Global g_pathPrefix:String
'!Global g_dataDir:String
	Function LoadFontChecked:TImageFont(a0:String, a1:Int, a2:Int)
		Local fnt:TImageFont
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_pathPrefix) And Not a0.Contains(g_dataDir)
				a0 = g_dataDir + a0
			End If
			If FileType(a0) = 1
				LogLine("Loading font: " + a0)
			Else
				LogLine("WARNING! >>>>>>>>>>>> Cannot see font: " + a0)
				Return Null
			End If
		End If
		fnt = LoadImageFont(a0, a1, a2)
		If fnt <> Null
			LogLine("Font loaded")
		Else
			LogLine("ERROR! >>>>>>>>>>>>>> Font could not be loaded: " + a0)
			DebugStop
		End If
		Return fnt
	End Function

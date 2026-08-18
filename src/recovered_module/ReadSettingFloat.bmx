' ReadSettingFloat  -- module-level Function (no Type)
' VA 0x004bbfc1   528 bytes   sig ($,$,f,f)f
' byte-identical vs NSS5.exe (528/528, original length from Ghidra's inventory, mode=reloc)
' Re-verified with NSS5_NO_LEARN=1: still 528/528. Nothing here was masked by a name this
' probe taught the table.
'
' NAME AND GLOBAL NAMES ARE OURS. On the BOOT PATH: 5 callers, four of them consecutive in
' the module body at 0x004BA034 (offsets 6036/6115/6197/6276), each result passed straight
' through bbFloatToInt.
'
' This is the Engine.ini reader. exe-assets/Engine.ini is `key=value`, one per line, which
' is why the value slice is Mid(line, key.Length + 2, -1) -- key plus the single '='.
' a2/a3 are a clamp: the value is forced into [a2,a3] before it is returned and logged.
'
' Family note: same opening as the LoadXChecked asset loaders, but the two path Globals are
' tested in the OPPOSITE order (g_dataDir first here, g_pathPrefix first in the loaders).
' That is byte-observable and was checked, not assumed.
'
' The clamps really are spelled as negated >=/<= tests: the original emits `setae`/`setbe`
' followed by `jne`, and `If v < a2` would emit `setb` + `je`. Written the other way the
' body is the same length but differs at those bytes.
'
' Corroborates 0x004A6E90 = _bbStringToFloat: our `Float(...)` lowers to _bbStringToFloat
' and masks against 0x004A6E90 with every other byte of a 528-byte body agreeing.
'!Global g_pathPrefix:String
'!Global g_dataDir:String
' PREDICATE CORRECTED: .StartsWith -> .Contains. extracted/runtime_helpers.tsv named
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row corrected, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Function ReadSettingFloat:Float(a0:String, a1:String, a2:Float, a3:Float)
		If Not a0.Contains("incbin")
			If Not a0.Contains(g_dataDir) And Not a0.Contains(g_pathPrefix)
				a0 = g_dataDir + a0
			End If
		End If
		a1 = Lower(a1)
		Local v:Float = 0.0
		Local s:TStream = ReadFile(a0)
		If Not s
			LogLine("Could not open file: " + a0 + ": " + a1)
			Return 0.0
		End If
		Local found:Int = 0
		While Not Eof(s) And Not found
			Local ln:String = ReadLine(s)
			ln = Lower(ln)
			If Left(ln, a1.Length) = a1
				v = Float(Mid(ln, a1.Length + 2, -1))
				found = 1
			End If
		Wend
		CloseStream s
		If Not found
			LogLine("Could not load variable: " + a1)
		End If
		If Not (v >= a2)
			v = a2
		End If
		If Not (v <= a3)
			v = a3
		End If
		LogLine("Load variable: " + a1 + " = " + v)
		Return v
	End Function

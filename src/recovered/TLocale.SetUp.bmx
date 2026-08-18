' TLocale.SetUp
' VA 0x004c558f   702 bytes   class-table slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (702/702, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=50)
'
' Boot step 2 (docs/game/engine/main-loop.md): loads GameMedia/Languages/Languages.csv and
' builds the tag->text lookup table every GetText()/TLocale.GetLocaleText() call reads. No
' file, no English fallback -- Notify() + End, the whole game is unplayable without it.
'
' GLOBAL NAMES ARE OURS. Types are load-bearing:
'   0x00C5A328 : TMap   -- language-code -> TMap(tag->text). Reused here as g_locale_maps,
'     matching TLocale.GetLocaleText.bmx's name for the same address; note
'     TLocale.SetCurrentLanguage.bmx already calls the SAME address g_locales -- a
'     pre-existing naming disagreement between two already-recovered files, not introduced
'     here and not fixed here (it touches files outside this VA).
'   0x00C6E950 : String -- g_datapath, the install/data-path prefix every asset loader in
'     the corpus uses (TNames.SetUp.bmx and 30+ others).
'
' CALLEE: 0x004A7740 (called once, on the freshly-read CSV row) is `_bbStringTrim`. It
' is in none of the helper tables (brl_functions.tsv, brl_functions_inferred.tsv,
' runtime_helpers.tsv, dll_imports.tsv, i.e. helper_map.full_table()), so it is
' identified directly, not by alignment guesswork:
'   * tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_classes.i:27 declares
'     `-Trim:String()="bbStringTrim"` inside the String pseudo-Type -- Trim is a no-arg
'     extern-alias METHOD on String (`row.Trim()`), which is why the call site is a bare E8
'     with exactly one pushed argument (self) and no wrapper level (codegen-patterns 15.2:
'     an extern alias is never a hand-written BlitzMax wrapper).
'   * blitz_string.c:307's bbStringTrim source matches the disassembly instruction for
'     instruction: skip leading chars <=' ', return &bbEmptyString if the whole string was
'     blank, skip trailing chars <=' ', return the original object unchanged if nothing was
'     trimmed, else bbStringFromShorts(buf+b, e-b) (0x004A7700, already named in
'     runtime_helpers.tsv). 0x5C7D40 -- used both as this C function's own blank-input
'     return value AND, separately, as this BlitzMax body's per-row `lastText` default init
'     -- is that same bbEmptyString runtime singleton, not a game-module string literal
'     (those live at 0xC5D284, a different address entirely).
'   Learned into runtime_helpers.tsv via one non-NO_LEARN alignment pass (the rest of this
'   702-byte body already matched byte-for-byte before that single call was named, so the
'   alignment was corroborating evidence, not a self-fulfilling guess -- codegen-patterns
'   15.1) and reverified clean under NSS5_NO_LEARN=1 with the name now persisted.
'
' REPLACE() ARGUMENTS RESOLVED: docs/game/data/languages.md flagged "the exact Replace()
' call in TLocale.SetUp's row-reading loop... unconfirmed" because Ghidra folds a callee's
' pushed arguments into the FOLLOWING call's printed argument list. Reading the raw pushes
' (three total, but the first call -- ReadLine, args=1 -- consumes only the last-pushed one)
' shows the earlier two literals belong to the SECOND call, _bbStringReplace, args=3:
' self=the just-read line, find=";", replace=",". So every CSV row is
' `ReadLine(a1).Replace(";", ",")` before NextField ever sees it -- semicolons in a
' translated string silently become commas, on every row, unconditionally.
'
' FALLBACK-TEXT MECHANISM: docs/game/data/languages.md describes the blank-cell fallback
' as "the last non-blank piece of text...seen so far in that row". The actual assembly
' (edi=lastText, reset to bbEmptyString once per row, right before the column loop) is:
'     If lastText.Length = 0 Then lastText = fieldText
'     If fieldText.Length = 0 Then fieldText = lastText
' -- lastText is captured from the FIRST non-blank column only and is never overwritten
' again for the rest of that row (the first If only fires while lastText is still blank), so
' this is STICKY-FIRST-non-blank, not a running LAST-non-blank. Since `en` is column 1 and
' is (per the doc) essentially always populated, the two descriptions agree in every
' observed real row -- but they are not the same algorithm: a row whose `en` cell is blank
' with a later column filled would fall back to whichever column was the first non-blank
' one, not to the most recently-seen non-blank value as the row is walked further right.
'
' `field` collides with the BlitzMax `Field` keyword (case-insensitive) and will not parse
' as a Local name; the header-column loop variable is spelled `hcol` here purely as a
' source-text choice with no effect on codegen.
'!Global g_locale_maps:TMap
'!Global g_datapath:String
	Function SetUp:Int()
		g_locale_maps = CreateMap()
		Local a1:TStream = ReadFile("utf8::" + g_datapath + "GameMedia/Languages/Languages.csv")
		If Not a1
			Notify("Error TMyLocale: Unable to load language file!", True)
			End
		EndIf
		Local header:String = ReadLine(a1)
		NextField(header, "~t")
		Local headerList:TList = CreateList()
		Local hcol:String
		Repeat
			hcol = NextField(header, "~t")
			headerList.AddLast(hcol)
			If hcol <> "" Then g_locale_maps.Insert(hcol, CreateMap())
		Until hcol = "" Or header.Length < 1
		If g_locale_maps.IsEmpty() Then DebugStop()
		While Not Eof(a1)
			Local row:String = ReadLine(a1).Replace(";", ",").Trim()
			Local tag:String = NextField(row, "~t")
			Local lastText:String
			For Local col:String = EachIn headerList
				Local dict:TMap = TMap(g_locale_maps.ValueForKey(col))
				Local fieldText:String = NextField(row, "~t")
				If lastText.Length = 0 Then lastText = fieldText
				If fieldText.Length = 0 Then fieldText = lastText
				dict.Insert(tag, fieldText)
			Next
		Wend
		CloseStream(a1)
	End Function

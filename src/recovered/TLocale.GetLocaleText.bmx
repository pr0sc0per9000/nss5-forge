' TLocale.GetLocaleText
' VA 0x004c58fc   106 bytes   class-table slot 0x38   sig ($)$   KIND=Function (static)
' byte-identical vs NSS5.exe (106/106, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. Types are load-bearing:
'   0x00C5A328 : TMap   -- language-code -> TMap of text keys (slot 0x40 = TMap.ValueForKey)
'   0x00C5A33C : String -- current language code (statically initialised to "en")
' globals_final.tsv types 0x00C5A33C as Int; the code passes it to ValueForKey(:Object),
' so it holds a reference. TRUST THE CODE (patterns 11.2).
'
' The missing-key marker is "@" + key -- this is why GetText() results are tested with
' StartsWith("@") elsewhere (see TScreen.CreateScreen).
'!Global g_locale_maps:TMap
'!Global g_locale_lang:String
	Function GetLocaleText:String(a0:String)
		Local s:String = String(TMap(g_locale_maps.ValueForKey(g_locale_lang)).ValueForKey(a0))
		If s.Length Then Return s
		Return "@" + a0
	End Function

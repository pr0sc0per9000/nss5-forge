' TLocale.SetCurrentLanguage
' VA 0x004c584d   175 bytes   vtable slot 0x34   sig ($)i
' byte-identical vs NSS5.exe (175/175, original length from Ghidra's inventory)
' Globals: 0x00C5A328 :TMap (locale table), 0x00C5A33C :String (current language).
' TMap.ValueForKey is slot 0x40; TLocale.SetUpKeyStrings is TLocale+0x3C. The two log
' prefixes and the "en" fallback are read out of NSS5.exe as string objects.
' The test is `If m <> Null` -- the original's `je` falls THROUGH to the a0 branch.
'
' GLOBALS RENAMED (2026-08-15) -- g_locales -> g_locale_maps, g_curlang -> g_locale_lang.
' Not a behaviour change and not a reconstruction correction: the two addresses above were
' spelled one way here and another way in TLocale.GetLocaleText.bmx / TLocale.SetUp.bmx,
' which both call 0x00C5A328 g_locale_maps and 0x00C5A33C g_locale_lang. Per-body
' verification cannot catch that -- a Global reaches the compiled code only as an absolute
' address, and the byte oracle masks those, so both spellings verify byte-perfectly. In the
' ASSEMBLED program they became two separate pairs of Globals: this function wrote the
' language into g_curlang while every reader looked at g_locale_lang, which stayed Null, and
' the first GetText() after boot died with "Attempt to access field or method of Null
' object" inside GetLocaleText. TLocale.SetUp.bmx's own header had already noticed the
' disagreement and explicitly left it ("not fixed here"); under a byte-matching goal it
' genuinely did not matter, and it only became fatal once the program was run.
'
' Renaming is byte-neutral (names do not appear in the compiled bytes), so this body must
' still verify at 175/175 -- confirm with scripts/reverify.py rather than trusting the note.
' scripts/unify_globals.py reports the remaining cases of this defect corpus-wide.
	Function SetCurrentLanguage:Int(a0:String)
		'!Global g_locale_maps:TMap
		'!Global g_locale_lang:String
		LogLine("SetCurrentLanguage:" + a0)
		Local m:TMap = TMap(g_locale_maps.ValueForKey(a0))
		If m <> Null
			g_locale_lang = a0
		Else
			g_locale_lang = "en"
		EndIf
		TLocale.SetUpKeyStrings()
		LogLine("Language set to: " + g_locale_lang)
		Return 0
	End Function

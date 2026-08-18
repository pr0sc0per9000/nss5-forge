' TScreen_Options.ButtonLanguage
' VA 0x00520cb7   118 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory, mode=reloc)
' KIND=Function -- static, no implicit Self.
' Renamed g_curscreen -> g_curscreenname. NAME COLLISION, not a type
' conflict: this Global is 0x00c63cec, a String holding the current screen's NAME, while
' the g_curscreen four other bodies declare is 0x00C6764C, the TScreen OBJECT
' (TScreen.SetActive returns it; TScreen_Difficulty.SetUpScreen reads .name off it, which
' is this string). Two addresses, one name, so assembled together they collided as
' "String vs TScreen". Both types were right; only the shared name was wrong. Global names
' are ours and have no codegen effect (codegen-patterns 4); re-verified after the rename,
' still 118/118 mode=reloc.
' assumptions: module Global 0x00c63cec is :String (the current screen name),
'              module Global 0x00c5d290 is :String (the language-menu selection);
'              literals 0x00c7e520 = "mainmenu", 0x00c805e4 = "CMESSAGE_CHANGELANGUAGE",
'              0x00c639ec = "0";
'              FUN_004a6a30 = _bbStringCompare, FUN_004c5549 = module Function GetText;
'              PTR_FUN_00c61cc0 = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i),
'              PTR_FUN_00c63984 = TScreen_Language classtable + 0x34 = SetUpScreen(i).
'
' Ghidra's `DAT_00c639f0 = DAT_00c639f0 + 1` is NOT a global counter -- it is
' `inc dword ptr [ebx+4]`, the refcount of the string constant at 0x00c639ec. There is
' no counter in the source.
'
' The shape is an early return, not If/Else: the taken branch ends `mov eax,0 / jmp end`
' rather than jumping over an else block.
	Function ButtonLanguage:Int()
		'!Global g_curscreenname:String
		'!Global g_lang_sel:String
		If g_curscreenname <> "mainmenu"
			TScreen.DoMessage(GetText("CMESSAGE_CHANGELANGUAGE"), 0, 0)
			Return 0
		EndIf
		g_lang_sel = "0"
		TScreen_Language.SetUpScreen(1)
	End Function

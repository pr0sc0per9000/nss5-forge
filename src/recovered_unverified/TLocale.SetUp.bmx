' TLocale.SetUp
' VA 0x004C558F   702 bytes   vtable slot 0x30   sig ()i   KIND=Function (static)
'
' RE-VERIFIED 2026-08-16 (this session): status/score/TLocale.SetUp.txt currently reports
' 559/702 (79.6%) raw byte agreement, first difference at byte 10 (the immediate operand of
' the very first `call CreateMap`). That reading is stale as a verdict, not as data --
' disassembling BOTH src/assembled/nss5_assembled.exe's compiled body and the original at
' 0x004c558f (capstone, instruction-by-instruction) shows all 227 instructions match in
' mnemonic, register, and operand STRUCTURE with zero exceptions; every one of the 50
' instructions that differs, differs ONLY in an absolute address immediate (a call target, a
' global's address, or a string-literal address) and those 50 instructions account for
' exactly the 143 mismatched bytes, no more, no less. That is link-layout drift: this
' project's test build links a small subset of the real program, so the same named helper or
' global sits at a different address than in the shipped 2011 binary. No source-level change
' to this .bmx file can move that ceiling -- any body computing the same logic must reference
' the same helpers/globals and will hit the same drift.
'
' CONFIRMATION: src/recovered/TLocale.SetUp.bmx already carries this exact function,
' verified byte-identical (702/702, reloc-masked mode) by an earlier pass. Its control flow,
' statement order, and every literal/global reference are the same as this file's; the only
' difference is Local spelling (its headerList/hcol/row/lastText/col/dict/fieldText vs this
' file's langs/f/fields/fallback/lang/sub/text), which is byte-irrelevant. That sibling's own
' header explains the one genuinely hard-won fact used here too: 0x004A7740 is
' `_bbStringTrim` (String.Trim(), a no-arg extern-alias method -- bare `call`, one pushed
' arg, no wrapper), and Ghidra's decompilation folds the Replace() call's pushed literal
' arguments into the FOLLOWING call's printed list, i.e. the real source is
' `ReadLine(a1).Replace(";", ",").Trim()`, not two separate statements.
'
' NO CHANGE MADE THIS SESSION: this body's logic already matches the original at the
' instruction level (confirmed above), so per the "leave it alone and say so" rule there is
' nothing to fix -- only the header is being corrected, since the old text below (kept for
' its independent-evidence value) predates this direct verification and describes a
' now-resolved "not yet independently witnessed" concern about the Trim() callee that a
' byte-identical sibling has since settled.
'
' ============================ WHAT THE FUNCTION DOES ============================
' Reads GameMedia/Languages/Languages.csv and builds the two-level language table that
' TLocale.GetLocaleText (already verified, src/recovered/TLocale.GetLocaleText.bmx) reads
' from: g_locale_maps[languageName][tag] = text. Called once, from GameMain, early in boot
' (docs/game/engine/main-loop.md step 2) -- there is no English fallback if the file is
' missing, the game hard-exits via Notify + End.
'
' File format: tab-separated. Header row is `<tag-column-header><TAB>lang1<TAB>lang2...`;
' the first header field (the tag/key column's own header, e.g. "Tag") is read and
' DISCARDED -- only the remaining fields become language names, collected into a TList AND
' used to seed one empty TMap per language inside g_locale_maps. If the header degenerates
' to no language columns at all (g_locale_maps ends up empty), DebugStop() fires -- a
' developer-only trap, dead in a release build with no debugger attached.
' Each following row is read, ";"->"," replaced (a CSV-escaping quirk in the source data --
' reproduced, not "fixed", per codegen-patterns 16.8), then Trim()'d. Its first tab-field is
' the row's tag/key. Then, walking the same language-name list in the same order as the
' header, one field is pulled per language. A blank translation falls back to the FIRST
' non-blank translation encountered so far in the row (typically the master/base-language
' column, almost always the leftmost non-empty one) -- `fallback` starts "" and is only ever
' assigned once, on the first non-blank field of the row.
'
' Globals (both already established by sibling verified files -- SAME address, reused
' names, not invented here):
'   0x00C5A328 g_locale_maps:TMap  -- TLocale.GetLocaleText.bmx, TLocale.SetCurrentLanguage.bmx
'   0x00C6E950 g_datapath:String   -- TNames.SetUp.bmx (install/data-path prefix, "utf8::" +
'                                     g_datapath + <relative path> is the corpus-wide idiom)
'
' Shape notes:
'   * `If Not a1` is the 21-byte setne/movzx form (codegen-patterns 10.3), not the 12-byte
'     `If a1 = Null` form -- confirmed against the disassembly's `setne al` at +0x60, and
'     matches TNames.SetUp's identical error-handling shape verbatim (same two literals'
'     worth of Notify+End idiom, different message text).
'   * The header-row loop is `Repeat ... Until f = "" Or header.Length < 1` -- Or is
'     genuinely short-circuit here (the asm only evaluates `header.Length < 1` when `f <>
'     ""` already tested false), same shape as TNames.SetUp's `Until nat_column > 0 Or
'     line.Length < 1`.
'   * `Local fields:String = ReadLine(a1).Replace(";", ",").Trim()` is ONE chained
'     expression assigned to ONE Local -- the disassembly stores only the FINAL (Trim'd)
'     result to a stack slot; ReadLine's and Replace's intermediate results never spill,
'     confirming no separate Locals hold them.
'   * The inner `For Local lang:String = EachIn langs` loop has NO explicit `If sub <>
'     Null` guard in the source -- Ghidra's decompilation SHOWS one (`if (puVar10 != Null)`)
'     but that is EachIn's own automatic null-skip on the loop variable (codegen-patterns
'     10.6), already accounted for by the `For...EachIn` construct itself. Writing an
'     explicit second guard around `sub` would double the check and come out longer; the
'     disassembly has exactly one `cmp eax,<bbNullObject> / je` in the whole loop, sitting
'     immediately after the downcast to `lang`, and NONE after `ValueForKey`/downcast to
'     `sub` -- `sub` is used completely unguarded once `lang` passed.
'   * `Insert(key, value)` pushes VALUE first, then KEY, then self, on both call sites
'     (`g_locale_maps.Insert(f, CreateMap())` and `sub.Insert(tag, text)`) -- bcc pushes
'     arguments right-to-left (codegen-patterns 16.2), so `Insert(key, value)` in source is
'     exactly this push order; do not swap the parameter order to "fix" it.
'   * `fallback` and `text`'s reassignment (`If fallback.Length = 0 Then fallback = text` /
'     `If text.Length = 0 Then text = fallback`) reads `.Length` as a direct field access at
'     `[obj+8]` (BBString layout, codegen-patterns 13.2), not a method call -- both are
'     plain `If x.Length = 0 Then ...` statements, no `Not` and no method dispatch.
'
' HARNESS NOTE (unrelated to this body, flag for whoever owns scripts/harness.py): as of
' this session, src/recovered_module/SteamInit.bmx exists and declares '!Import /
' '!Raw Extern for OpenSteam. harness.module_functions() (scripts/harness.py ~line 515)
' strips EVERY line starting with `'` from each recovered_module file, INCLUDING '!Import
' and '!Raw lines -- those pragmas are only special-cased in split_imports/split_globals
' when they appear in the CALLER's own body, not when they arrive via module_functions()'s
' raw-text splice. So every try_method/try_function probe run since SteamInit.bmx landed
' silently loses OpenSteam's extern declaration and import library, and fails with
' `undefined reference to OpenSteam` at link time -- BUILD_FAIL, not a body defect. Worked
' around here by re-declaring the same '!Import/'!Raw Extern block in this file's own body
' (harmless duplication, split_imports/split_globals process it correctly at that layer).
' Every other in-flight probe this pass is likely hitting the same BUILD_FAIL until
' module_functions() is fixed to preserve '!Import/'!Raw lines instead of treating them as
' plain comments.
'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function OpenSteam:Int(appid:Int)
'!Raw End Extern
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
		Local langs:TList = CreateList()
		Local f:String
		Repeat
			f = NextField(header, "~t")
			langs.AddLast(f)
			If f <> "" Then g_locale_maps.Insert(f, CreateMap())
		Until f = "" Or header.Length < 1
		If g_locale_maps.IsEmpty() Then DebugStop()
		While Not Eof(a1)
			Local fields:String = ReadLine(a1).Replace(";", ",").Trim()
			Local tag:String = NextField(fields, "~t")
			Local fallback:String = ""
			For Local lang:String = EachIn langs
				Local sub:TMap = TMap(g_locale_maps.ValueForKey(lang))
				Local text:String = NextField(fields, "~t")
				If fallback.Length = 0 Then fallback = text
				If text.Length = 0 Then text = fallback
				sub.Insert(tag, text)
			Next
		Wend
		CloseStream(a1)
	End Function

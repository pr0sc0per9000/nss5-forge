' TKit.SetUp
' VA 0x004DA744   1731 bytes   sig ()i
' byte-identical vs NSS5.exe (1731/1731, original length from Ghidra's inventory, mode=reloc)
'
' KIND=Function (static, no Self). Reads 26 base kit-part settings from Engine.ini into
' g_kit_arr01 (String[26]), Lower()'d, then parses each as a "RRGGBB" hex colour and packs
' it through TKit.ColorInt into the matching slot of g_kit_arr02 (Int[26]).
'
' GLOBAL TYPES CORRECTED from extracted/globals_final.tsv, which lists both
' 0x00C5C1E4 (g_kit_arr01) and 0x00C5C1EC (g_kit_arr02) as "Object[]" (type_source=usage,
' confidence=medium). The code itself disagrees and is the higher-confidence signal
' (codegen-patterns.md 10.7/11.2/16.7 -- refcount traffic decides the type, not the table):
'   * every g_kit_arr01[i] store carries full retain-new/release-old/conditional-bbGCFree
'     traffic around a String returned by Lower(ReadSettingString(...)) -> String[].
'   * every g_kit_arr02[i] store is a bare `mov [ebx+esi*4+0x18],eax` of ColorInt's Int
'     return, no refcount traffic at all -> Int[].
' Neither array's allocation site is in this function; both are declared/sized elsewhere
' (26 elements each, indices 0..25) and merely populated here.
'
' The `To 25` loop bound was NOT obvious from Ghidra's own C: it normalises `cmp esi,0x19 /
' jle` to `iVar5 < 0x1a`, which reads as `Until 26`. The raw bytes are `jle`, which
' codegen-patterns.md 6 ties to `To N`, not `Until N+1` -- confirmed by the oracle
' (`Until 26` builds to the same length but wrong opcode/immediate: `jl`/0x1a vs the
' original's `jle`/0x19).
'
' All 27 string literals (the 26 Engine.ini keys plus the "incbin::Inc/Engine.ini" path)
' were read back from NSS5.exe with harness.read_string() and match verbatim -- a MATCH
' masks a literal's ADDRESS, never its content (codegen-patterns.md 13.2).
'!Global g_kit_arr01:String[]
'!Global g_kit_arr02:Int[]
	Function SetUp:Int()
		g_kit_arr01[0] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basemask"))
		g_kit_arr01[1] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt1"))
		g_kit_arr01[2] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt2"))
		g_kit_arr01[3] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt3"))
		g_kit_arr01[4] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt4"))
		g_kit_arr01[5] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt5"))
		g_kit_arr01[6] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshirt6"))
		g_kit_arr01[7] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshorts1"))
		g_kit_arr01[8] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshorts2"))
		g_kit_arr01[9] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseshorts3"))
		g_kit_arr01[10] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basesocks1"))
		g_kit_arr01[11] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basesocks2"))
		g_kit_arr01[12] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseboots1"))
		g_kit_arr01[13] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseboots2"))
		g_kit_arr01[14] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseboots3"))
		g_kit_arr01[15] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basehair1"))
		g_kit_arr01[16] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basehair2"))
		g_kit_arr01[17] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basehair3"))
		g_kit_arr01[18] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin1"))
		g_kit_arr01[19] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin2"))
		g_kit_arr01[20] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin3"))
		g_kit_arr01[21] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin4"))
		g_kit_arr01[22] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin5"))
		g_kit_arr01[23] = Lower(ReadSettingString("incbin::Inc/Engine.ini","baseskin6"))
		g_kit_arr01[24] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basegloves1"))
		g_kit_arr01[25] = Lower(ReadSettingString("incbin::Inc/Engine.ini","basegloves2"))
		For Local i:Int = 0 To 25
			Local r:Int
			Local g:Int
			Local b:Int
			ParseColourHex(g_kit_arr01[i], r, g, b)
			g_kit_arr02[i] = ColorInt(r, g, b, 255)
		Next
		Return 0
	End Function

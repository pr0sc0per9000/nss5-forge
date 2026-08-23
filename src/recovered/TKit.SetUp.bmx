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
' CASE DIRECTION CORRECTED 2026-08-22: 26 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function SetUp:Int()
		g_kit_arr01[0] = ReadSettingString("incbin::Inc/Engine.ini","basemask").ToUpper()
		g_kit_arr01[1] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt1").ToUpper()
		g_kit_arr01[2] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt2").ToUpper()
		g_kit_arr01[3] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt3").ToUpper()
		g_kit_arr01[4] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt4").ToUpper()
		g_kit_arr01[5] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt5").ToUpper()
		g_kit_arr01[6] = ReadSettingString("incbin::Inc/Engine.ini","baseshirt6").ToUpper()
		g_kit_arr01[7] = ReadSettingString("incbin::Inc/Engine.ini","baseshorts1").ToUpper()
		g_kit_arr01[8] = ReadSettingString("incbin::Inc/Engine.ini","baseshorts2").ToUpper()
		g_kit_arr01[9] = ReadSettingString("incbin::Inc/Engine.ini","baseshorts3").ToUpper()
		g_kit_arr01[10] = ReadSettingString("incbin::Inc/Engine.ini","basesocks1").ToUpper()
		g_kit_arr01[11] = ReadSettingString("incbin::Inc/Engine.ini","basesocks2").ToUpper()
		g_kit_arr01[12] = ReadSettingString("incbin::Inc/Engine.ini","baseboots1").ToUpper()
		g_kit_arr01[13] = ReadSettingString("incbin::Inc/Engine.ini","baseboots2").ToUpper()
		g_kit_arr01[14] = ReadSettingString("incbin::Inc/Engine.ini","baseboots3").ToUpper()
		g_kit_arr01[15] = ReadSettingString("incbin::Inc/Engine.ini","basehair1").ToUpper()
		g_kit_arr01[16] = ReadSettingString("incbin::Inc/Engine.ini","basehair2").ToUpper()
		g_kit_arr01[17] = ReadSettingString("incbin::Inc/Engine.ini","basehair3").ToUpper()
		g_kit_arr01[18] = ReadSettingString("incbin::Inc/Engine.ini","baseskin1").ToUpper()
		g_kit_arr01[19] = ReadSettingString("incbin::Inc/Engine.ini","baseskin2").ToUpper()
		g_kit_arr01[20] = ReadSettingString("incbin::Inc/Engine.ini","baseskin3").ToUpper()
		g_kit_arr01[21] = ReadSettingString("incbin::Inc/Engine.ini","baseskin4").ToUpper()
		g_kit_arr01[22] = ReadSettingString("incbin::Inc/Engine.ini","baseskin5").ToUpper()
		g_kit_arr01[23] = ReadSettingString("incbin::Inc/Engine.ini","baseskin6").ToUpper()
		g_kit_arr01[24] = ReadSettingString("incbin::Inc/Engine.ini","basegloves1").ToUpper()
		g_kit_arr01[25] = ReadSettingString("incbin::Inc/Engine.ini","basegloves2").ToUpper()
		For Local i:Int = 0 To 25
			Local r:Int
			Local g:Int
			Local b:Int
			ParseColourHex(g_kit_arr01[i], r, g, b)
			g_kit_arr02[i] = ColorInt(r, g, b, 255)
		Next
		Return 0
	End Function

' TScreen.UpdateOffset
' VA 0x00510811   500 bytes   class-table slot 0x54   KIND=Function (static)   sig ()i
' byte-identical vs NSS5.exe (500/500, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only, no parameters.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Globals (names ours, types load-bearing):
'      0x00C6EFDC Int   g_screen_int21    0x00C6EFE0 Int   g_screen_int22
'      0x00C6EFE4 Int   g_engine_int162   0x00C6EFE8 Int   g_engine_int163
'      0x00C61724 Float g_screen_float01  0x00C61728 Float g_screen_float02
'      0x00C61718 TImage g_screen_bg  -- globals_final.tsv says only `Object`
'        (type_source=usage, confidence=low). TImage is forced by the call sites:
'        ImageHeight() and SetImageHandle() both take :TImage, and the value assigned
'        is LoadImageChecked()'s declared :TImage return.
'  * 0x005AE3D4 = _brl_max2d_ImageHeight, from brl_functions_inferred.tsv (§10.8 -- the
'    inferred table does mask, and it did here).
'  * 0x004BC372 = LoadImageChecked, 0x00505B91 = LogLine, both from src/recovered_module.
'  * String literals read out of NSS5.exe's .data at the pushed BBString addresses.
'  * `If Not g_screen_bg Or ...` (setne/movzx/cmp/sete/movzx) -- NOT `= Null`, which is
'    the short 12-byte form (§10.3).
'  * The two zero-clamps are If BLOCKS (`cmp/jg +8` straight past the store), not the
'    single-line `If ... Then ...` form.
'
' NOTE -- this body was already byte-correct before it could be certified. It was blocked
' by a helper_map defect: orig_functions() read only the first 400 chars of each
' recovered_module file, so the four "NOT CERTIFIED" files (LoadImageChecked and its three
' siblings) never got their VA registered and the E8 into them could not mask. Fixed in
' scripts/helper_map.py.
' g_screen_int21/g_screen_int22 are the screen width/height (0x00C6EFDC=800,
' 0x00C6EFE0=600, the game's fixed 800x600 resolution -- codegen-patterns 21.1/21.3).
' The SAME two addresses are also declared under two other names elsewhere in the corpus
' (g_screenwidth/g_screenheight in ~30 files, g_screenw/g_screenh in TScreen.Draw.bmx);
' merge_globals dedups by name, not address, so each name family needs its own
' initialiser or it stays a separate, zero-defaulted Global in the assembled build.
'!Global g_screen_int21:Int = 800
'!Global g_screen_int22:Int = 600
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_bg:TImage
LogLine("UpdateOffset")
g_screen_float01 = (g_engine_int162 - g_screen_int21) / 2
g_screen_float02 = (g_engine_int163 - g_screen_int22) / 2
If g_engine_int162 <= 800
	g_screen_float01 = 0
EndIf
If g_engine_int163 <= 600
	g_screen_float02 = 0
EndIf
LogLine("offsetX:" + g_screen_float01)
LogLine("offsetY:" + g_screen_float02)
If g_engine_int162 > 800
	If g_engine_int163 = 600
		If Not g_screen_bg Or ImageHeight(g_screen_bg) > 600
			g_screen_bg = LoadImageChecked("GameMedia/Images/Backgrounds/StadiumBG2.jpg", -1)
			SetImageHandle(g_screen_bg, 240.0, 0.0)
		EndIf
	Else
		If Not g_screen_bg Or ImageHeight(g_screen_bg) = 600
			g_screen_bg = LoadImageChecked("GameMedia/Images/Backgrounds/StadiumBG.jpg", -1)
			SetImageHandle(g_screen_bg, 505.0, 503.0)
		EndIf
	EndIf
EndIf

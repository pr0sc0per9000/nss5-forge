' TScreen_EditKits.UpdateKitInp
' VA 0x00536094   600 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x44   (static -- no implicit Self)
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C61CF8 g_editkits_focus:TGadget    (downcast to TInputBox at the top, so the
'                                              Global itself is NOT declared TInputBox)
'      0x00C65C6C g_editkits_screen:TScreen   (slot 0x90 = TScreen.GetGadgetByName)
'      0x00C65C70 g_editkits_team:TBase_Team  (fields +0x44/+0x48/+0x4C/+0x50 =
'                                              kitcolsHome/Away/Third/Keeper:TKitStrings)
'      0x00C65CE8/CF8/D08/D18 the four TGadget[] input-box arrays.
'    globals_final.tsv types the four arrays Object[] and the two objects Object; the
'    concrete types come from the field offsets: TKitStrings is the only Type whose
'    +0x0C..+0x18 are four Strings, and TBase_Team the only one holding four of them
'    at +0x44..+0x50.
'  * The per-index dispatch is a Select: the subject is copied to edx once and all four
'    `cmp edx,N / je` sit back to back before any body (guide 10.2).
'  * `To 3` not `Until 4` -- the loop closes with `cmp edi,3 / jle`.
'  * 0x00C63058 is TCombo's class table, pushed well before the concat because it is
'    the downcast's argument; it is not an argument of _bbStringFromInt.
'  * RefreshKits is TScreen_EditKits' own class-table slot 0x3C, so it is unqualified.
	'!Global g_editkits_focus:TGadget
	'!Global g_editkits_screen:TScreen
	'!Global g_editkits_team:TBase_Team
	'!Global g_editkits_inp_shirt1:TGadget[]
	'!Global g_editkits_inp_shirt2:TGadget[]
	'!Global g_editkits_inp_shorts:TGadget[]
	'!Global g_editkits_inp_socks:TGadget[]
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Local s:String = (TInputBox(g_editkits_focus).GetText()).ToUpper()
	Local cmb:TCombo = Null
	Local ks:TKitStrings = Null
	For Local i:Int = 0 To 3
		Select i
			Case 0
				ks = g_editkits_team.kitcolsHome
			Case 1
				ks = g_editkits_team.kitcolsAway
			Case 2
				ks = g_editkits_team.kitcolsThird
			Case 3
				ks = g_editkits_team.kitcolsKeeper
		End Select
		If g_editkits_inp_shirt1[i] = g_editkits_focus
			ks.shirt1 = s
			cmb = TCombo(g_editkits_screen.GetGadgetByName("cmb_Shirt1" + i))
		EndIf
		If g_editkits_inp_shirt2[i] = g_editkits_focus
			ks.shirt2 = s
			cmb = TCombo(g_editkits_screen.GetGadgetByName("cmb_Shirt2" + i))
		EndIf
		If g_editkits_inp_shorts[i] = g_editkits_focus
			ks.shorts = s
			cmb = TCombo(g_editkits_screen.GetGadgetByName("cmb_Shorts" + i))
		EndIf
		If g_editkits_inp_socks[i] = g_editkits_focus
			ks.socks = s
			cmb = TCombo(g_editkits_screen.GetGadgetByName("cmb_Socks" + i))
		EndIf
	Next
	cmb.btn_head.SetColour(s, "FFFFFF")
	RefreshKits()

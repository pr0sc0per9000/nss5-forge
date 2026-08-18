' TScreen_EditKits.UpdateKitCmb
' VA 0x00535c91   1027 bytes   vtable slot 0x40   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (1027/1027, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=53), verified with NSS5_NO_LEARN=1.
'
' Global names are ours; the TYPES are load-bearing:
'   0x00C61CF8 g_ek_activegadget:TGadget  -- declared as a base type, the body downcasts it
'                                            with TCombo(...) (bbObjectDowncast at +0x14)
'   0x00C65C70 g_ek_team:TBase_Team       -- only kitcols* (+0x44..+0x50) are touched
'   0x00C65CA4/CB0/CBC/CCC/CD8  TCombo[]  -- globals_final.tsv says Object[]
'
' BOTH dispatches are Select, not If/ElseIf (guide 10.2): every Case compare is emitted back
' to back (0x00535CE0.. and 0x00535D33..) with all targets past the last compare, and each
' has NO Default -- the fallthrough is a plain `jmp` to the statement after End Select.
' The loop is `To 3` (cmp edi,3 / jle at 0x00536077), not `Until 4`.
'!Global g_ek_activegadget:TGadget
'!Global g_ek_team:TBase_Team
'!Global g_ek_cmb_style:TCombo[]
'!Global g_ek_cmb_shirt1:TCombo[]
'!Global g_ek_cmb_shirt2:TCombo[]
'!Global g_ek_cmb_shorts:TCombo[]
'!Global g_ek_cmb_socks:TCombo[]
Local cmb:TCombo = TCombo(g_ek_activegadget)
Local col:String = cmb.GetSelectedColour()
cmb.SetColour(col, "FFFFFF")
Local k:TKitStrings = Null
For Local i:Int = 0 To 3
	Select i
	Case 0
		k = g_ek_team.kitcolsHome
	Case 1
		k = g_ek_team.kitcolsAway
	Case 2
		k = g_ek_team.kitcolsThird
	Case 3
		k = g_ek_team.kitcolsKeeper
	End Select
	Select g_ek_cmb_style[i].GetSelectedItem()
		Case 1
			k.style = "PLAIN"
		Case 2
			k.style = "STRIPES"
		Case 3
			k.style = "SLEEVES"
		Case 4
			k.style = "SLEEVE"
		Case 5
			k.style = "HOOPS"
		Case 6
			k.style = "SINGLEHOOP"
		Case 7
			k.style = "SPLIT"
		Case 8
			k.style = "DIAGONALSPLIT"
		Case 9
			k.style = "SEGMENTS"
		Case 10
			k.style = "STRIPE_LR"
		Case 11
			k.style = "STRIPE"
		Case 12
			k.style = "STRIPE_C"
		Case 13
			k.style = "STRIPE_V"
		Case 14
			k.style = "CHEQUERED"
		Case 15
			k.style = "TRIM"
	End Select
	If g_ek_cmb_shirt1[i] = g_ek_activegadget Then k.shirt1 = col
	If g_ek_cmb_shirt2[i] = g_ek_activegadget Then k.shirt2 = col
	If g_ek_cmb_shorts[i] = g_ek_activegadget Then k.shorts = col
	If g_ek_cmb_socks[i] = g_ek_activegadget Then k.socks = col
Next
TScreen_EditKits.RefreshKits()

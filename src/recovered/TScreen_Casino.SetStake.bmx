' TScreen_Casino.SetStake
' VA 0x005742B8   375 bytes   vtable slot 0x3C   sig ()i
' byte-identical vs NSS5.exe (375/375, original length from Ghidra's inventory)

'!Global g_casino_panel:TPanel
'!Global g_activegadget:TGadget
'!Global g_colour_sel:String
'!Global g_stake:Int
For Local g:TGadget = EachIn g_casino_panel.children
	g.SetColour("FFFFFF", "FFFFFF")
	If g = g_activegadget Then g.SetColour(g_colour_sel, "FFFFFF")
Next
Select TGadget.GetActiveGadgetName()
Case "btn_stake1"
	g_stake = 50
Case "btn_stake2"
	g_stake = 100
Case "btn_stake3"
	g_stake = 250
Case "btn_stake4"
	g_stake = 500
Case "btn_stake5"
	g_stake = 1000
Case "btn_stake6"
	g_stake = 2500
Case "btn_stake7"
	g_stake = 5000
End Select

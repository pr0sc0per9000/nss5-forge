' TScreen_Stable.SetStake
' VA 0x00588687   375 bytes   class-table slot 0x54   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (375/375, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. 0x00C6DEE8 TPanel, 0x00C61CF8 TGadget (the selected gadget --
' this address is 8 bytes PAST the end of TScreen's class table, so it is a real Global),
' 0x00C6E91C String ("00FF00"), 0x00C6DF68 Int (the stake).
' The trailing Select has no Default: the last compare is followed by a jmp to after the
' bodies (patterns 10.2).
'!Global g_stable_panel:TPanel
'!Global g_activegadget:TGadget
'!Global g_greenhex:String
'!Global g_stakeamount:Int
	Function SetStake:Int()
		For Local g:TGadget = EachIn g_stable_panel.children
			g.SetColour("FFFFFF", "FFFFFF")
			If g = g_activegadget Then g.SetColour(g_greenhex, "FFFFFF")
		Next
		Select TGadget.GetActiveGadgetName()
			Case "btn_stake1"
				g_stakeamount = 50
			Case "btn_stake2"
				g_stakeamount = 100
			Case "btn_stake3"
				g_stakeamount = 250
			Case "btn_stake4"
				g_stakeamount = 500
			Case "btn_stake5"
				g_stakeamount = 1000
			Case "btn_stake6"
				g_stakeamount = 2500
			Case "btn_stake7"
				g_stakeamount = 5000
		End Select
	End Function

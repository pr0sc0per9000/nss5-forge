' TScreen_Options.ButtonCurrency
' VA 0x00521558   125 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' assumes module global at 0x00C5D274 typed Int (currency setting)
' 0x00C621CC = TGadget + 0x7c = GetActiveGadgetName()$; 0x00C64064 = TScreen_Options + 0x38
' = RefreshButtons()i. String constants read from NSS5.exe at 0x00C7F7DC/828/874.
' The `je <case body>` fan-out plus trailing `jmp` is Select/Case, not If/ElseIf
' (If/ElseIf builds 4 bytes short at 121).
	Function ButtonCurrency:Int()
		'!Global g_currency:Int
		Select TGadget.GetActiveGadgetName()
			Case "options_currencyUSD"
				g_currency = 1
			Case "options_currencyGBP"
				g_currency = 2
			Case "options_currencyEUR"
				g_currency = 3
		End Select
		RefreshButtons()
	End Function

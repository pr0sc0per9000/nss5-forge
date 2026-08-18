' TScreen_Shop.HidePanels
' VA 0x005431ac   56 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (56/56, original length from Ghidra's inventory)
' assumes module globals:  Global g_shop_panel1:TPanel  (0x00c66d44)
'                          Global g_shop_panel2:TPanel  (0x00c66d48)
'                          Global g_shop_panel3:TPanel  (0x00c66d4c)
' slot 0x54 is TGadget.Hide, inherited by TPanel -- any TGadget subclass would emit
' the same bytes, so the exact TPanel typing is an assumption

	Function HidePanels:Int()
		'!Global g_shop_panel1:TPanel
		'!Global g_shop_panel2:TPanel
		'!Global g_shop_panel3:TPanel
		g_shop_panel1.Hide()
		g_shop_panel2.Hide()
		g_shop_panel3.Hide()
	End Function

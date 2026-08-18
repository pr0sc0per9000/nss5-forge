' TScreen_MainMenu.Update
' VA 0x0051CEBD   339 bytes
' byte-identical vs NSS5.exe (339/339, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_mm_items:String[]
'!Global g_mm_panel:TPanel
'!Global g_screen_fx:Float
'!Global g_screen_fy:Float
'!Global g_mm_lasttime:Int
'!Global g_mm_index:Int
'!Global g_mm_delay:Int
' g_mm_offx/g_mm_offw original data-section values are 10.0 / 20.0
' (0x00C7EC90 / 0x00C7EC94). Never stored to anywhere in the corpus -- see
' codegen-patterns 21.1.
'!Global g_mm_offx:Float = 10.0
'!Global g_mm_offw:Float = 20.0
'!Global g_now:Int
If g_mm_items.Length > 0 And g_now > g_mm_lasttime + g_mm_delay + 1500 And TScreenMessage.Count() = 0
	g_mm_lasttime = g_now
	Local ix:Int = Int(g_screen_fx + g_mm_panel.x + g_mm_offx)
	Local iy:Int = Int(g_screen_fy + g_mm_panel.y + g_mm_panel.h)
	Local ty:Int = 2
	If g_mm_items[g_mm_index] <> ""
		TScreenMessage.CreateAlert(ix, iy, g_mm_items[g_mm_index], g_mm_delay, "888888", "FFFFFF", Null, ty, Int(g_mm_panel.w - g_mm_offw), 25, 1, 3)
	End If
	g_mm_index :+ 1
	If g_mm_index >= g_mm_items.Length Then g_mm_index = 0
End If

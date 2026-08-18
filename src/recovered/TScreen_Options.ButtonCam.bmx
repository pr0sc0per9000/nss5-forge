' TScreen_Options.ButtonCam
' VA 0x005211BB   160 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (160/160, original length from Ghidra's inventory)
' assumptions: 0x00C5D24C Int; TGadget.name is the field at +0x0C; Select (not If/ElseIf)
' per the back-to-back _bbStringCompare run -- ElseIf comes out 156.
' 0x00C61CF8 is g_activegadget:TGadget, the same slot and name the rest of the corpus uses.
' Neither the name nor the type is byte-observable HERE (the Global is only downcast, so
' Object and TGadget emit the same bytes), but the type is TGadget -- 0x005114C7 calls its
' +0x40 function-pointer field, which Object has no room for. See
' extracted/globals_corrections.tsv.
	Function ButtonCam:Int()
		'!Global g_activegadget:TGadget
		'!Global g_camtype:Int
		Select TButton(g_activegadget).name
			Case "options_camball"
				g_camtype = 0
			Case "options_camplayer"
				g_camtype = 1
			Case "options_camzoom"
				If g_camtype = 2
					g_camtype = 3
				Else
					g_camtype = 2
				EndIf
		End Select
		RefreshButtons()
	End Function

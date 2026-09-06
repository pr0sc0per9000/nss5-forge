' TSlotMachine.Draw
' VA 0x005783E4   133 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory)
' assumptions: Globals 0x00C6C558/55C/560 declared TSlotStrip (slot 0x3c = Draw),
' 0x00C6C54C TImage, 0x00C6EFE4/E8 Int; string literal "FFFFFF" read from .data;
' 0x00506456 is the recovered module Function SetDrawStateHex.
	Function Draw:Int()
		'!Global g_slotstrip1:TSlotStrip
		'!Global g_slotstrip2:TSlotStrip
		'!Global g_slotstrip3:TSlotStrip
		'!Global g_slotmachineimage:TImage
		' THE RUNTIME WINDOW SIZE IS 0x00C6EFE4/0x00C6EFE8, NOT 0x00C6EFDC/0x00C6EFE0.
' The lower pair are the 800x600 DESIGN canvas: they are static initialisers in the PE
' image and no instruction anywhere in the program stores to them. The upper pair are
' written from the chosen TGraphicsMode in FUN_00506A5D (0x00506AF6
' `mov [0xc6efe4],eax`, fallback 0x00506B3A `mov [0xc6efe4],0x320`).
' TScreen.UpdateOffset settles which is which: 0x00510825 `mov eax,[0xc6efe4]` /
' `sub eax,[0xc6efdc]` halved into the borderX float, and 0x00510844 the same for
' 0x00C6EFE8 minus 0x00C6EFE0 into borderY.
' This SetViewport resets the viewport to the whole WINDOW, so it reads the upper pair:
' the original pushes [0xc6efe8] then [0xc6efe4]. Spelled g_screenwidth/g_screenheight it
' shared the emitted variables of the 800x600 constants, and above 800x600 the viewport
' was clipped to the top-left 800x600 of the window, cutting off the right-hand reels.
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		g_slotstrip1.Draw()
		g_slotstrip2.Draw()
		g_slotstrip3.Draw()
		SetViewport(0, 0, g_screen_w, g_screen_h)
		DrawImage(g_slotmachineimage, 202.0, 172.0, 0)
	End Function

' TSlotMachine.Update
' VA 0x00578366   126 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' Assumes four module Globals (original names unrecoverable):
'   g_reel1/g_reel2/g_reel3:TSlotStrip (0x00c6c558/55c/560) -- the declared type is fixed
'   by slot 0x34 = Update together with the Int field at +0x28 (reelstopped); TSlotStrip
'   is the only Type in the model with both.
'   g_slotstate:Int (0x00c6c564)
' 0x00c6c650 = TSlotMachine+0x44 (DoPrize), 0x00c6c544 = TScreen_Slots+0x34 (SetUpScreen).
	Function Update:Int()
		'!Global g_reel1:TSlotStrip
		'!Global g_reel2:TSlotStrip
		'!Global g_reel3:TSlotStrip
		'!Global g_slotstate:Int
		g_reel1.Update()
		g_reel2.Update()
		g_reel3.Update()
		If g_reel1.reelstopped And g_reel2.reelstopped And g_reel3.reelstopped
			If g_slotstate
				TSlotMachine.DoPrize()
				TScreen_Slots.SetUpScreen()
			EndIf
			g_slotstate = 0
		EndIf
	End Function

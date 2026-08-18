' TSlotStrip.SetUp
' VA 0x005786f6   231 bytes   vtable slot 0x30   sig (i,i)i
' byte-identical vs NSS5.exe (231/231, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. 0x00C6E950 String (media path prefix), 0x00C6C654 TSound,
' 0x00C6C658 TImage.  Lazy one-time asset load guarded by `If Not <sound global>`.
'!Global g_mediaPrefix:String
'!Global g_snd_slotsstop:TSound
'!Global g_img_slotstrip:TImage
	Method SetUp:Int(a0:Int, a1:Int)
		If Not g_snd_slotsstop
			g_snd_slotsstop = LoadSoundChecked(g_mediaPrefix + "GameMedia/Sounds/Casino/SlotsStop.ogg", 0)
			g_img_slotstrip = LoadImageChecked("GameMedia/Images/Casino/Slots/Strip.png", -1)
		EndIf
		Self.fruitCount = 8
		If a1 Then Self.fruitCount = 6
		Self.reelH = ImageHeight(g_img_slotstrip)
		Self.xPos = a0
		Self.yPos1 = 0
		Self.yPos2 = Self.yPos1 - Self.reelH
		Self.yVel = 0
		Self.reelstopped = 1
	End Method

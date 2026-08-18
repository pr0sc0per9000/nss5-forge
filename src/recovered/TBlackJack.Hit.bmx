' TBlackJack.Hit
' VA 0x0057726a   176 bytes   vtable slot 0x4c   sig (:TList)i
' byte-identical vs NSS5.exe (176/176, original length from Ghidra's inventory, mode=reloc)
' Globals: 0x00C6C168 g_snd_card:TSound, 0x00C6F090 g_chan:TChannel.
' PTR_FUN_00C6C48C is TCard's class table + slot 0x3c = TCard.Pull(). The `bVar1=!bVar2;
' if(!bVar1) bVar1 = 1 < num` shape is a short-circuit Or, and the do/while is Repeat/Until.
	Function Hit:Int(a0:TList)
		'!Global g_snd_card:TSound
		'!Global g_chan:TChannel
		Local ace:Int = False
		For Local c:TCard = EachIn a0
			If c.num = 1 Then ace = True
		Next
		Local card:TCard
		Repeat
			card = TCard.Pull()
		Until Not ace Or card.num > 1
		a0.AddLast(card)
		PlaySound(g_snd_card, g_chan)
	End Function

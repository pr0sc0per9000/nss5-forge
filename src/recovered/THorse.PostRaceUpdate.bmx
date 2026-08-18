' THorse.PostRaceUpdate
' VA 0x0058b0dc   330 bytes   vtable slot 0x64   sig (i)i
' byte-identical vs NSS5.exe (330/330, original length from Ghidra's inventory, mode=reloc)
'
' `form` is []i; the five slots are read at BBArray data offset +0x18..+0x28, i.e. [0]..[4].
' Rnd() is the Double-returning brl.random Rnd (0x0059F048), so the arguments and the
' intermediate results are qwords.
	Method PostRaceUpdate:Int(a0:Int)
		Self.form[0] = Self.form[1]
		Self.form[1] = Self.form[2]
		Self.form[2] = Self.form[3]
		Self.form[3] = Self.form[4]
		Self.form[4] = a0
		If Self.owned = 1
			Self.strength = Self.strength + Rnd(0.5, 2.5)
			If Self.energy < 20.0
				Self.health = Self.health - Rnd(25.0, 50.0)
				TScreen.DoMessage(GetText("CMESSAGE_HORSEEXHAUSTED").Replace("$name", Self.name), 0, 0)
			EndIf
		EndIf
		ClampFloat(Varptr Self.strength, 30.0, 100.0)
		ClampFloat(Varptr Self.health, 1.0, 100.0)
		ClampFloat(Varptr Self.energy, 1.0, 100.0)
	End Method

' TTeam.Clear
' VA 0x004dd35b   189 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (189/189, original length from Ghidra's inventory)
	Method Clear:Int()
		formation = Null
		If cornerformation <> Null Then cornerformation.Clear()
		If kitplayer <> Null Then kitplayer.Clear()
		If kitkeeper <> Null Then kitkeeper.Clear()
		kitplayer = Null
		kitkeeper = Null
		If squad <> Null Then squad.Clear()
	End Method

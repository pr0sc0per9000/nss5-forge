' TTeam.CreateReplayTeam
' VA 0x004DDA91   186 bytes   vtable slot 0x4c   sig (:TReplay,i,$,$,:TKit,:TKit,i):TTeam
' byte-identical vs NSS5.exe (186/186, original length from Ghidra's inventory)
' Slots 0x50/0x54 on TTeam are CreateReplaySquad(:TReplay) and PaintSquad(i).
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Function CreateReplayTeam:TTeam(a0:TReplay, a1:Int, a2:String, a3:String, a4:TKit, a5:TKit, a6:Int)
		Local t:TTeam = New TTeam
		t.id = a1
		t.name = a2
		t.tla = a3
		t.rating = 100
		t.controller = 0
		t.kitplayer = a4
		t.kitkeeper = a5
		t.CreateReplaySquad(a0)
		t.PaintSquad(a6)
		Return t
	End Function

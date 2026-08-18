' TPlayer.CreateReplayPlayer
' VA 0x004EDF4D   196 bytes   vtable slot 0x3C   sig (:TReplayFrame):TPlayer
' byte-identical vs NSS5.exe (196/196, original length from Ghidra's inventory, mode=reloc)
' assumptions: 0x005B40BF is CreateList (alias set gnet.TGNetHost.Create|CreateList|CreateMap;
' the inferred table resolves it to _brl_linkedlist_CreateList, and TPlayer.replayframes is a
' TList) -- writing `New TList` would emit bbObjectNew instead and not match.
' PTR_FUN_00C5C4D8 resolves to TKit class table + slot 0x58 = TKit.GetBootColour(i)$, used for
' both the boot and the glove colour.
' skincol/haircol are copied with a bare dword move and no refcount traffic, so they are Ints;
' bootcol/glovecol carry retain/release, so they are Strings.
	Function CreateReplayPlayer:TPlayer(a0:TReplayFrame)
		Local p:TPlayer = New TPlayer
		p.id = a0.id
		p.selectionno = a0.selno
		p.teamid = a0.clubid
		p.replayframes = CreateList()
		p.skincol = a0.skincol
		p.haircol = a0.haircol
		p.bootcol = TKit.GetBootColour(a0.bootcol)
		p.glovecol = TKit.GetBootColour(a0.glovecol)
		Return p
	End Function

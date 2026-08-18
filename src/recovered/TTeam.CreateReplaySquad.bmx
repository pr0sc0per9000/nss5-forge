' TTeam.CreateReplaySquad
' VA 0x004DDB4B   441 bytes   vtable slot 0x50   sig (:TReplay)i   KIND=Method
' byte-identical vs NSS5.exe (441/441, original length from Ghidra's inventory, mode=reloc)
' assumptions: no module Globals needed.
' slots resolved:
'   [0x00C5F988] = TPlayer classtable + 0x3C = TPlayer.CreateReplayPlayer(:TReplayFrame)
'   TList slots used through Self.squad / p.replayframes: 0x34 Clear, 0x44 AddLast,
'     0x8C ObjectEnumerator (the last emitted by For EachIn itself)
'   0x005B40BF is the CreateList|CreateMap|TGNetHost.Create alias set; CreateList is
'     confirmed by the following AddLast at slot 0x44 (codegen-patterns 10.8)
' downcast class tables: 0x00C6008C = TReplayFrame, 0x00C5F94C = TPlayer.
' fields: TTeam +0x08 id, +0x1C squad:TList; TReplay +0x50 playerframes:TList;
'         TReplayFrame +0x14 id, +0x1C clubid; TPlayer +0x10 id, +0x160 replayframes:TList.
' Shape notes: the first guard is `If Not Self.squad` (setne/movzx, 10.3) while the second
' is `If Self.squad <> Null` (bare cmp/je) -- the two spellings genuinely both occur here
' and are 9 bytes apart. `f.id > lastid And f.clubid = Self.id` is a short-circuit And
' (setg, then sete, then one cmp/je), whereas the inner loop's `p.id = f.id` is a single
' comparison branched directly with jne.
	Method CreateReplaySquad:Int(a0:TReplay)
		If Not Self.squad
			Self.squad = CreateList()
		EndIf
		If Self.squad <> Null
			Self.squad.Clear()
		EndIf
		Local lastid:Int = 0
		For Local f:TReplayFrame = EachIn a0.playerframes
			If f.id > lastid And f.clubid = Self.id
				Self.squad.AddLast(TPlayer.CreateReplayPlayer(f))
				lastid = f.id
			EndIf
		Next
		For Local p:TPlayer = EachIn Self.squad
			For Local f:TReplayFrame = EachIn a0.playerframes
				If p.id = f.id
					p.replayframes.AddLast(f)
				EndIf
			Next
		Next
	End Method

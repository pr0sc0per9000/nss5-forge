' TBall.CreateReplayBalls  -- Function (:TReplay)i   slot 0x3c   (static method on the Type)
' VA 0x004C7E4B   441 bytes
' byte-identical vs NSS5.exe (441/441, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=23)
'
' ASSUMPTIONS
'  * Global 0x00C5A4C0 declared TList, named g_replayballs. globals_final.tsv has it as
'    bare `Object` (type_source=usage, confidence=low, "init=bbNullObject, no call-site
'    typing"); TList is forced by the call sites here -- slot 0x34 Clear and slot 0x8C
'    ObjectEnumerator (vtable_map.tsv TList).
'  * FUN_005B40BF = CreateList (alias set CreateList|CreateMap|TGNetHost.Create; the
'    confirming tell per guide 10.8 is the AddLast at slot 0x44 on the same list).
'  * Guard shapes taken from the bytes, not from Ghidra's rendering:
'      0x004C7E54 setne al / movzx / cmp 0 / jne  -> `If Not g` (guide 10.3, 21-byte form)
'      0x004C7E8C cmp dword [g], bbNullObject / je -> `If g <> Null` (12-byte form)
'  * `cmp [edi+0x14], ebx / jle` at 0x004C7EEC fixes the operand order as
'    `If rf.id > lastid`, not `If lastid < rf.id` (guide 10.1).
'  * The new TBall is deliberately never added to a list here -- the original does not do
'    it either; registration happens inside TBall.New.
'  * Field offsets from object_model.json: TReplay.ballframes 0x4C, TReplayFrame.id 0x14,
'    TBall.id 0x08, TBall.replayframes 0xAC.
	Function CreateReplayBalls:Int(a0:TReplay)
		'!Global g_replayballs:TList
		If Not g_replayballs Then g_replayballs = CreateList()
		If g_replayballs <> Null Then g_replayballs.Clear()
		Local lastid:Int = 0
		For Local rf:TReplayFrame = EachIn a0.ballframes
			If rf.id > lastid
				Local nb:TBall = New TBall
				nb.id = rf.id
				nb.replayframes = CreateList()
				lastid = rf.id
			EndIf
		Next
		For Local b:TBall = EachIn g_replayballs
			For Local rf2:TReplayFrame = EachIn a0.ballframes
				If b.id = rf2.id Then b.replayframes.AddLast(rf2)
			Next
		Next
	End Function

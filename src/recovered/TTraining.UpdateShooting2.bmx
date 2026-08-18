' TTraining.UpdateShooting2
' VA 0x00580F6B   603 bytes   vtable slot 0x84   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (603/603, original length from Ghidra's inventory)
' Same family as TTraining.UpdatePassing (0x00580C44, 553 bytes, already verified) --
' the restart-flag / SetUpSetPiece / trailing Success() skeleton is shared.
'
' ASSUMPTIONS
'  Class-table slot calls:
'    0x00C5AEDC TBall+0x44   GetActiveBall():TBall
'    0x00C5FAB0 TPlayer+0x164 GetHumanPlayer():TPlayer
'    0x00C5BAA0 TEngine+0x70  SetUpSetPiece(i,i,i,i)
'    0x00C6D53C TTraining+0x98 Success()  -- this Type, so unqualified
'    0x00C5D998 TPitch+0x6C   YardsToPixels(f)f
'    TBall slot 0x88 = KeeperHolding()i
'    downcast class table 0x00C6D898 = TDummy (extends TTrainingObject, alive at +0x18)
'  Direct call 0x00505DA2 = Dist2D (src/recovered_module/Dist2D.bmx)
'  Module Globals (names ours, types load-bearing; all bare dword access -> Int):
'    0x00C6EFD4 g_ticks             0x00C6D568 g_trainobjs:TList (slot 0x8C used on it)
'    0x00C5D638 g_goalliney         0x00C6CFF8 g_training_int21 (same Global UpdateShooting1
'                                                                tests)
'    0x00C6CFD8 g_training_setpiecex  0x00C6CFDC g_training_setpiecey
'  Field offsets from extracted/object_model.json: TBall kicktime 0x64, controlledby 0x70,
'    lastkickedby 0x74, x 0x18, y 0x1C, velocity 0x54; TPlayer keepercatchtime 0x90,
'    selectionno 0xBC; TTrainingObject alive 0x18. Float constant 0x00C92928 = 2.0.
' SHAPE NOTES (byte-observable)
'  * The three restart tests are one If / ElseIf / ElseIf CASCADE -- the first two arms end
'    with `mov [ebp-8],1` followed by a jmp all the way to the final `cmp [ebp-8],0`, which
'    is what an ElseIf chain emits; as three separate Ifs the jumps would be local.
'  * The cone scan is `Exit`, not a plain flag set: the loop body jumps past the enumerator's
'    HasNext call, not back to it.
'  * `Dist2D(0.0, -g_goalliney, b.x, b.y)` -- the negation is `neg eax` on the Int Global
'    before the fild, so the minus is in the source, not folded into the constant.
'  * The last pair is an And whose left operand is the Float Local `d`: bcc keeps d in a real
'    stack slot here ([ebp-4]) because the YardsToPixels call intervenes.
	Function UpdateShooting2:Int()
		'!Global g_ticks:Int
		'!Global g_trainobjs:TList
		'!Global g_goalliney:Int
		'!Global g_training_int21:Int
		'!Global g_training_setpiecex:Int
		'!Global g_training_setpiecey:Int
		Local b:TBall = TBall.GetActiveBall()
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If b <> Null
			Local restart:Int = 0
			If b.KeeperHolding() And g_ticks > b.controlledby.keepercatchtime + 500
				restart = 1
			ElseIf b.KeeperHolding() = 0 And b.lastkickedby <> Null And b.lastkickedby.selectionno = 0 And g_ticks > b.kicktime + 350
				restart = 1
			ElseIf b.lastkickedby = p And b.kicktime > 0 And g_ticks > b.kicktime + 1000
				For Local c:TDummy = EachIn g_trainobjs
					If c.alive = 0
						restart = 1
						Exit
					EndIf
				Next
				If b.controlledby = p Then restart = 1
				If g_ticks > b.kicktime + 3500 Then restart = 1
				If b.y > 0.0 Then restart = 1
				Local d:Float = Dist2D(0.0, -g_goalliney, b.x, b.y)
				If d > TPitch.YardsToPixels(10.0) And b.velocity < 2.0
					restart = 1
				EndIf
			EndIf
			If restart Then TEngine.SetUpSetPiece(4, 1, g_training_setpiecex, g_training_setpiecey)
		EndIf
		If g_training_int21 = 0 Then Success()
	End Function

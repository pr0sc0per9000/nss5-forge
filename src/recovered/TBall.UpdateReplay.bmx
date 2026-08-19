' TBall.UpdateReplay
' byte-identical vs NSS5.exe
' VA 0x004CC0B6   471 bytes   mode=reloc   MATCH 471/471
' KIND=Method on TBall, SIG=(i)i, SLOT=0xB4
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Global declared here (name is ours; the original is unrecoverable):
'     0x00C5DE10 -> g_players:TList
'         globals_final says Object/usage/low. Typed TList from the code: slot 0x8C
'         (TList.ObjectEnumerator) is called on it and the loop downcasts to
'         ClassTable_TPlayer.
'   Fields (object_model.json):
'     TBall   +0x10 alph, +0x14 colour$, +0x18/1C/20 x,y,z, +0x24/28/2C oldx,oldy,oldz,
'             +0xA0 frame, +0xA8 hideball, +0xAC replayframes:TList
'     TReplayFrame +0x08 frametime, +0x0C obtext$, +0x30/34/38 x,y,z, +0x48 frame, +0x54 alph
'     TPlayer +0xBC selectionno, +0x160 replayframes:TList; slot 0x1AC ImageHoldingBall(i)i
'   `Self.alph = 0` really is INSIDE the first loop -- Ghidra folds it into the loop
'   condition as a comma expression, and it executes once per non-Null iteration.
'   Both `Exit`s are real: the inner loop leaves after the first frametime match, which in
'   the decompilation shows up as a jump back to the outer enumerator's HasNext.
'!Global g_players:TList
Self.oldx = Self.x
Self.oldy = Self.y
Self.oldz = Self.z
For Local rf:TReplayFrame = EachIn Self.replayframes
	Self.alph = 0
	If rf.frametime = a0
		Self.x = rf.x
		Self.y = rf.y
		Self.z = rf.z
		Self.frame = rf.frame
		Self.alph = rf.alph
		Self.colour = rf.obtext
		Exit
	EndIf
Next
Self.hideball = 0
For Local p:TPlayer = EachIn g_players
	If p.selectionno = 0
		For Local rf2:TReplayFrame = EachIn p.replayframes
			If rf2.frametime = a0
				If p.ImageHoldingBall(rf2.frame)
					Self.hideball = 1
					Return 0
				EndIf
				Exit
			EndIf
		Next
	EndIf
Next

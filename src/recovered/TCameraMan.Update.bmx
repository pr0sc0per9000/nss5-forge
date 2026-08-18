' TCameraMan.Update
' VA 0x004EB697   650 bytes   vtable slot 0x40   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (650/650, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=32)
' Body-only format: statements only, Self implicit.
' assumptions (module Globals, names ours):
'   0x00C78A90 : Float   -- the camera's default target x  (globals_final: Float, usage/high)
'   0x00C78A94 : Float   -- the camera's default target y  (globals_final: Float, usage/high)
'   0x00C5B1CC : Int     -- the engine mode (3 = replay)
'   0x00C5B1FC : Int     -- the replay/camera sub-mode (8). globals_final type_source=verified.
'   0x00C5B2C8 : Int     -- the replay frame time cursor
'   0x00C5DE10 : TList   -- every TPlayer. bare Object/usage/low in globals_final; TList is
'                           forced by the 0x8C ObjectEnumerator call, element type from the
'                           downcast class table = TPlayer.
'   0x00C5A4C0 : TList   -- every TBall, same reasoning.
'   0x00C5B248 : TPlayer -- the followed player; +0x4C/+0x50 are TPlayer.x/.y.
' slots resolved: 0x00C5AEDC = TBall classtable + 0x44 = TBall.GetActiveBall():TBall. It is
'   a call on ANOTHER Type from inside TCameraMan, so it keeps the `TBall.` prefix.
'   TList 0x8C/0x30/0x34 = ObjectEnumerator/HasNext/NextObject.
' fields: TPlayer.replayframes +0x160, TBall.replayframes +0xAC, TReplayFrame.frametime +0x08,
'   TReplayFrame.active +0x58.
' AngleTo is the recovered module Function at 0x0050639D.
' load-bearing shape: the inner replay-frame search ends in `Exit`, not a flag -- the original
' branches straight to the OUTER loop's HasNext once a frame matches.
' `f.active` is the bare truth value as the second operand of the And; `f.active <> 0` would
' add a 9-byte cmp/setne/movzx triple.
	Method Update:Int()
		'!Global g_cam_targetx:Float
		'!Global g_cam_targety:Float
		'!Global g_engine_state:Int
		'!Global g_replay_mode:Int
		'!Global g_players:TList
		'!Global g_replay_time:Int
		'!Global g_balls:TList
		'!Global g_focusplayer:TPlayer
		Local tx:Float = g_cam_targetx
		Local ty:Float = g_cam_targety
		If g_engine_state = 3
			If g_replay_mode = 8 And g_players <> Null
				For Local p:TPlayer = EachIn g_players
					For Local f:TReplayFrame = EachIn p.replayframes
						If f.frametime = g_replay_time And f.active
							tx = p.x
							ty = p.y
							Exit
						EndIf
					Next
				Next
			ElseIf g_balls <> Null
				For Local b:TBall = EachIn g_balls
					For Local f:TReplayFrame = EachIn b.replayframes
						If f.frametime = g_replay_time And f.active
							tx = b.x
							ty = b.y
							Exit
						EndIf
					Next
				Next
			EndIf
		Else
			Local b:TBall = TBall.GetActiveBall()
			If b <> Null
				tx = b.x
				ty = b.y
			EndIf
			If g_replay_mode = 8 And g_focusplayer <> Null
				tx = g_focusplayer.x
				ty = g_focusplayer.y
			EndIf
		EndIf
		Self.rot = AngleTo(Self.x, Self.y, tx, ty)
	End Method

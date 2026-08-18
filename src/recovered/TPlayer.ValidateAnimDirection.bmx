' TPlayer.ValidateAnimDirection
' VA 0x004FC1B5   1018 bytes   vtable slot 0x198   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (1018/1018, original length from Ghidra's inventory, mode=reloc)
'
' ASSUMPTIONS
'  Self.currentanim ([]i, +0x130) is compared by IDENTITY against the g_player_arrNN
'  Global Int[] table (0x00C5DEAC..0x00C5DF1C), the same table GetStringAnim.bmx
'  decodes to names: arr01=Stand, arr03=Kick, arr04=Header, arr10-13=Celebrate1-4,
'  arr15-18=Commiserate1:{ScratchHead,FallOnFace,FallOnKnees,HoldHead}, arr19=StandGK,
'  arr20=StandWithBallGK, arr22=DiveGK, arr23=DiveFallGK, arr24=JumpGK,
'  arr25=JumpWithBallGK, arr26=CatchGK, arr27=CatchWithBallGK, arr28=CatchLowGK,
'  arr29=CatchLowWithBallGK. arr14 (Celebrate5) is genuinely absent from this chain --
'  the original skips straight from arr13 to arr15 (ORIGINAL BUG/omission, reproduced
'  faithfully, VA 0x004FC28B->0x004FC291).
'  arr27/arr28/arr29 (CatchWithBallGK/CatchLowGK/CatchLowWithBallGK) are three SEPARATE
'  empty Case blocks, each its own 2-byte `jmp` to the End Select exit -- NOT one combined
'  `Case a,b,c`, which would compile to a single shared body instead of three stub jumps.
'
'  Fields (object_model.json, byte offsets): x +0x4C(f), y +0x50(f), directiontoball
'  +0xCC(i), lastkickdirection +0xC8(f), directiontogoal_opp +0xE0(i), facing +0x128(i),
'  currentanim +0x130([]i).
'  0x00C5DEA4 = g_ball:TBall (globals_final type_source=verified); TBall.lastkickedby
'  +0x74 (TPlayer.DoKeeperDiveAI).
'  0x00C5B1FC = g_matchstate:Int, 0x00C5B208 = g_engine_half:Int (both already-established
'  names, TEngine.SkipTime.bmx).
'  Slots: TPlayer 0x16C = GetFacingDirection(f)i (TPlayer.GetFacingDirection.bmx);
'  0x148 = GetHuddlePosition(*i,*i)i -- the two params are Int Ptr, so the call site needs
'  `Varptr hx, Varptr hy`, not bare Locals (bcc rejects Int -> Int Ptr silently coercing).
'  0x0050639D = the already-recovered module Function AngleTo(f,f,f,f)f
'  (src/recovered_module/AngleTo.bmx).
'
' Argument order for both the GetHuddlePosition/AngleTo pair and the AngleTo(x,y,x,0) GK
' calls was taken directly from Ghidra's parameter ordering (it resolves cdecl push order
' correctly here), then confirmed by the harness MATCH.
	Method ValidateAnimDirection:Int()
		'!Global g_player_arr01:Int[]
		'!Global g_player_arr03:Int[]
		'!Global g_player_arr04:Int[]
		'!Global g_player_arr10:Int[]
		'!Global g_player_arr11:Int[]
		'!Global g_player_arr12:Int[]
		'!Global g_player_arr13:Int[]
		'!Global g_player_arr15:Int[]
		'!Global g_player_arr16:Int[]
		'!Global g_player_arr17:Int[]
		'!Global g_player_arr18:Int[]
		'!Global g_player_arr19:Int[]
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr22:Int[]
		'!Global g_player_arr23:Int[]
		'!Global g_player_arr24:Int[]
		'!Global g_player_arr25:Int[]
		'!Global g_player_arr26:Int[]
		'!Global g_player_arr27:Int[]
		'!Global g_player_arr28:Int[]
		'!Global g_player_arr29:Int[]
		'!Global g_matchstate:Int
		'!Global g_engine_half:Int
		'!Global g_ball:TBall
		Select Self.currentanim
			Case g_player_arr01
				Self.facing = Self.GetFacingDirection(Float(Self.directiontoball))
				If g_matchstate = 0 And (g_engine_half = 3 Or g_engine_half = 4)
					Local hx:Int
					Local hy:Int
					Self.GetHuddlePosition(Varptr hx, Varptr hy)
					Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Float(hx), Float(hy)))
				EndIf
			Case g_player_arr19
				Self.facing = Self.GetFacingDirection(Float(Self.directiontoball))
			Case g_player_arr20
				Self.facing = Self.GetFacingDirection(Float(Self.directiontogoal_opp))
			Case g_player_arr03
				Self.facing = Self.GetFacingDirection(Self.lastkickdirection)
			Case g_player_arr04
				If g_ball <> Null And g_ball.lastkickedby = Self
					Self.facing = Self.GetFacingDirection(Float(Self.directiontoball))
				EndIf
			Case g_player_arr24
				Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Self.x, 0))
			Case g_player_arr25
				Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Self.x, 0))
			Case g_player_arr22
				Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Self.x, 0))
			Case g_player_arr23
				Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Self.x, 0))
			Case g_player_arr26
				Self.facing = Self.GetFacingDirection(AngleTo(Self.x, Self.y, Self.x, 0))
			Case g_player_arr27
			Case g_player_arr28
			Case g_player_arr29
			Case g_player_arr10
				Self.facing = 2
			Case g_player_arr11
				Self.facing = 3
			Case g_player_arr12
				Self.facing = 0
			Case g_player_arr13
				Self.facing = 1
			Case g_player_arr15
				Self.facing = 2
			Case g_player_arr16
				Self.facing = 3
			Case g_player_arr17
				Self.facing = 0
			Case g_player_arr18
				Self.facing = 1
		End Select
	End Method

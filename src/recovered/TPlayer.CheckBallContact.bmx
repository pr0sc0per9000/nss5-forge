' TPlayer.CheckBallContact
' VA 0x004F55F2   5021 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0xE8
'
' ASSUMPTIONS  (module Global names are ours; the originals are unrecoverable)
'   g_ball            0x00C5DEA4 : TBall   -- globals_final type_source=verified. Fields
'                     used: kicktime +0x64, lastkickmatchstate +0x6C, controlledby +0x70,
'                     lasttouchedby +0x78, setpiecetaker +0x80, passtoid +0x9C,
'                     x/y/z +0x18/+0x1C/+0x20, oldx/oldy +0x24/+0x28,
'                     teaminpossession +0x60, velocity +0x54.
'   g_player_int01    0x00C5B1FC : Int     -- match state (8 = celebration, 1/10 = live)
'   g_player_int50    0x00C6EFD4 : Int     -- the millisecond clock
'   g_player_selected 0x00C5B248 : TPlayer -- globals_final usage/medium
'   g_player_int04    0x00C5B250 : Int
'   g_player_int15    0x00C5D228 : Int     -- difficulty / assist level (1..3)
'   g_player_float11  0x00C5DE68 : Float   -- base contact radius
'   g_player_float02  0x00C5DE44 : Float   -- the shared draw scale
'   g_player_int33    0x00C5DE70 : Int     -- ball/player height unit
'   g_player_int14    0x00C5D1AC : Int     -- control-scheme flag
'   g_tr_mode         0x00C6CF90 : Int     -- in-training flag
'   g_ballimg         0x00C5A4B0 : TImage  -- the ball sprite (globals_final says Object;
'                     it is passed as ImagesCollide2's image1, so TImage)
'   g_player_arr03/04/05/06/07 = 0x00C5DEB4/B8/BC/C0/C4
'   g_player_arr19..29         = 0x00C5DEF4/F8/FC, 0x00C5DF00/04/08/0C/10/14/18/1C
'                     all Int[] -- animation frame lists assigned to TPlayer.currentanim,
'                     which object_model.json types []i. arr05/06/22/28 are already
'                     type_source=verified as Int[]; the rest follow the family.
'   0x00C5BAA4 is NOT a Global: it is TEngine's class table + 0x74 = SetPiece()i.
'   0x00C5D998 is TPitch's class table + 0x6C = YardsToPixels(f)f.
'   0x005AE59E = _brl_max2d_ImagesCollide2 ; 0x005B9690 = _bbFloatToInt (emitted by Int()).
'   0x00505E20 = the module Function recovered as GetInterceptPoint (333/333 exact, in
'                src/recovered_module/) -- WITHOUT it the two E8 operands here cannot be
'                named on the original side and the whole body sits 2 bytes short of a
'                MATCH. It was recovered, not stubbed.
'
' CODEGEN NOTES (each cost an iteration)
'   * The 16-way dispatch on Self.currentanim is a Select, not an If/ElseIf chain: every
'     `cmp eax,[global] / je` is emitted back to back with all targets past the last
'     compare (guide 10.2). Six Cases are EMPTY and compile to a bare 5-byte `jmp` each.
'   * A plain If on a Float comparison emits the NEGATED setcc plus `jne` to the skip
'     label (`If Self.xvel < 0.0` -> `setae`/`jne`), whereas the same comparison as the
'     first term of an `And` chain emits the straight setcc plus `je` (`setb`/`je`).
'     Both spellings are the same length, so only the opcode distinguishes them.
'   * `Self.y + yo` and `yo + Self.y` differ: the first is `fld [esi+0x50] / fild / faddp`
'     (5 bytes), the second `fild / fadd [esi+0x50]` (3). Ghidra prints the second form
'     for both. Four sites; getting it wrong left the body 8 bytes short.
'   * The BlockTackle branch carries an EMPTY `Else` -- bcc emits the `EB 00` jump-over
'     only when the else-part exists. Without it the body is 2 bytes short.
'   * `rt` is a register-allocated Local Int 250 (edi); Case arr05 uses `rt / 2`, which
'     emits the signed `cdq / and edx,1 / add / sar` div-by-two, not a literal 125.
'     The `g_player_int50 - 250` inside the joystick test is a separate literal.
'   * The joystick test is an `Or` of two `And` groups: the short-circuit `jne` out of the
'     first group is the tell (an `And` chain would emit `je`).
'   * Locals are named by us. Float Locals rad/bs/xs/hs occupy ebp-0x24/-0x0C/-0x18/-0x08
'     and the Int Locals ebp-0x10/-0x14/-0x1C/-0x20; the assignment falls out of bcc and
'     was reproduced without having to be forced.
' Float constants come from .rdata at 0x00C79C24..0x00C79CE8 and were read out of
' NSS5.exe, not guessed (2.0, 1.5, 1.75, 2.25, 0.5, 1.0, 5.0, 0.25, 4.0, 0.75, 1.1, 0.85,
' 0.6, 15.0, 16.0, 17.0, 1.4, 1.35).

	Method CheckBallContact:Int()
		'!Global g_ball:TBall
		'!Global g_player_int01:Int
		'!Global g_player_int50:Int
		'!Global g_player_selected:TPlayer
		'!Global g_player_int04:Int
		' g_player_int15's original data-section value is 2 (read from NSS5.exe at
		' 0x00C5D228, opcode 0xA1 direct-address read -- codegen-patterns 21.1/21.3).
		'!Global g_player_int15:Int = 2
		'!Global g_player_float11:Float
		'!Global g_player_float02:Float
		'!Global g_player_int33:Int
		'!Global g_player_int14:Int
		'!Global g_tr_mode:Int
		'!Global g_ballimg:TImage
		'!Global g_player_arr03:Int[]
		'!Global g_player_arr04:Int[]
		'!Global g_player_arr05:Int[]
		'!Global g_player_arr06:Int[]
		'!Global g_player_arr07:Int[]
		'!Global g_player_arr19:Int[]
		'!Global g_player_arr20:Int[]
		'!Global g_player_arr21:Int[]
		'!Global g_player_arr22:Int[]
		'!Global g_player_arr23:Int[]
		'!Global g_player_arr24:Int[]
		'!Global g_player_arr25:Int[]
		'!Global g_player_arr26:Int[]
		'!Global g_player_arr27:Int[]
		'!Global g_player_arr28:Int[]
		'!Global g_player_arr29:Int[]
		If Not g_ball Then Return 0
		If TEngine.SetPiece()
			If g_ball.setpiecetaker <> Self Then Return 0
			If g_ball.setpiecetaker = Self And g_ball.controlledby <> Self And Self.distancetoball < g_player_float11 * 2.0
				g_ball.NewController(Self)
			EndIf
		Else
			If g_player_int01 = 8
				If g_player_int50 < g_ball.kicktime + 350 And g_ball.lasttouchedby = Self Then Return 0
				If Not g_ball.controlledby And g_player_selected = Self And g_player_int04 = Self.teamid And Self.distancetoball < TPitch.YardsToPixels(1.0) And Self.PlayerCelebrating() = 0
					g_ball.NewController(Self)
					Return 0
				EndIf
				Return 0
			EndIf
			If g_player_int01 <> 1 And g_player_int01 <> 10 Then Return 0
		EndIf
		Local rad:Float = g_player_float11
		If g_player_int15 = 1 And Self.controller = 1
			rad = g_player_float11 * 1.5
		EndIf
		If g_ball <> Null
			If g_ball.lastkickmatchstate <> 4 And g_player_int50 < g_ball.kicktime + 350 And g_ball.lasttouchedby = Self Then Return 0
			Local bs:Float = 2.0
			Local rt:Int = 250
			If Self.GetMyTeam().controller = 0
				Select g_player_int15
					Case 1
						bs = 1.75
					Case 2
						bs = 2.0
					Case 3
						bs = 2.25
				End Select
			EndIf
			If g_ball.controlledby <> Self
				Local xs:Float = g_player_float02
				If Self.KeeperDiving() And Self.xvel < 0.0
					xs = -xs
				ElseIf Self.facing = 0
					xs = -xs
				EndIf
				Select Self.currentanim
					Case g_player_arr03
					Case g_player_arr05
						If g_player_int50 < g_ball.kicktime + rt / 2 And g_ball.passtoid <> Self.id Then Return 0
						Local hs:Float = g_player_float02 * 2.0
						If g_ball.controlledby <> Null And g_tr_mode = 0
							Select g_player_int15
								Case 1
									hs = g_player_float02 * 2.0
								Case 2
									hs = g_player_float02 * 1.5
								Case 3
									hs = g_player_float02
							End Select
						EndIf
						If Self.speed > 0.25 And ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0), 0, 0, hs, hs, Self.imgPlayer, Int(Self.x), Int(Self.y), Self.imageframenumber, Self.spriterotation, xs, g_player_float02) And g_ball.z < g_player_int33 * 0.75
							If Self.CheckOffside() Then Return 0
							Self.SlideBall()
						EndIf
					Case g_player_arr04
						If g_player_int50 < g_ball.kicktime + rt And g_ball.passtoid <> Self.id Then Return 0
						If g_ball.KeeperHolding() Then Return 0
						If Self.distancetoball < rad And g_ball.z <= Self.z + g_player_int33 * 1.1
							If Self.CheckOffside() Then Return 0
							Self.HeadBall()
						EndIf
					Case g_player_arr06
						If g_player_int50 < g_ball.kicktime + rt And g_ball.passtoid <> Self.id Then Return 0
						If g_ball.KeeperHolding() Then Return 0
						If Self.z > 1.0 And ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0 - g_ball.z), 0, 0, g_player_float02 * 2.0, g_player_float02 * 2.0, Self.imgPlayer, Int(Self.x), Int(Self.y - Self.z), Self.imageframenumber, 0, xs, g_player_float02) And g_ball.z < Self.z + g_player_int33 * 0.85
							If Self.CheckOffside() Then Return 0
							Self.DiveHeadBall()
						EndIf
					Case g_player_arr07
					Case g_player_arr19
						If Self.distancetoball < rad * 1.5 And ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0 - g_ball.z), 0, 0, g_player_float02 * bs, g_player_float02 * bs, Self.imgPlayer, Int(Self.x), Int(Self.y - Self.z), Self.imageframenumber, 0, xs, g_player_float02) And g_ball.z < Self.z + g_player_int33
							Self.CheckKeeperSave()
						EndIf
					Case g_player_arr20
					Case g_player_arr21
					Case g_player_arr22
						Local zz:Int = Int(Self.z)
						Select Self.currentanim[Self.frame]
							Case 59
								zz :+ g_player_int33
							Case 60
								zz :+ g_player_int33 + 5
							Case 61
								zz = Int(zz + g_player_int33 * 0.6)
						End Select
						Local yo:Int = 0
						Select Self.GetShootingDirection()
							Case 1
								yo = 6
							Case -1
								yo = -6
						End Select
						Local xl:Int = Int(Self.x - 5.0)
						Local xr:Int = Int(Self.x + 5.0)
						If Self.xvel < 0.0
							Select g_player_int15
								Case 1
									xl = Int(Self.x - 15.0)
								Case 2
									xl = Int(Self.x - 16.0)
									zz :+ 1
								Case 3
									xl = Int(Self.x - 17.0)
									zz :+ 3
							End Select
						Else
							Select g_player_int15
								Case 1
									xr = Int(Self.x + 15.0)
								Case 2
									xr = Int(Self.x + 16.0)
									zz :+ 1
								Case 3
									xr = Int(Self.x + 17.0)
									zz :+ 3
							End Select
						EndIf
						If g_ball.z < zz
							If GetInterceptPoint(xl, Self.y + yo, xr, Self.y + yo, g_ball.oldx, g_ball.oldy, g_ball.x, g_ball.y).intercept
								Self.CheckKeeperSave()
							EndIf
						EndIf
					Case g_player_arr23
						Local zz2:Int = Int(Self.z)
						Select Self.currentanim[Self.frame]
							Case 59
								zz2 :+ g_player_int33
							Case 61
								zz2 = Int(zz2 + g_player_int33 * 0.6)
						End Select
						Local yo2:Int = 0
						Select Self.GetShootingDirection()
							Case 1
								yo2 = 6
							Case -1
								yo2 = -6
						End Select
						Local xl2:Int = Int(Self.x - 5.0)
						Local xr2:Int = Int(Self.x + 5.0)
						If Self.xvel < 0.0
							Select g_player_int15
								Case 1
									xl2 = Int(Self.x - 15.0)
								Case 2
									xl2 = Int(Self.x - 16.0)
									zz2 :+ 1
								Case 3
									xl2 = Int(Self.x - 17.0)
									zz2 :+ 3
							End Select
						Else
							Select g_player_int15
								Case 1
									xr2 = Int(Self.x + 15.0)
								Case 2
									xr2 = Int(Self.x + 16.0)
									zz2 :+ 1
								Case 3
									xr2 = Int(Self.x + 17.0)
									zz2 :+ 3
							End Select
						EndIf
						If g_ball.z < zz2
							If GetInterceptPoint(xl2, Self.y + yo2, xr2, Self.y + yo2, g_ball.oldx, g_ball.oldy, g_ball.x, g_ball.y).intercept
								Self.CheckKeeperSave()
							EndIf
						EndIf
					Case g_player_arr24
						If Self.distancetoball < rad * 1.5
							If ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0 - g_ball.z), 0, 0, g_player_float02 * bs, g_player_float02 * bs, Self.imgPlayer, Int(Self.x), Int(Self.y - Self.z), Self.imageframenumber, 0, xs, g_player_float02) And g_ball.z < Self.z + g_player_int33 * 1.4
								Self.CheckKeeperSave()
							EndIf
						EndIf
					Case g_player_arr25
					Case g_player_arr26
						If Self.distancetoball < rad * 1.5
							If ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0 - g_ball.z), 0, 0, g_player_float02 * bs, g_player_float02 * bs, Self.imgPlayer, Int(Self.x), Int(Self.y - Self.z), Self.imageframenumber, 0, xs, g_player_float02) And g_ball.z < Self.z + g_player_int33 * 1.35
								Self.CheckKeeperSave()
							EndIf
						EndIf
					Case g_player_arr27
					Case g_player_arr28
						If Self.distancetoball < rad * 1.5
							If ImagesCollide2(g_ballimg, Int(g_ball.x), Int(g_ball.y + 4.0 - g_ball.z), 0, 0, g_player_float02 * 2.0, g_player_float02 * 2.0, Self.imgPlayer, Int(Self.x), Int(Self.y - Self.z), Self.imageframenumber, 0, xs, g_player_float02) And g_ball.z < Self.z + g_player_int33
								Self.CheckKeeperSave()
							EndIf
						EndIf
					Case g_player_arr29
					Default
						If g_player_int50 < g_ball.kicktime + rt And g_ball.passtoid <> Self.id Then Return 0
						If Self.distancetoball < rad And g_ball.z < Self.z + g_player_int33
							If Self.CheckOffside() Then Return 0
							If Self.selectionno = 0
								Self.CheckKeeperSave()
							ElseIf g_ball.controlledby <> Null
								If g_ball.teaminpossession <> Self.teamid
									Self.BlockTackle()
								Else
								EndIf
							Else
								If g_ball.z > g_player_int33 * 0.5 And g_ball.z < g_player_int33 * 1.0 And g_ball.velocity > 5.0
									g_ball.Deflect(Self)
								Else
									If (Self.joy.kickbuttonhits > g_player_int50 - 250 And Self.joy.kickbuttondown = 0) Or (g_player_int14 = 1 And Self.joy.kickbuttondown And Self.joy.activebutton <> 3)
										Self.TapKick()
										Return 0
									Else
										g_ball.NewController(Self)
									EndIf
								EndIf
							EndIf
						EndIf
				End Select
			EndIf
		EndIf
	End Method

' TRouletteBall.Update
' VA 0x00575F50   772 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (:TRouletteWheel)i, slot 0x38
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C6BBCC g_roulette_sndland:TSound   0x00C6BBD0 g_roulette_sndhit:TSound
'        (names and types taken from the already-verified TRoulette.SetUp)
'      0x00C6BE60 g_roulette_chan_spin:TChannel -- globals_final says untyped Object.
'        The call on it is `call [eax+0x30]` with no arguments; TChannel slot 0x30 is
'        Stop(), which is both the right shape and the right meaning (the spin sound is
'        stopped when the ball drops into a pocket). The emitted bytes (FF 50 30) do not
'        depend on the choice, so this is an interpretation, not a proof.
'      0x00C6F090 g_chan_bet:TChannel         0x00C6BE5C g_rouletteball_int:Int
'  * 38.0 / 9.473 / 0.15 live at 0x00C6BBB4 / 0x00C6BBB8 / 0x00C6BE50 -- Float constant
'    pool entries interleaved with this module's Globals, not Globals themselves (the
'    values are baked into the image).
'  * The two closing statements are `Cos(...) * Self.fDist`, NOT `Self.fDist * Cos(...)`.
'    With the field on the left bcc must spill it across the Cos/Sin call and the body
'    comes out 792 bytes; with the call on the left the product operand is loaded fresh
'    after the call (`fld dword [esi+0x10] / fmulp`) and the body is exact.
'  * `moved` is register-allocated (ebx). The two `Int(Self.fPocket)` spills of the left
'    operand are compiler-generated, not source Locals.

'!Global g_roulette_sndland:TSound
'!Global g_roulette_sndhit:TSound
'!Global g_roulette_chan_spin:TChannel
'!Global g_chan_bet:TChannel
'!Global g_rouletteball_int:Int

Method Update:Int(a0:TRouletteWheel)
	SetRotation(0)
	Self.oldfX = Self.fX
	Self.oldfY = Self.fY
	Self.fLineRot = Self.fLineRot + Self.fSpeed
	If Self.fLineRot > 360.0
		Self.fLineRot = Self.fLineRot - 360.0
	End If
	If Self.fLineRot < 1.0
		Self.fLineRot = Self.fLineRot + 360.0
	End If
	Self.fPocket = Self.fLineRot / 9.473 - a0.fRot / 9.473
	If Self.fPocket < 0.0
		Self.fPocket = Self.fPocket + 38.0
	End If
	If a0.fSpeed < 2.0
		Self.fVel = Self.fVel - 0.15
		Self.fDist = Self.fDist + Self.fVel
		If Self.fDist <= a0.iWheelSize / 2
			If g_roulette_chan_spin <> Null
				g_roulette_chan_spin.Stop()
			End If
			If g_rouletteball_int = 0
				PlaySound(g_roulette_sndhit, g_chan_bet)
			End If
			Self.fDist = a0.iWheelSize / 2
			Self.fVel = -(Self.fVel * 0.7)
			If Self.fVel > -0.5 And Self.fVel < 0.5
				If g_rouletteball_int = 0
					PlaySound(g_roulette_sndland, g_chan_bet)
					g_rouletteball_int = 1
				End If
				Self.fSpeed = a0.fSpeed
				Local moved:Int = 0
				If Self.fPocket > Int(Self.fPocket) + 0.62
					Self.fLineRot = Self.fLineRot - 0.3
					moved = 1
				End If
				If Self.fPocket < Int(Self.fPocket) + 0.58
					Self.fLineRot = Self.fLineRot + 0.3
					moved = 1
				End If
				If moved = 0 Then Self.bStopped = 1
			Else
				Self.fSpeed = Rnd(-1.0 - a0.fSpeed * 2.0, 1.0 + a0.fSpeed)
			End If
		End If
	End If
	Self.fX = a0.fX + Cos(Self.fLineRot) * Self.fDist
	Self.fY = a0.fY + Sin(Self.fLineRot) * Self.fDist
End Method

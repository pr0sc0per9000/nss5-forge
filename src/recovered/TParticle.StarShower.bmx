' TParticle.StarShower
' VA 0x0056F7E3   497 bytes  mode=reloc  byte-identical vs NSS5.exe (497/497)
' KIND=Function, SIG (i,i,$,$)i, slot 0x38
' ASSUMPTIONS
'   0x00C5D250 is an Int Global (bare cmp dword ,0) -- named g_particles_on here.
'   0x00C6AD88 is a TSound and 0x00C6F090 a TChannel: they are the two arguments of
'     _brl_audio_PlaySound (0x0059B25E), whose signature fixes both types.
'   The eight qword operands at 0x00C8F500..0x00C8F538 are bcc-emitted Double literals,
'     not Globals: 360.0, 5.0, 5.0, 360.0, 0.1, 0.05, 2.5, 1.5.
'   Rnd's second parameter defaults to 0, which is why Rnd(360) emits a bare fldz.
'   The guard is an early return (cmp/jne + mov eax,0 / jmp epilogue), not an If block.
'   The 4th parameter (a3:String) is never referenced by the original.
	Function StarShower:Int(a0:Int, a1:Int, a2:String, a3:String)
		'!Global g_particles_on:Int
		'!Global g_snd_star:TSound
		'!Global g_chan_star:TChannel
		If g_particles_on = 0 Then Return 0
		CreateParticle(a0, a1, 0, 0.5, 0.6, 0.5, 0, 0, 1.0, "FFFFFF", "")
		For Local i:Int = 1 To 30
			Local ang:Float = Rnd(360)
			Local px:Float = a0 + Cos(ang) * 5.0
			Local py:Float = a1 + Sin(ang) * 5.0
			CreateParticle(px, py, ang, Rnd(1.5, 2.5), Rnd(0.05, 0.1), 0.5, Rnd(360), 0, 0, "FFFF00", "")
		Next
		CreateParticle(a0, a1, 0, 0, 0.3, 3.0, 0, 0, 1.0, "FFFFFF", a2)
		PlaySound(g_snd_star, g_chan_star)
	End Function

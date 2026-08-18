' TParticle.UpdateParticlesAll
' VA 0x0056fa67   93 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' assumes module global at 0x00C6AD80 typed TList; the downcast class table
' 0x00C6AF88 is TParticle + 0x00, so the loop variable is TParticle.
	Function UpdateParticlesAll:Int()
		'!Global g_particles:TList
		For Local p:TParticle = EachIn g_particles
			p.Update()
		Next
	End Function

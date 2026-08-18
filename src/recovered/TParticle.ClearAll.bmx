' TParticle.ClearAll
' VA 0x0056f72c   28 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6ad80 declared TList (the particle list); the call is
' slot 0x34 through it, which is TList.Clear. harness mode=reloc, 1 address masked.
	Function ClearAll:Int()
		'!Global g_particles:TList
		g_particles.Clear()
	End Function

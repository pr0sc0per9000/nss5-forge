' TParticle.Count
' VA 0x0056fd07   23 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (23/23, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6ad80 declared :TList (name ours; type is load-bearing --
' it selects slot 0x70 = TList.Count)
	Function Count()
		'!Global g_particles:TList
		Return g_particles.Count()
	End Function

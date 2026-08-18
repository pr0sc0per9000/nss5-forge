' TParticle.New
' VA 0x0056F683   116 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' the field-zeroing prologue in the decompilation is bcc-generated for every New; only the AddLast is user source
' ASSUMPTION: Global 0x00c6ad80 declared :TList (slot 0x44 = TList.AddLast)
	Method New:Int()
		'!Global g_particles:TList
		g_particles.AddLast(Self)
	End Method

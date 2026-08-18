' TParticle.RenderParticlesAll
' VA 0x0056fbad   129 bytes   vtable slot 0x48   sig (f,f,f)i
' byte-identical vs NSS5.exe (129/129, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6AD80 declared TList (ObjectEnumerator at slot 0x8c confirms).
'   Loop downcast class table is TParticle; slot 0x4c = TParticle.Render(f,f,f).
'   FUN_00506456 = recovered module Function SetDrawStateHex($,f,f,f,i).
	Function RenderParticlesAll:Int(a0:Float,a1:Float,a2:Float)
		'!Global g_particles:TList
		For Local p:TParticle = EachIn g_particles
			p.Render(a0,a1,a2)
		Next
		SetDrawStateHex("FFFFFF",1.0,1.0,0,3)
	End Function

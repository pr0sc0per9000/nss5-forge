' TParticle.Update
' VA 0x0056FAC4   233 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (233/233, original length from Ghidra's inventory, mode=reloc)
' assumptions: Global 0x00C6AD80 declared TList (type_source=verified in globals_final.tsv);
' slot 0x74 on it is TList.Remove(:Object). The .rdata float constants were read out of
' NSS5.exe: 0x00C8F540=20.0, 0x00C8F544=0.96, 0x00C8F548=1.015, 0x00C8F54C=0.955,
' 0x00C8F550=0.01. FUN_004A1F10 / FUN_004A1F00 are _bbCos / _bbSin per runtime_helpers.tsv.
'
' OPERAND ORDER IS LOAD-BEARING. Cos(dir)*vel, not vel*Cos(dir): the original computes the
' call first and only then loads [ebx+0x14]. Written the other way bcc spills both operands
' around the call and each of the two statements comes out 8 bytes longer (251 vs 233).
' Same reason for Self.rot + Self.vel * 20.0 -- rot is fld'ed before the multiply.
	Method Update:Int()
		'!Global g_particles:TList
		If Self.dir <> 0.0
			Self.x = Self.x + Cos(Self.dir) * Self.vel
			Self.y = Self.y + Sin(Self.dir) * Self.vel
		EndIf
		Self.y = Self.y + Self.grav
		Self.rot = Self.rot + Self.vel * 20.0
		Self.vel = Self.vel * 0.96
		Self.scale = Self.scale * 1.015
		Self.alph = Self.alph * 0.955
		If Self.alph < 0.01
			g_particles.Remove(Self)
		EndIf
	End Method

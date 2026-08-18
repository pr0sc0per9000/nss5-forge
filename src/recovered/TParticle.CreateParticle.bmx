' TParticle.CreateParticle
' VA 0x0056F9D4   147 bytes   vtable slot 0x3c   sig (f,f,f,f,f,f,f,f,f,$,$)i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' The created particle is not stored anywhere by the original; the function returns 0 (no explicit Return).
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Function CreateParticle:Int(a0:Float, a1:Float, a2:Float, a3:Float, a4:Float, a5:Float, a6:Float, a7:Float, a8:Float, a9:String, a10:String)
		Local p:TParticle = New TParticle
		p.x = a0
		p.y = a1
		p.dir = a2
		p.vel = a3
		p.scale = a4
		p.alph = a5
		p.rot = a6
		p.grav = a7
		p.inflate = a8
		p.colour = a9
		p.txt = a10
	End Function

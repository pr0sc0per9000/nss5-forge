' TParticle.Render
' VA 0x0056FC2E   217 bytes   vtable slot 0x4c   sig (f,f,f)i
' byte-identical vs NSS5.exe (217/217, original length from Ghidra's inventory)
' assumptions: Global 0x00C6AD84 declared TImage; 0x00C5BB34 resolves to
' TEngine class table + 0x104 = TEngine.DrawMyText($,f,f,i,i,f,f,$,i)i;
' 0x00505CEA is the recovered module Function SetColourHex.
' a0*Self.scale is written out twice on purpose -- the original has no Local there.
	Method Render:Int(a0:Float, a1:Float, a2:Float)
		'!Global g_particleimage:TImage
		If Self.txt.length <> 0
			TEngine.DrawMyText(Self.txt, Self.x * a0 - a1, Self.y * a0 - a2, 1, 1, a0 * Self.scale, Self.alph, Self.colour, 0)
		Else
			SetBlend(4)
			SetScale(a0 * Self.scale, a0 * Self.scale)
			SetAlpha(Self.alph)
			SetColourHex(Self.colour)
			SetRotation(Self.rot)
			DrawImage(g_particleimage, Self.x * a0 - a1, Self.y * a0 - a2, 0)
		EndIf
	End Method

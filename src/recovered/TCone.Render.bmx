' TCone.Render
' VA 0x00583254   249 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (249/249, original length from Ghidra's inventory)
' assumptions: 0x00C5B1B4 resolves to TDrawOb class table + 0x34 =
' AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i; Global 0x00C5DE44 declared Float
' (globals_final: x87 dword access, high confidence). Float constants 0.0/24.0/0.3/0.5/1.5
' and the string literals "000000" / "FFFFFF" / "" read from the image.
	Method Render:Int()
		'!Global g_drawscale:Float
		Local rot:Float = 0.0
		If Self.fallen <> 0 Then rot = Self.fallen
		If Self.alive <> 0
			TDrawOb.AddDrawOb(Self.img, Self.x + 1.5, Self.y - 0.5, 0, Self.frame, 2, Self.alph * 0.3, Int(rot + 24.0), "000000", g_drawscale, g_drawscale, 3, 0, "", 0, 0)
		EndIf
		TDrawOb.AddDrawOb(Self.img, Self.x, Self.y, 0, Self.frame, 3, Self.alph, Int(rot), "FFFFFF", g_drawscale, g_drawscale, 3, 0, "", 0, 0)
	End Method

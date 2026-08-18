' TCone.Create
' VA 0x00582ee4   241 bytes
' byte-identical vs NSS5.exe (241/241, original length from Ghidra's inventory, mode=reloc, 18 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function (i,i,i)i, vtable slot 0x48.
' ASSUMPTIONS: the two string literals are relocatable data addresses and are MASKED --
' their VALUES are not proven, only that a String constant sits in each position.
' Globals 0x00C6D6C0 (TImage) and 0x00C6D6C4 (TSound) named by us.
'!Global g_coneimg:TImage
'!Global g_conesnd:TSound
If Not g_coneimg
	g_coneimg = LoadAnimImageChecked("EngineMedia/Match/Pitch/Cones.png", 48, 48, 0, 3, -1)
	SetImageHandle(g_coneimg, 24.0, 32.0)
	g_conesnd = LoadSoundChecked("EngineMedia/Match/Sounds/ConeHit.ogg", 0)
End If
Local c:TCone = New TCone
c.img = g_coneimg
c.frame = a2
c.x = a0
c.y = a1

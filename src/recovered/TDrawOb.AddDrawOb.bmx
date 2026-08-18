' TDrawOb.AddDrawOb
' VA 0x004CD483   210 bytes   vtable slot 0x34   sig (:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i
' byte-identical vs NSS5.exe (210/210, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical

	Function AddDrawOb:Int(a0:TImage, a1:Float, a2:Float, a3:Float, a4:Int, a5:Int, a6:Float, a7:Int, a8:String, a9:Float, a10:Float, a11:Int, a12:Float, a13:String, a14:Int, a15:Int)
		Local d:TDrawOb = New TDrawOb
		d.x = a1
		d.y = a2
		d.z = a3
		d.z2 = a12
		d.img = a0
		d.frame = a4
		d.level = a5
		d.alph = a6
		d.rot = a7
		d.col = a8
		d.sclx = a9
		d.scly = a10
		d.blend = a11
		d.txt = a13
		d.imgrectw = a14
		d.imgrecth = a15
	End Function

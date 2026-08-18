' TPhotographer.Create
' VA 0x004EA638   74 bytes   vtable slot 0x34   sig (f,f,i,i)i
' byte-identical vs NSS5.exe (74/74, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' FUN_0059f089 = _brl_random_Rand.

	Function Create:Int(a0:Float,a1:Float,a2:Int,a3:Int)
		Local p:TPhotographer = New TPhotographer
		p.x=a0
		p.y=a1
		p.facing=a2
		p.pose=a3
		p.flashmod=Rand(20,60)
	End Function

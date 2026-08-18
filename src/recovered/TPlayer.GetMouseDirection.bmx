' TPlayer.GetMouseDirection
' VA 0x004FBD0B   130 bytes   vtable slot 0x18C   sig ()i
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C5B1D8 Float (camera x), 0x00C5B1DC Float (camera y),
' 0x00C5B1D4 Float (zoom). AngleTo is the recovered module Function at 0x0050639D;
' 0x005B47DF/0x005B47FE are _brl_polledinput_MouseX/MouseY; 0x005B9690 is _bbFloatToInt,
' i.e. the Int() around the result.
' The three Float Locals are load-bearing: the original opens `sub esp,0x10` and copies each
' Global into its own slot BEFORE the MouseX/MouseY calls. Inlining the Globals into the
' expression is only 115 bytes.
' g_engine_zoom's original data-section value is 2.0 (0x00C5B1D4), read directly
' from NSS5.exe -- see codegen-patterns 21.1/21.3.
	Method GetMouseDirection:Int()
		'!Global g_engine_camx:Float
		'!Global g_engine_camy:Float
		'!Global g_engine_zoom:Float = 2.0
		Local camx:Float = g_engine_camx
		Local camy:Float = g_engine_camy
		Local zoom:Float = g_engine_zoom
		Return Int(AngleTo(Self.x * zoom - camx, Self.y * zoom - camy, MouseX(), MouseY()))
	End Method

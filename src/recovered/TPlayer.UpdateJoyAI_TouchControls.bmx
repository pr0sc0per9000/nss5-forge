' TPlayer.UpdateJoyAI_TouchControls
' VA 0x004F1B5B   429 bytes   vtable slot 0x8c   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (429/429, original length from Ghidra's inventory, mode=reloc)
' 0x005B4965 is the alias set KeyDown|MouseDown and 0x005B4932 is MouseHit (inferred table);
' MouseDown / MouseHit are the members that fit a touch-control path.
' TEngine.SetPiece is reached through TEngine's class table + 0x74.
' 0x00C6EFD4 g_kickHits:Int -- that globals row is type_source='verified'.
' Operand order is load-bearing: Cos(direction) * force, not force * Cos(direction).
' Dist2D(...) is evaluated and spilled BEFORE YardsToPixels, so it is the LEFT operand of
' the comparison even though Ghidra prints the test reversed.
	Method UpdateJoyAI_TouchControls()
		'!Global g_kickHits:Int
		If MouseDown(2) Or TEngine.SetPiece()
			Self.joy.direction = Self.GetMouseDirection()
			Self.joy.force = 1.0
		Else
			Self.joy.direction = AngleTo(Self.x, Self.y, Self.desx, Self.desy)
			Self.joy.force = 0.0
			If Dist2D(Self.x, Self.y, Self.desx, Self.desy) > TPitch.YardsToPixels(1.0)
				Self.joy.force = 1.0
			End If
		End If
		Self.joy.axis_x = Cos(Self.joy.direction) * Self.joy.force
		Self.joy.axis_y = Sin(Self.joy.direction) * Self.joy.force
		If Self.joy.kickenabled <> 0
			If MouseHit(1) <> 0
				Self.joy.kickbuttonhits = g_kickHits
			End If
			If MouseDown(1) <> 0
				Self.joy.kickbuttondown = 1
			Else
				Self.joy.kickbuttondown = 0
			End If
		Else
			Self.joy.kickbuttonhits = 0
			Self.joy.kickbuttondown = 0
			If MouseDown(1) = 0
				Self.joy.kickenabled = 1
			End If
		End If
	End Method

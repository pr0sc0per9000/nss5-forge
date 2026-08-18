' TBall.HitNet
' VA 0x004CAE6E   184 bytes   vtable slot 0x80   sig (i)i
' byte-identical vs NSS5.exe (184/184, original length from Ghidra's inventory, mode=reloc)
' assumptions: 0x00505B91 is the recovered module Function LogLine (entry trace, literal is
' the method's own name); 0x0059F048 is _brl_random_Rnd and its two Double operands were read
' out of .rdata at 0x00C72830 = 0.07 and 0x00C72838 = 0.03; 0x004A1F00/0x004A1F10 are
' _bbSin/_bbCos; 0x004A1F90 is _bbATan2.
' Branch sense is load-bearing: the original is `cmp ebx,0 / je`, so the a0<>0 arm (negating
' the cosine term) is the Then-block. Writing `If a0 = 0` first inverts it and diverges at
' byte 131.
	Method HitNet:Int(a0:Int)
		LogLine("HitNet")
		Self.x = Self.oldx
		Self.y = Self.oldy
		Self.velocity = Self.velocity * Rnd(0.03, 0.07)
		Local c:Float = Cos(Self.direction)
		Local s:Float = Sin(Self.direction)
		If a0 <> 0
			c = -c
		Else
			s = -s
		EndIf
		Self.direction = ATan2(s, c)
	End Method

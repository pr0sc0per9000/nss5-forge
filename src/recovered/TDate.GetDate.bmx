' TDate.GetDate
' VA 0x005369ca   225 bytes   vtable slot 0x44   sig (*i,*i,*i)i
' byte-identical vs NSS5.exe (225/225, original length from Ghidra's inventory)
' mode=exact. Register allocation is load-bearing: 'Local d = Self.gDate' then 'd :+ 32044' (one statement is 1 byte short), and a separate 'Local e = d' before the third stage (the original's 'mov esi,ecx').
	Method GetDate:Int(a0:Int Var, a1:Int Var, a2:Int Var)
		Local d:Int = Self.gDate
		d :+ 32044
		Local a:Int = (d * 4 + 3) / 146097
		d = d - (a * 146097) / 4
		Local b:Int = (d * 4 + 3) / 1461
		d = d - (b * 1461) / 4
		Local e:Int = d
		Local c:Int = (e * 5 + 2) / 153
		a0[0] = e - (c * 153 + 2) / 5 + 1
		a1[0] = c + 3 - (c / 10) * 12
		a2[0] = a * 100 + b - 4800 + c / 10
	End Method

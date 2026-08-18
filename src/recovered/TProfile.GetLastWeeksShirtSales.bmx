' TProfile.GetLastWeeksShirtSales
' VA 0x0056AF34   100 bytes   vtable slot 0xd4   sig ()i
' byte-identical vs NSS5.exe (100/100, original length from Ghidra's inventory)
' assumptions: 0x00505F90 is the already-recovered module Function ClampFloat
' (src/recovered_module/ClampFloat.bmx); the original almost certainly declared its
' first parameter Var, which compiles identically to Float Ptr + Varptr at the call site.
' 0x00C8EBD0 / 0x00C8EBD4 are the Float literals 0.7 and 0.01 in the constant pool.
' The x87 order requires (f * 0.01) to be the LEFT operand of the final multiply.
	Method GetLastWeeksShirtSales:Int()
		Local f:Float = Float(myclub.strength) * 0.7
		ClampFloat(Varptr f,20.0,70.0)
		Return Int(f * 0.01 * Float(lastweeksshirtsales))
	End Method

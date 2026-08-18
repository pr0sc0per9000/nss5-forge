' TMyDate.SetDateByTraditionalDate
' VA 0x00537435   102 bytes   vtable slot 0x48   sig (i,i,i)i
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' CONSTANT CORRECTED: the Float constant at 0x00C84FE4 was written 30.3333
'   (a plausible guess, = 364/12) because its ADDRESS is reloc-masked and so was unpinned
'   by the byte match. scripts/check_floats.py reads the exe's actual value: 30.36
'   (code offset +57). Re-verified MATCH 102/102.
' operand order inside Int(...) is load-bearing: sdate must be pushed on the x87 stack first.

	Method SetDateByTraditionalDate:Int(a0:Int, a1:Int, a2:Int)
		If a2 > 2000 Then a2 = a2 - 2001
		sdate = a0
		sdate = Int(sdate + (a1 - 1) * 30.36)
		sdate = sdate + a2 * 364
	End Method

' TDate.SetDateStr
' VA 0x00536946   94 bytes   vtable slot 0x38   sig ($)i
' byte-identical vs NSS5.exe (94/94, original length from Ghidra's inventory)
' NOTE: parameter names are harness placeholders (a0, a1, ...); the
'       original source names are not recoverable from the binary.
' Shape is load-bearing: the three Int() conversions land in explicit Locals
' (edi / [ebp-4] / eax, sub esp,4 = one spill slot) and are then pushed
' right-to-left.  Inlining them into the SetDate call evaluates right-to-left
' with no temporaries and comes out 80 bytes instead of 94.
' The trailing "Return" is real -- there is no `mov eax,0` in the original, so
' SetDate's own result is returned.
	Method SetDateStr:Int(a0:String)
		Local d:String[] = SplitString(a0, "/")
		Local dd:Int = Int(d[0])
		Local mm:Int = Int(d[1])
		Local yy:Int = Int(d[2])
		Return Self.SetDate(dd, mm, yy)
	End Method

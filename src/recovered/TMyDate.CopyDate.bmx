' TMyDate.CopyDate
' VA 0x0053738e   33 bytes   vtable slot 0x34   sig (:TMyDate):TMyDate
' byte-identical vs NSS5.exe (33/33, original length from Ghidra's inventory)
' Parameter name is not recoverable from the binary; emitted as a0 exactly as the
' harness compiles it. TMyDate.sdate @0x8.
	Function CopyDate:TMyDate(a0:TMyDate)
		Local d:TMyDate = New TMyDate
		d.sdate = a0.sdate
		Return d
	End Function

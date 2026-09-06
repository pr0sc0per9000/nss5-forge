' TZipFileList.Create -- VA 0x0058E974, 143 bytes   vtable slot 0x30   sig (:TStream,i,i):TZipFileList
' byte-identical vs NSS5.exe (143/143, mode=reloc, 7 absolute-address slots masked)
' Both tests are written with Not, and that is load-bearing, not stylistic. `If a0 = Null`
' fuses the comparison into the branch (one jne, no flag materialisation); the original
' materialises the truth value first -- cmp/setne/movzx/cmp/jne at 0x0058E980, nine bytes
' more -- which is what bcc emits for `Not` on an object, inverting the branch instead of
' the value. The same shape decides the second test, where the Not also puts the
' o = Null arm in front of the Sort arm.
' Slot 0x40 on TZipFileList is ScanCentralHeader; TList slot 0x88 is Sort, called with its
' two defaults (ascending = 1 and brl.linkedlist's own comparator at 0x005B3516).
' Parameter names are not recoverable from the binary and do not affect codegen.
	Function Create:TZipFileList(a0:TStream, a1:Int, a2:Int)
		If Not a0 Then Return Null
		Local o:TZipFileList = New TZipFileList
		o.zipFile = a0
		o.IgnoreCase = a1
		o.IgnorePaths = a2
		If Not o.ScanCentralHeader()
			o = Null
		Else
			o.FileList.Sort()
		EndIf
		Return o
	End Function

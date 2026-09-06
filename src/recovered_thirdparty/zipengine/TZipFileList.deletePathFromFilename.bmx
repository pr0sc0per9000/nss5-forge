' TZipFileList.deletePathFromFilename -- VA 0x0058EDD1, 54 bytes   vtable slot 0x48   sig (*$)i
' byte-identical vs NSS5.exe (54/54, mode=reloc, 2 absolute-address slots masked)
' One call, on the Var String parameter: 0x005B5578 is _brl_filesystem_StripDir
' (extracted/brl_functions.tsv). The retain/release pair around the store is the ordinary
' String assignment sequence for a Var parameter, not source-level code.
' Parameter names are not recoverable from the binary and do not affect codegen.
Method deletePathFromFilename:Int(a0:String Var)
	a0 = StripDir(a0)
End Method

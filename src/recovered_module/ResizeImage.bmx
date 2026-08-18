' ResizeImage  -- module-level Function (no Type)
' VA 0x005064a2   75 bytes   sig (:TImage,i,i):TImage
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Module-level Functions carry no BBDebugScope record, so the original
' name is unrecoverable -- exactly like module Globals. Names have no effect on codegen.
' Identified by its callers: 4 game call sites use 0x005064A2 (TOptions.SetUp twice,
' FUN_004BD649 once, TScreen_Options.RefreshButtons once), all with 3 arguments.
' Rescales a TImage by round-tripping through a TPixmap:
'   LockImage (0x005AE43C) -> ResizePixmap (0x005B256F) -> UnlockImage (0x005AE45F)
'   -> LoadImage (0x005AE256), all named in extracted/brl_functions.tsv.
' LockImage's frame/read/write defaults are emitted by bcc at the call site, which is
' why the original pushes 1,1,0 for a bare LockImage(a0) -- no explicit arguments needed.
	Function ResizeImage:TImage(a0:TImage, a1:Int, a2:Int)
		Local px:TPixmap = LockImage(a0)
		px = ResizePixmap(px, a1, a2)
		UnlockImage(a0)
		Return LoadImage(px, -1)
	End Function

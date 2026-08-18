' StartMusic  -- module-level Function (no Type)
' VA 0x004bc874   24 bytes   sig ()i
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=1, verified with NSS5_NO_LEARN=1 -- codegen-patterns 13.1)
'
' NAME IS OURS. Called once from GameMain (docs/game/engine/main-loop.md, step 5, boot
' order) right after SetUpGraphics, before TScreen.SetUp -- starts the menu music. Trivial
' one-statement wrapper: pushes the literal 1 (track number) and calls PlayTrack, which is
' already verified in this directory (PlayTrack.bmx). Return value is unused/always 0.
	Function StartMusic:Int()
		PlayTrack(1)
	End Function

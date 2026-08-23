' SetClipboardText  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058d78d   141 bytes   sig ($)i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=12), verified with harness.try_function under NSS5_NO_LEARN=1.
'
' The write half of the clipboard pair whose read half, GetClipboardText (0x0058D81A), was
' recovered earlier today. It sits 141 bytes before it in the image.
'
' NOT CALLED FROM ANYWHERE in the shipped exe. Verified by a brute scan of every E8/E9
' rel32 in the code sections, not just extracted/callgraph_resolved.tsv: zero call sites.
' TInputBox.Update handles Ctrl+V through GetClipboardText, but nothing in the game ever
' copies OUT -- the Ctrl+C half was written and never wired up. Found by the
' unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
'
' TWO BUGS, both preserved:
'   * The CString from a0.ToCString() is never freed. GetClipboardText's mirror image
'     frees nothing either, but there the buffer belongs to the clipboard; here it is a
'     bbMemAlloc block and it leaks, once per copy.
'   * GlobalFree(h) is called at 0x0058D806, AFTER SetClipboardData has handed ownership of
'     the handle to the clipboard. Freeing it there is a double-free from the clipboard's
'     point of view; MSDN is explicit that the handle must not be touched afterwards. That
'     may well be why the feature was never wired up.
'
' HELPER SYMBOLS. Five of the twelve relocation sites had no entry in the helper table and
' therefore could not mask. They were measured, not guessed: the probe was built with
' keep=True and helper_map.code_relocations() read straight off the resulting object file,
' which names each DISP32 site. The five were then recorded with helper_map.record(), no
' conflicts:
'     0x004a8df0 _bbMemCopy          (a `jmp 0x004B44F8` thunk onto memcpy; 0x004A8E00,
'                                     the alloc-and-copy helper, calls bbMemAlloc then it)
'     0x004a9bd8 _GlobalAlloc@8      \
'     0x004a9be0 _GlobalFree@4        |  identity from extracted/dll_imports.tsv (the PE
'     0x004b47e8 _EmptyClipboard@0    |  import directory); the @N stdcall decoration is
'     0x004b4808 _SetClipboardData@8 /   this toolchain's, exactly as GetClipboardText.bmx
'                                        measured for OpenClipboard and friends.
' Blast radius: all four Win32 thunks have EXACTLY ONE caller in the whole exe, this
' function, so no other body's verdict can move. bbMemCopy's other callers are all BRL
' module code with no body under src/.
'
' THE RAW EXTERN BLOCK BELOW IS DELIBERATELY DISJOINT FROM GetClipboardText'S, AND ITS
' BRACKET LINES DELIBERATELY CARRY A TRAILING COMMENT. Both details were forced by
' measurement and neither is cosmetic:
'
'  * DISJOINT. assemble.py concatenates every module Function's '!Raw lines VERBATIM into
'    src/assembled/nss5_assembled.bmx, with no deduplication. Declaring OpenClipboard here
'    as well as in Fn_0058D81A.GetClipboardText.bmx fails the whole build outright with
'    "Compile Error: Duplicate identifier 'OpenClipboard'". So this file declares only the
'    four Win32 functions that file does not, and takes OpenClipboard, CloseClipboard,
'    GlobalLock and GlobalUnlock from its block. The coupling is real: if
'    Fn_0058D81A.GetClipboardText.bmx is ever removed or added to harness.MODULE_SKIP,
'    this body stops compiling and the four declarations have to move here.
'
'  * TRAILING COMMENT ON `Extern` AND `End Extern`. harness.merge_globals does the
'    opposite of assemble.py -- it deduplicates '!Raw lines by their exact stripped,
'    lowercased text. With both files spelling the bracket lines identically the two
'    `Extern "Win32"` lines collapse into one and so do the two `End Extern` lines, and
'    whichever file sorts second in os.listdir order has its declarations emitted AFTER
'    that single `End Extern` -- at module scope, where a bodyless `Function` is a compile
'    error that breaks EVERY probe in the project, not just these two. The trailing
'    comment makes this block's brackets distinct text, so the merge keeps two properly
'    closed Extern blocks whatever order the files sort in. A BlitzMax comment after a
'    statement is legal and emits nothing.
'!Raw Extern "Win32" ' SetClipboardText's own block, kept disjoint -- see header
'!Raw Function EmptyClipboard()
'!Raw Function SetClipboardData(fmt:Int, hmem:Int)
'!Raw Function GlobalAlloc(flags:Int, bytes:Int)
'!Raw Function GlobalFree(h:Int)
'!Raw End Extern ' SetClipboardText's own block
	Function SetClipboardText:Int(a0:String)
		If a0 = "" Then Return 0
		If OpenClipboard(0)
			Local h:Int = GlobalAlloc(2, a0.length + 1)
			Local p:Byte Ptr = GlobalLock(h)
			MemCopy(p, a0.ToCString(), a0.length + 1)
			GlobalUnlock(h)
			EmptyClipboard()
			SetClipboardData(1, h)
			CloseClipboard()
			GlobalFree(h)
		EndIf
	End Function

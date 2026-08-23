' Fn_0058D81A.GetClipboardText -- module-level Function (no Type). NAME IS OURS: no
' reflection record for a module Function (5.7/law -- names have no effect on codegen).
' VA 0x0058D81A   83 bytes (Ghidra inventory)   sig $()
' byte-identical vs NSS5.exe (83/83, mode=reloc, reloc_masked=8), verified with
' harness.try_function under NSS5_NO_LEARN=1.
'
' Unattributed "code" function -- absent from vtable_map.tsv, from
' extracted/brl_functions*.tsv and from every tree under src/ before this file, exactly
' as recorded in the BLOCKER section of src/recovered_unverified/TInputBox.Update.bmx,
' whose own "Ctrl+V" statement is the only caller (`SetText(GetClipboardText(), "", -1,
' -1)`, at VA 0x0058D84D). That header already carries this function's disassembly and
' the name GetClipboardText; this file is the independently byte-verified body 13.3
' requires before a caller's E8 to it can mask.
'
' Own disassembly (harness.disasm_original 0x0058D81A 83, re-read fresh rather than
' trusting the transcription in TInputBox.Update.bmx's header, per this task's own
' instruction):
'     0058D81A  55                    push ebp
'     0058D81B  89 E5                 mov ebp, esp
'     0058D81D  53                    push ebx
'     0058D81E  56                    push esi
'     0058D81F  57                    push edi
'     0058D820  BE 40 7D 5C 00        mov esi, 0x5c7d40      ; esi = "" (bbEmptyString) --
'                                                             the fallthrough/default result
'     0058D825  6A 00                 push 0
'     0058D827  E8 D4 6F F2 FF        call 0x4b4800           ; OpenClipboard(0)
'     0058D82C  83 F8 00              cmp eax, 0
'     0058D82F  74 31                 je 0x58d862             ; failed -> Return ""
'     0058D831  6A 01                 push 1
'     0058D833  E8 C0 6F F2 FF        call 0x4b47f8           ; IsClipboardFormatAvailable(1)
'     0058D838  83 F8 00              cmp eax, 0
'     0058D83B  74 20                 je 0x58d85d             ; unavailable -> CloseClipboard, Return ""
'     0058D83D  6A 01                 push 1
'     0058D83F  E8 AC 6F F2 FF        call 0x4b47f0           ; GetClipboardData(1) -> eax
'     0058D844  89 C3                 mov ebx, eax             ; ebx = handle
'     0058D846  53                    push ebx
'     0058D847  E8 9C C3 F1 FF        call 0x4a9be8           ; GlobalLock(ebx) -> eax (ptr)
'     0058D84C  50                    push eax
'     0058D84D  E8 0E A1 F1 FF        call 0x4a7960           ; _bbStringFromCString(ptr)
'     0058D852  83 C4 04              add esp, 4               ; cdecl cleanup, ONE call only
'     0058D855  89 C6                 mov esi, eax             ; esi = result
'     0058D857  53                    push ebx
'     0058D858  E8 93 C3 F1 FF        call 0x4a9bf0           ; GlobalUnlock(ebx)
'     0058D85D  E8 7E 6F F2 FF        call 0x4b47e0           ; CloseClipboard()
'     0058D862  89 F0                 mov eax, esi
'     0058D864  EB 00                 jmp 0x58d866
'     0058D866  5F                    pop edi
'     0058D867  5E                    pop esi
'     0058D868  5B                    pop ebx
'     0058D869  89 EC                 mov esp, ebp
'     0058D86B  5D                    pop ebp
'     0058D86C  C3                    ret
' All six DLL calls are stdcall (no caller-side "add esp,N" after any of them); only the
' _bbStringFromCString call gets an "add esp,4", which is how the two calling conventions
' are told apart in the byte stream. 0x004a7960 = _bbStringFromCString
' (extracted/brl_functions_inferred.tsv, STRONG, already used identifying the same call
' shape in Fn_0058D90B.SyncSteamAchievements.bmx). The six DLL thunk addresses are
' confirmed by extracted/callgraph_resolved.tsv (rows for caller 0x0058d81a, all "direct
' high") and by extracted/dll_imports.tsv:
'     0x004b4800 OpenClipboard              USER32.dll
'     0x004b47f8 IsClipboardFormatAvailable USER32.dll
'     0x004b47f0 GetClipboardData           USER32.dll
'     0x004a9be8 GlobalLock                 KERNEL32.dll
'     0x004a9bf0 GlobalUnlock               KERNEL32.dll
'     0x004b47e0 CloseClipboard             USER32.dll
'
' SEMANTICS: open the clipboard; if CF_TEXT (1) is available, lock the handle, convert
' the locked ANSI buffer to a BlitzMax String, unlock; either way close the clipboard;
' return the converted text, or the empty string on any failure (clipboard busy, wrong
' format, or nothing to read). CF_TEXT is passed as the literal 1 in both
' IsClipboardFormatAvailable and GetClipboardData (0058D831/0058D83D), read directly off
' the disassembly rather than assumed from the constant's usual name.
'
' RUNTIME_HELPERS.TSV CORRECTION -- READ BEFORE REUSING THIS PATTERN FOR ANOTHER DLL CALL.
' This is the first body in the tree to Extern a Win32 stdcall DLL function directly (no
' prior file anywhere under src/ does), and it exposed a table defect of exactly the
' shape 3b warns about: a wrong entry that BLOCKS a correct body rather than blessing a
' wrong one. extracted/dll_imports.tsv holds the PE import hint name verbatim
' ("OpenClipboard", no stdcall decoration -- that is genuinely what the ORIGINAL exe's
' import directory says), and helper_map.brl_table() prefixes only a bare underscore
' ("_OpenClipboard"), which is right for every existing DLL-import row because every one
' recovered so far (SteamInit, Fn_0058D987, Fn_0058D90B) calls into libsteamstub.a, a
' CDECL import library. A stdcall "Extern "Win32"" declaration is different: measured
' directly (harness.try_function probe, kept workdir, `objdump -r` on the resulting
' .o), THIS toolchain mangles a plain `Function OpenClipboard(hwnd:Int)` inside
' `Extern "Win32"` to the relocation symbol "_OpenClipboard@4" (stdcall byte-count
' decoration), not "_OpenClipboard" -- confirmed against the vendored
' tools/blitzmax-legacy-src/mod/maxgui.mod/win32maxguiex.mod compiled .s output, whose
' own OpenClipboard/CloseClipboard/GetClipboardData/GlobalLock/GlobalUnlock/
' IsClipboardFormatAvailable calls (win32maxguiex.bmx:2168-2198, declared plain in
' pub.mod/win32.mod/user32.bmx and kernel32.bmx, no alias override) carry the identical
' "@N" suffix. Tried the obvious fix first and it does NOT work: overriding the
' declaration with an explicit undecorated alias
' (`Function OpenClipboard(hwnd:Int)="OpenClipboard"`) fails to LINK at all --
' "undefined reference to `OpenClipboard'" -- because the import library this toolchain
' searches only exports the decorated symbol. So the decorated name is not a cosmetic
' choice, it is the only symbol that resolves, and helper_map's undecorated entry could
' never have matched it.
' Consequence for masking: harness.compare's name-match branch (14.2's mechanism (a))
' requires `usym in osym.split("|")`; when both usym and osym are non-empty but merely
' disagree, it unconditionally `break`s the search for THAT call site rather than
' falling through to the byte-identical-thunk fallback (b) -- so a present-but-wrong
' table entry is strictly worse than an absent one, and ordinary in-run learning could
' never reach it either, for the same reason (path (c) is behind the same `if usym and
' osym` gate). Fixed by calling helper_map.record() directly with the six measured,
' evidenced observations below, which persists into extracted/runtime_helpers.tsv and
' overrides brl_table()'s undecorated defaults in full_table() (load_table() is applied
' after brl_table() in full_table()'s merge). No conflicts were reported.
'     0x004b4800 _OpenClipboard@4
'     0x004b47f8 _IsClipboardFormatAvailable@4
'     0x004b47f0 _GetClipboardData@4
'     0x004a9be8 _GlobalLock@4
'     0x004a9bf0 _GlobalUnlock@4
'     0x004b47e0 _CloseClipboard@0
' Any future body that Externs a Win32 stdcall DLL function directly should expect the
' same "@N"-decorated symbol and check extracted/runtime_helpers.tsv before assuming
' dll_imports.tsv's undecorated name will mask.
'
' A second, purely cosmetic pitfall found and avoided: `Byte Ptr GlobalLock(h)` (casting
' an untyped/Int-returning declaration at the call site) compiles to two extra bytes, a
' redundant `mov eax,eax` (measured: 85/83, first divergence at the branch displacement
' that encodes the skipped block's length). Declaring the Extern with its real return
' type instead -- `Function GlobalLock:Byte Ptr(h:Int)`, matching
' pub.mod/win32.mod/kernel32.bmx's own declaration -- removes the cast and the body
' lands at 83/83 exactly.
' FOUR OF THESE DECLARATIONS ARE SHARED WITH Fn_0058D78D.SetClipboardText.bmx, the write
' half of this pair, recovered later by the unrecovered-function audit. That file declares
' ONLY the four Win32 functions this one does not (EmptyClipboard, SetClipboardData,
' GlobalAlloc, GlobalFree) and relies on the block below for OpenClipboard, CloseClipboard,
' GlobalLock and GlobalUnlock. Do not delete any line here on the grounds that this body
' does not call it -- CloseClipboard and GlobalUnlock are used by both. See that file's
' header for why the two blocks must stay disjoint and why its bracket lines carry a
' trailing comment. Re-verified 83/83 after the audit.
'!Raw Extern "Win32"
'!Raw Function OpenClipboard(hwnd:Int)
'!Raw Function CloseClipboard()
'!Raw Function IsClipboardFormatAvailable(fmt:Int)
'!Raw Function GetClipboardData(fmt:Int)
'!Raw Function GlobalLock:Byte Ptr(h:Int)
'!Raw Function GlobalUnlock(h:Int)
'!Raw End Extern
	Function GetClipboardText:String()
		Local result:String = ""
		If OpenClipboard(0)
			If IsClipboardFormatAvailable(1)
				Local h:Int = GetClipboardData(1)
				Local p:Byte Ptr = GlobalLock(h)
				result = String.FromCString(p)
				GlobalUnlock(h)
			EndIf
			CloseClipboard()
		EndIf
		Return result
	End Function

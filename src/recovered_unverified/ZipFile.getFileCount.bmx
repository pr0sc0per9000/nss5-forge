' ================= REFINE PASS (item 51, refine.json): body left UNCHANGED =====
' VA 0x0058dd25   40 bytes   vtable slot 0x38   sig ()i
' status/score/ZipFile.getFileCount.txt reports 3/14 (21.4%), first diff at byte 3,
' our_len=14 vs orig_len=40. That 14-byte "ours" is NOT this file's body -- it is the
' push ebp/mov ebp,esp/mov eax,0/jmp/epilogue shape of a bare `Return 0`, i.e. the
' empty-stub fallback. Confirmed against scripts/assemble.py:67-70: this file's own
' base name is listed in UNVERIFIED_SKIP ("Near-miss bodies... known NOT TO COMPILE"),
' so the shared build never compiles the body below at all; it substitutes a stub and
' status/score is scoring THAT. Nothing here can move that percentage without a change
' to assemble.py's placeholder handling for TZipFileList, which is out of scope for a
' single-file pass (rule 1) and is exactly the tooling gap the BUILD_FAIL note below
' already diagnosed.
'
' Re-derived the body from extracted/decomp/ZipFile.getFileCount@0058dd25.c and
' manually reconstructed the expected machine code statement-by-statement against the
' ORIGINAL bytes read directly from binary/NSS5.exe at VA 0x0058dd25 (read-only check,
' no assemble.py run):
'   55 89E5 8B4508                     push ebp / mov ebp,esp / mov eax,[ebp+8]
'   81780C 809C5C00 74 0E               cmp dword[eax+0Ch],005c9c80 ; je +0Eh
'   8B400C 50 8B00 FF5034 83C404        mov eax,[eax+0Ch] / push eax / mov eax,[eax]
'                                       / call [eax+34h] / add esp,4   <- m_zipFileList.getCount()
'   EB07                                jmp +07h  (over the null-path literal)
'   B8 00000000 EB00                    mov eax,0 / jmp +0   <- Return 0
'   89EC 5D C3                          mov esp,ebp / pop ebp / ret   <- shared epilogue
' This is precisely: `If m_zipFileList <> Null Then Return m_zipFileList.getCount()` /
' `Return 0`, cross-checked against src/recovered/TFixture.GetAwayTeamId.bmx (byte-
' identical, same "If x <> Null Then Return x.method() ... Return 0" idiom, same JE
' polarity for the guard, same trailing unconditional jmp-to-epilogue after each
' Return -- including the redundant `jmp +0` after a same-position Return, matching
' the compiled Return-0 stub seen elsewhere). Byte count adds up exactly: 13 + 2 + 11
' (call sequence) + 2 (EB07) + 7 (mov eax,0 + EB00) + 4 (epilogue) = 40, matching
' orig_len. The body already reconstructs to the literal original bytes; changing it
' would only make it worse. Left as-is per rule 4.
' ================= BUILD_FAIL, oracle-confirmed =================
' harness.try_method('ZipFile','getFileCount', body) -> BUILD_FAIL:
'   Compile Error: Identifier 'getCount' not found
' NOT a body defect. m_zipFileList is declared ':TZipFileList' (object_model.json,
' ZipFile scope, offset 12), but TZipFileList itself has ZERO rows anywhere in the
' extracted data -- absent from extracted/object_model.json (no "type":"TZipFileList"
' scope at all, unlike ZipFile itself) AND absent from extracted/class_tables.tsv.
' harness.py's placeholder-type generator (_build_prelude, scripts/harness.py:439-448)
' therefore emits `Type TZipFileList\nEnd Type` -- a bodyless stub with none of
' getCount()i / getEntry(i):SZipFileEntry / getEntryByName($):SZipFileEntry that this
' body and its two ZipFile siblings need to call. This is the SAME class of gap as the
' TPlayer/TMap/TTextStream vtable holes recorded in the skill's section 9, just for a
' third-party (zipengine) Type instead of a game one: the reflection metadata simply
' never described TZipFileList's layout, so neither its field count, its method count,
' nor its vtable slot ORDER (which of New/Delete/readFileList/clearFileList/getCount/
' getEntry/getEntryByName sits at which of slots 0x10.. 0x3c) can be reconstructed from
' data currently in this repo -- and guessing an order would risk silently landing
' getCount et al. at the WRONG slot in our own class table.
' FIX REQUIRES: either (a) recovering TZipFileList's own member layout from the
' zipengine decompilation (ZipFile.New/readFileList/clearFileList/ZipWriter.* all
' touch it -- extracted/decomp_annotated/Zip*.c) and teaching harness.py to emit a
' real stub for it, keyed off a real per-Type slot table the way emit_type() does for
' game Types, or (b) extending _build_prelude's placeholder list with a hand-written,
' evidence-backed method set for this one Type. Neither was attempted here: it is a
' harness/tooling gap, not a 5-minute pragma fix, and touching harness.py's shared
' placeholder logic needs its own dedicated pass, not a drive-by inside a health sweep.
' ==================================================================================
' ZipFile.getFileCount -- VA 0x0058DD25, 40 bytes
' The oracle cannot verify this body: the synthetic stub for TZipFileList carries no
' getCount() method, because TZipFileList has zero rows in the reflection data.
' (1 absolute-address slot(s) relocation-masked; emitted code identical)
' Parameter names are not recoverable from the binary and do not affect codegen.
Method getFileCount:Int()
	If m_zipFileList <> Null Then Return m_zipFileList.getCount()
	Return 0
End Method

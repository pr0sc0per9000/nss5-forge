' DecodeText  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0050874a   63 bytes   sig ($)$
' byte-identical vs NSS5.exe (63/63, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1, mode=reloc, reloc_masked=4, on two
' separately created worker trees.
'
' Found by the unrecovered-function audit (docs/reference/unrecovered-inventory.md): one of
' 23 module-level Functions inside the game's own module object that had no body in any
' tree and no row in any table.
'
' WHAT IT DOES. Wraps the string in a read-only RamStream over its own C string and hands
' that to BRL.TextStream's LoadText, which re-decodes it -- a UTF-8/BOM normalisation pass.
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32 in the code
' sections: zero call sites).
'
' THERE IS NO `MemFree` IN THIS SOURCE, AND NO BUG IN THE ORIGINAL. The `push esi /
' call _bbMemFree` at 0x00508770 is compiler-generated: it is `Val::funArgCast`'s cleanup
' for the String -> Byte Ptr conversion of the FIRST argument (codegen-patterns.md 24.1).
' CreateRamStream's first parameter is `buf:Byte Ptr`, a String is passed to it, so bcc
' emits `_bbStringToCString`, stores the result in a temp, and pushes `_bbMemFree(temp)`
' onto that CALL's cleanup list -- which is emitted after the call returns, i.e. before
' the next statement. An earlier draft read that free as a use-after-free the game gets
' away with because nothing calls the function. It is neither: the buffer is dead the
' moment CreateRamStream has copied the pointer out of it.
'
'     0050874F  8B 5D 08        mov ebx, [ebp+8]      ; a0, materialised once (used twice)
'     00508752  53              push ebx
'     00508753  E8 ..           call 0x004A6E20       ; _bbStringToCString  (funArgCast)
'     0050875B  89 C6           mov esi, eax          ; the conversion temp
'     0050875D  6A 00           push 0                ; writeable = False
'     0050875F  6A 01           push 1                ; readable  = True
'     00508761  FF 73 08        push dword [ebx+8]    ; a0.length
'     00508764  56              push esi              ; buf
'     00508765  E8 ..           call 0x0059F356       ; _brl_ramstream_CreateRamStream
'     0050876D  89 C3           mov ebx, eax          ; s -- RECYCLES a0's register
'     0050876F  56              push esi
'     00508770  E8 ..           call 0x004A8DA0       ; _bbMemFree          (the cleanup)
'     00508778  53              push ebx
'     00508779  E8 ..           call 0x0059D7E1       ; _brl_textstream_LoadText
'
' 0x0059F356 is an ALIAS SET in brl_functions.tsv (_brl_pixmap_CreatePixmap and
' _brl_ramstream_CreateRamStream have byte-identical 36-byte bodies); codegen-patterns.md
' 3h -- CreateRamStream is the member that fits, and the mask accepts it.
'
' WHY THE SPELLING MATTERS, measured. Writing the conversion out by hand --
'     Local p:Byte Ptr = a0.ToCString()
'     Local s:TStream = CreateRamStream(p, a0.length, True, False)
'     MemFree p
' -- compiles to the same 63 bytes and the same instruction at every offset, but with ebx
' and esi EXCHANGED throughout: a0 lands in esi and the conversion temp in ebx, so 20 of
' the 63 bytes differ (43/63, first_diff=+6) purely in ModRM/opcode register fields. This
' is codegen-patterns.md 24.2 exactly: the hand-written form puts the conversion in its own
' earlier statement, which moves the temp's live range and hence the colouring. Declaration
' order was ruled out first -- all three orderings of the two Locals give byte-identical
' output. Letting funArgCast do it is what closes the function.
	Function DecodeText:String(a0:String)
		Local s:TStream = CreateRamStream(a0, a0.length, True, False)
		Return LoadText(s)
	End Function

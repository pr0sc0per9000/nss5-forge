' zip_fileinfo.New -- VA 0x0058EED0, 95 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (95/95, mode=reloc, 4 absolute-address slots masked)
' tmz_date is a FIELD INITIALISER, not a statement in New. The original stores the new
' object straight into +8 (0x0058EEF6) with a retain and no release of the previous value,
' which is what bcc emits for a declared default on a field it knows is still
' uninitialised; an assignment inside New emits the full release-then-store sequence and
' 32 bytes more. Hence the '!Field pragma rather than a line of body.
' The zeroing at +0x10..+0x27 is the three Long fields' default init. +0xC is a hole and
' the original never writes it -- bcc aligns a Long to eight. scripts/harness.py's pad
' generator used to cap natural alignment at four and filled it with an Int, which added a
' `mov [ebx+0xC],0` the original does not have; the cap is now eight.
	'!Field tmz_date = New tm_zip
	Method New()
	End Method

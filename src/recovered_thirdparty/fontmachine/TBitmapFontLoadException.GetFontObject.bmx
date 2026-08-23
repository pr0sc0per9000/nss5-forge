' TBitmapFontLoadException.GetFontObject
' VA 0x00592382   21 bytes   vtable slot 0x30
' byte-identical vs NSS5.exe (21/21)
' CLAIM CORRECTED. This header previously said "code-identical ... NOT byte-identical:
' the E8 rel32 displacement is layout-dependent", and therefore did not state the
' phrase scripts/progress.py counts -- so a body the oracle certifies was being
' reported as outstanding work. The reasoning behind the old wording was sound and the
' conclusion drawn from it was not: a call's rel32 displacement IS layout-dependent, but
' that is true of nearly every body in this corpus, and the oracle already handles it by
' resolving the call target's SYMBOL on both sides and masking the operand when the
' names agree. That is the same rule certifying ~1,900 other bodies; nothing special was
' added for this one. Measured with NSS5_NO_LEARN=1 in an isolated worker tree:
'     harness.try_method -> MATCH, matched=21/21, first_diff=None
' All 21 bytes match except the call displacement; probe target verified == TDrawTextException.GetFontObject, original target 0x00592319 == TDrawTextException.GetFontObject.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted

	Method GetFontObject:TBitmapFont()
		Return Super.GetFontObject()
	End Method

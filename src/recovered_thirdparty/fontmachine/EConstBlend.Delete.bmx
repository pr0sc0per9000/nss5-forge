' EConstBlend.Delete
' VA 0x00592273   14 bytes   sig ()i
' byte-identical vs NSS5.exe (14/14, verified via try_function VA-route, see note below)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' EConstBlend is one of the two "root Types" with the padding-stub edge case -- it has no
' row in extracted/class_tables.tsv, so
' object_model.json's Method offsets for it are raw VAs, not vtable slots (confirmed:
' New=5841489=0x592251, Delete=5841523=0x592273, GetCurrent=5841537=0x592281, all inside
' this VA). harness.try_method('EConstBlend','Delete',...) cannot locate it --
' bytematch.find_method assumes a slot-resolvable class table and throws
' ("unpack_from requires a buffer of at least 14839019 bytes ... actual buffer size
' 9383424") -- so this body was verified through harness.try_function's VA route instead
' (plain wrapper Function, no dotted name, at the real orig_va) rather than try_method.
' That route is valid here because the body touches no field and no Self state: EConstBlend
' declares no Fields at all (Const-only "enum" Type), so a Method with an unused implicit
' Self compiles to exactly the same bytes as a Function with no parameters -- confirmed by
' the byte-identical MATCH.
'
' Body: Type has zero fields, so Delete() is the plain empty-method shape (Return 0
' implicit); nothing to release.

	Method Delete:Int()
	End Method

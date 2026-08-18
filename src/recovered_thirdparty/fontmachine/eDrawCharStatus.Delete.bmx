' eDrawCharStatus.Delete
' VA 0x00592688   14 bytes   sig ()i
' byte-identical vs NSS5.exe (14/14, verified via try_function VA-route, see note below)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' eDrawCharStatus is the second of the two "root Types" with the padding-stub edge case
' -- same class_tables.tsv gap as
' EConstBlend (see EConstBlend.Delete.bmx for the full explanation): object_model.json's
' offset here (5842568 = 0x00592688) is a raw VA, not a slot, and try_method cannot locate
' it (bytematch.find_method throws trying to treat the offset as file-offset-derived).
' Verified through harness.try_function's VA route instead. Valid for the same reason as
' EConstBlend.Delete: eDrawCharStatus declares no Fields (Const-only "enum" Type), so an
' unused implicit Self makes the Method byte-identical to a bare Function.
'
' Body: Type has zero fields, so Delete() is the plain empty-method shape; nothing to
' release.

	Method Delete:Int()
	End Method

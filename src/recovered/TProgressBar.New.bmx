' TProgressBar.New
' VA 0x0051A390   143 bytes   vtable slot 0x10   sig ()i   KIND=Method, class-table slot 0x10
' byte-identical vs NSS5.exe (143/143, original length from Ghidra's inventory, mode=reloc)
' ASSUMPTIONS
'   body is EMPTY -- Super.New (TGadget.New), the class-table store and every field default
'     (image/fillimage/fillicon/boosticon = Null, fillcolour = "", the Float/Int zeroes)
'     are compiler-emitted, not source
'   field default Field oldfillcolour:String = "FF0000"; literal READ OUT OF THE EXE at
'     0x00C725EC. It is NOT "": that reading is invisible to the oracle because the
'     literal's address is relocation-masked, so it has to be read out of the exe.
	Method New()
		'!Field oldfillcolour = "FF0000"
	End Method

' TKitStrings.New
' VA 0x004DC371   89 bytes   vtable slot 0x10   sig ()i   KIND=Method, class-table slot 0x10
' byte-identical vs NSS5.exe (89/89, original length from Ghidra's inventory, mode=reloc)
' ASSUMPTIONS
'   body is EMPTY -- all 89 bytes are bcc's automatic initialisation of the five String
'     fields; no body statement can produce them (bcc emits field initialisers inside the
'     Type declaration, ahead of every statement)
'   field defaults READ OUT OF THE EXE, one per store, in offset order:
'     style  +0x08 = "PLAIN"   @0x00C75670
'     shirt1 +0x0C = "FFFFFF"  @0x00C5D680
'     shirt2 +0x10 = "FFFFFF"  @0x00C5D680
'     shorts +0x14 = "0000FF"  @0x00C72868
'     socks  +0x18 = "FFFFFF"  @0x00C5D680
'     The oracle cannot tell these values on its own, because each store is
'     `mov [ebx+off], <relocated addr>`.
	Method New()
		'!Field style = "PLAIN"
		'!Field shirt1 = "FFFFFF"
		'!Field shirt2 = "FFFFFF"
		'!Field shorts = "0000FF"
		'!Field socks = "FFFFFF"
	End Method

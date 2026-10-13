' TGadget.New
' VA 0x00513599   326 bytes
' byte-identical vs NSS5.exe (326/326, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_allgadgets:TList
'!Field txtalignx :Int = 1
'!Field alph :Float = 1.0
'!Field forcetxtalpha :Int = 1
'!Field fntSize :Int = 1
If Not g_allgadgets Then g_allgadgets = CreateList()
' CRASH FIX: the original also did g_allgadgets.AddLast(Self). Nothing ever reads that list,
' so it only kept every gadget and its images alive for good (message boxes, help boxes,
' alerts, tooltips, menu credits). The 32-bit game ran out of memory and crashed with
' EXCEPTION_ACCESS_VIOLATION, often while saving.
Self.children = CreateList()
Self.txtlines = CreateList()

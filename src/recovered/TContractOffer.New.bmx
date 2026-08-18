' TContractOffer.New
' VA 0x00570EED   174 bytes
' byte-identical vs NSS5.exe (174/174, original length from Ghidra's inventory, mode=reloc)
' The nine field zero/Null initialisers in the decompilation are compiler-emitted default
' init for the declared Fields -- they are NOT source. Only the list registration is.
' The null test is the 21-byte `If Not` form (setne/movzx/cmp/jne), not `= Null`.
' GLOBAL NAME IS OURS; its declared type TList is load-bearing (selects slot 0x44 AddLast).
'!Global g_contractoffers:TList
If Not g_contractoffers Then g_contractoffers = CreateList()
g_contractoffers.AddLast(Self)

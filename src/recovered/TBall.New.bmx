' TBall.New
' VA 0x004C74E1   433 bytes   mode=reloc   byte-identical vs NSS5.exe (433/433)
' KIND=Method, SIG ()i, slot 0x10
' ASSUMPTIONS
'   Almost all of this function is COMPILER-GENERATED field initialisation emitted from the
'   Type declaration (41 fields in declaration order), not source statements. Writing those
'   stores as body statements gives 904 bytes -- they land AFTER bcc's own defaults.
'   Only three fields carry a non-zero initialiser, recorded as '!Field pragmas:
'     alph = 1.0        (fld1 / fstp [ebx+0x10], not fldz)
'     colour = "FFFFFF" (literal at 0x00C5D680, retained)
'     frame = 1         (mov dword [ebx+0xA0],1)
'   0x00C5A4C0 -> g_balls:TList. Slot 0x44 = TList.AddLast; 0x005B40BF is the
'   CreateList|CreateMap|TGNetHost.Create alias set, resolved to CreateList by the
'   following AddLast (10.8).
'   The guard is the object->Int cast form `If Not g_balls` (setne/movzx/cmp 0), not
'   `If g_balls = Null`.
'!Field alph = 1.0
'!Field colour = "FFFFFF"
'!Field frame = 1
'!Global g_balls:TList
If Not g_balls Then g_balls = CreateList()
g_balls.AddLast(Self)

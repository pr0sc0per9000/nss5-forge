' TFormation.New
' VA 0x004D7EF2   394 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (394/394, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=7.
' Body-only format: statements only, parameters are a0, a1, ...
' The METHOD BODY IS EMPTY.  Everything in this 394-byte function is bcc's own
' default-field-init prologue plus two FIELD INITIALISERS declared on the Type:
'   FUN_004a8e50(Self) / *Self = ClassTable_TFormation   -- compiler preamble
'   retain 0x005c7d40 + store into name                  -- String field default ""
'   m_Defenders .. m_Attackers = 0                       -- Int field defaults
'   FUN_004a63d0 = _bbArrayNew1D                         -- the two array initialisers
' m_TacPos (+0x20, []i): _bbArrayNew1D("i",0x23) followed by 35 immediate stores at
'   data offsets +0x18..+0xa0, i.e. an Int array literal of 35 elements.
' m_TacLabel (+0x24, []$): _bbArrayNew1D("$",0x23) with NO element stores, i.e. a
'   plain `String[35]` sized declaration.
' Field initialisers cannot be written as body statements -- bcc emits them ahead of
' every statement -- so they go through the harness's '!Field pragma.
'!Field m_TacPos:Int[] = [1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,0]
'!Field m_TacLabel:String[35]

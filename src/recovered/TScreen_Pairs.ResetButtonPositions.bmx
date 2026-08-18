' TScreen_Pairs.ResetButtonPositions
' VA 0x00579055   153 bytes   mode=reloc   MATCH 153/153
' KIND=Function (static method on TScreen_Pairs), SIG ()i, class-table slot 0x38.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'  * Global 0x00C6C81C declared TButton[] (globals_final.tsv says Object[], usage-typed,
'    init=bbEmptyArray). The elements are dispatched through slot 0x84 = TGadget.SetPosition
'    (i,i,i) and field +0x38 = TGadget.alive:Int, so any TGadget subclass emits the same
'    bytes -- THIS BODY CANNOT DECIDE THE ELEMENT TYPE, and said so when it read TGadget[].
'    TScreen_Pairs.UpdateFaces decides it: it loads the same absolute 0x00C6C81C and
'    dispatches `call dword ptr [eax+0x90]` = slot 144 = TButton.SetIcon(:TImage)i. TGadget's
'    table ends at slot 132, so 0x90 is not a TGadget slot and the TGadget spelling cannot
'    compile that call. TButton Extends TGadget directly (class_tables.tsv; TButton's fields
'    start at 92, immediately after TGadget's last at 88), so slots 132 and 56 are inherited
'    unchanged and this body re-verifies 153/153 under the corrected type -- measured, not
'    assumed. See extracted/globals_type_overrides.tsv. Name is ours.
'  * Slot 0x84 resolved in vtable_map.tsv as TGadget.SetPosition ($ sig (i,i,i)).
'  * The two 94-value Locals are memory slots [ebp-4] and [ebp-8]; declaration order is
'    load-bearing (w must be the FIRST declared so it lands at [ebp-4], which is what the
'    x term multiplies by).
'  * px/py must be Locals: with them the invocant loads into ecx AFTER both args (6-byte
'    mov ecx,[mem]); inlining the expressions loads it into eax first (5-byte mov eax,moffs)
'    and the function comes out 152 bytes.
'  * reloc_masked=2 = the two absolute loads of the Global's array pointer.
'!Global g_pairs_buttons:TButton[]
Local w:Int = 94
Local h:Int = 94
Local n:Int = 0
For Local x:Int = 1 To 4
	For Local y:Int = 1 To 4
		Local px:Int = x * w + 90 + x * 10
		Local py:Int = y * h + 12 + y * 10
		g_pairs_buttons[n].SetPosition(px, py, 1)
		g_pairs_buttons[n].alive = 0
		n = n + 1
	Next
Next

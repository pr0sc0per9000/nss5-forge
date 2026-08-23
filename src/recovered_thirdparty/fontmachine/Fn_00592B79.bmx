' Fn_00592B79  --  fontmachine module Function
' VA 0x00592B79   14 bytes
' byte-identical vs NSS5.exe (14/14, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/owner. Zero callers in extracted/callgraph_resolved.tsv and
' extracted/ghidra/function_inventory.tsv (caller count 0), no row in
' extracted/vtable_map.tsv, and no offset in extracted/object_model.json falls on this VA
' (checked against every scope, not just EConstBlend/eDrawCharStatus, whose same-shaped
' Delete()s at 0x592273/0x592688 this one is textually identical to). Following law 8 /
' the codegen-patterns naming rule: named by VA, not guessed.
'
' Body is the standard empty-Delete/empty-zero-return shape: push ebp; mov ebp,esp;
' mov eax,0; jmp; mov esp,ebp; pop ebp; ret. Written as a bare Function (no receiver) since
' nothing ties it to a Type; if a future session identifies the owner, rename the file and
' rewrap as `Method Delete:Int()`/`End Method` -- the bytes are identical either way (see
' EConstBlend.Delete.bmx for why a no-op body makes an implicit Self invisible to codegen).

Function Fn_00592B79:Int()
End Function

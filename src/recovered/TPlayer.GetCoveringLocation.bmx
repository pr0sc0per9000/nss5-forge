' TPlayer.GetCoveringLocation
' VA 0x004F96A1   343 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG=(f,f)i, class-table slot 0x12c   (a0 = target x, a1 = target y)
' ORACLE 343/343 reloc_masked=10, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared and typed:
'     0x00C5D638 g_goalline:Int   (table: Int, bare dword access, no refcount traffic)
'   Fields (object_model.json, TPlayer): +0x7C desx:Float, +0x80 desy:Float
'   Slots resolved:
'     TPlayer 0x160 = GetShootingDirection()i
'     [0x00C5D998] = TPitch classtable(0x00C5D92C) + 0x6C = TPitch.YardsToPixels(f)f
'   Calls named from extracted/runtime_helpers.tsv:
'     0x004A1F00 = _bbSin, 0x004A1F10 = _bbCos.
'     0x004A1F90 is ATan2 (fpatan then *180/pi) -- identified from its own body, it is
'     not in brl_functions.tsv.
'     0x00505DA2 = Dist2D (module Function, src/recovered_module/Dist2D.bmx).
'   Float constants read out of .rdata: 0x00C7A068/6C = 1.1, 0x00C7A070/74 = 1.5.
'
' CODEGEN NOTES (each cost an iteration)
'   * gx/gy are Int Locals living in ebx/esi; the `mov [ebp-0x24],r / fild` pairs are
'     bcc's Int->Float widening of those registers, not extra variables.
'   * Operand order in the last two statements is load-bearing. Written as
'     `gx + (d / sc) * Cos(ang)` the body is 363 bytes: bcc evaluates (d/sc) first and
'     must spill it across the Cos call, costing an extra 8-byte Double slot per
'     statement (frame 0x34 instead of 0x24). With the call FIRST -- `Cos(ang) * (d/sc)`
'     -- the call result stays on the x87 stack and the divide follows it. 343 exact.
'   * The parentheses around (d / sc) are required; `Cos(ang) * d / sc` regroups.
'!Global g_goalline:Int
Local gx:Int = 0
Local gy:Int = g_goalline * -Self.GetShootingDirection()
Local d:Float = Dist2D(gx, gy, a0, a1)
Local ang:Float = ATan2(a1 - gy, a0 - gx)
Local sc:Float = d / TPitch.YardsToPixels(19.0)
If sc < 1.1 Then sc = 1.1
If sc > 1.5 Then sc = 1.5
Self.desx = gx + Cos(ang) * (d / sc)
Self.desy = gy + Sin(ang) * (d / sc)

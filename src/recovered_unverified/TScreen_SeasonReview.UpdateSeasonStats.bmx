' UNVERIFIED -- close, not proven byte-identical. Do not promote to src/recovered/ without
' closing the last-4-bytes gap noted below.
' TScreen_SeasonReview.UpdateSeasonStats   VA 0x005601CA   1279 bytes (Ghidra-authoritative)
' KIND=Function (static, no Self)   SIG=()i   vtable slot 0x38
' Revised this pass using harness.try_method/localise_diff
' directly against the real bmk compiler (not blind) -- see WHAT CHANGED below.
'
' RESULT THIS PASS: length now EXACT (1279/1279, was 1013/1279, delta was -266). Verified
' via localise_diff.localise_body: same length, only 4 real (non-relocation) bytes differ,
' both are single-byte immediate swaps (0x0D<->0x0C) in row 1's two combined-stat columns;
' every other byte in the function -- all 7 AddItem rows, the whole array-build sequence,
' every receiver-cache and register choice -- is byte-identical. See ROOT CAUSE 2 for why
' those 4 bytes resist a further fix without regressing the other 1275.
'
' ROOT CAUSE 1 (the -266 problem, now fixed): the array-literal argument to AddItem,
' `[a, b, c]`, compiles differently depending on whether a/b/c are written as bare
' expressions INSIDE the literal or as separately-declared Locals assigned just before it.
' Confirmed empirically (try_method on isolated single-row probes):
'   * `g_sr_tblSeason.AddItem([GetText(...), g_profile.GetStringStat(...), ...], "", "")`
'     with the calls written directly inside the `[...]` -- bcc allocates the array FIRST
'     (`_bbArrayNew1D` before any element is evaluated) and stores each element into it as
'     soon as that element's value is ready. This is a real, different, shorter code shape;
'     it is what produced 1013/1279 (delta -266) in the prior pass.
'   * `Local lbl:String ... : lbl = GetText(...) : g_sr_tblSeason.AddItem([lbl, s1, s2], ...)`
'     -- with each element pre-computed into its own Local and the array literal containing
'     only bare reads of those Locals -- bcc instead evaluates every element into a register
'     (or, once registers run out, a stack slot) FIRST, then calls `_bbArrayNew1D` once, then
'     copies all three values into it via `edx = <slot>; inc [edx+4]; mov [eax+off], edx`.
'     This is exactly the original's shape (confirmed instruction-by-instruction against
'     `harness.disasm_original`) and is what produces the 1279-byte, 32-byte-frame (`sub
'     esp,0x20`) result below. `lbl`/`s1`/`s2` are declared ONCE and reassigned (no `Local`
'     keyword) on every row, matching TScreen_Stats.UpdateStatTable.bmx's own `Local
'     lbl:String` reuse -- and matching the original, which reuses the SAME register/slot
'     per role (ebx=label, edi=first stat, [ebp-4]=second stat) on every one of the 7 rows,
'     confirmed by reading all 7 rows of the real disassembly end to end.
' The "receiver-spill-to-a-distinct-slot" theory from the previous pass was a correct
' OBSERVATION but the wrong EXPLANATION: the distinct slots ([ebp-0xC]..[ebp-0x20], one per
' row for g_sr_tblSeason) are not something to force via an explicit Local -- they fall out
' automatically once the element-Locals free up ebx/edi/[ebp-4] the way the original's do.
' Forcing the AddItem receiver into an explicit named Local was tried this pass and made
' things WORSE (shifted unrelated code, in one variant even flipping frame size); it was not
' needed once the real cause (element pre-computation) was fixed.
'
' ROOT CAUSE 2 (the remaining 4 bytes, row 1 only): row 1 ("Appearances") is NOT the simple
' one-GetStringStat-per-column shape of rows 2-7. Reading the real disassembly closely (the
' decompilation's merged-argument printout obscures this) shows each of row 1's two stat
' columns is itself a 4-part concat, combining TWO different stat codes at the SAME
' sub-index: column "3" is `GetStringStat(13,3,0,yr,0) + " (" + GetStringStat(12,3,0,yr,0)
' + ")"`, column "4" is the same with sub-index 4. (13 = the main stat, matching rows 2-7's
' convention; 12 is a second, related stat -- plausibly "substitute appearances" given the
' label GetText("Appearances")+" ("+GetText("tla_Substitute")+")" uses the identical 4-part
' shape one line earlier, and reproduces byte-for-byte.) The previous pass's `(13,3,...)` /
' `(13,4,...)` pair for both columns was simply wrong -- confirmed by decoding the actual
' push/call sequence at 0x560262-0x560279 and 0x5602C1-0x5602D7 (stat code 0xC there, not
' 0xD), not by trusting Ghidra's merged printout.
' Reproducing `s1 = A + " (" + B + ")"` in ONE statement (matching the label's own,
' byte-perfect shape) gets every byte right EXCEPT the two GetStringStat call sites' stat-
' code immediate, which come out swapped (0xC where the original has 0xD and vice versa).
' Isolated with a single-line probe: for a method-call chain sharing one receiver
' (`g_profile.M(..) + lit + g_profile.M(..) + lit`), bcc evaluates the SECOND-written call
' first (this is what lets it cache the receiver across both calls -- confirmed the cached
' copy lands in a register and is reused, not reloaded, for the second-executed call). The
' label's `GetText(..) + lit + GetText(..) + lit` does NOT show this reordering (GetText is a
' plain Function, no shared receiver to cache), which is why it matches exactly while the
' stat pair does not. Splitting the stat-pair into two statements
' (`s1 = GetStringStat(13,...) + " (" : s1 = s1 + GetStringStat(12,...) + ")"`) DOES restore
' the written call order, but it also defeats the receiver-caching optimisation (each call
' reloads g_profile fresh instead of reusing a cached copy), which costs a stack slot the
' original does not spend and regresses the length to 1274/1279 -- worse overall than
' accepting the 4-byte swap. Tried swapping which stat is written first to compensate: that
' also swaps which value lands leftmost in the final string, i.e. changes the game-visible
' text, which is not an acceptable trade for 4 bytes. Tried wrapping the second call's
' receiver in `TProfile(g_profile)` to make it textually different and defeat the same-
' receiver detection: no effect, byte-identical output to the plain version.
' Net effect of the swap: the STORED VALUE is unaffected either way (GetStringStat is a
' side-effect-free getter; only the machine order in which the two calls execute changes,
' and the compiler's own data-flow still routes each call's result to the correct side of
' the concatenation regardless of which one it runs first) -- i.e. this is believed to be a
' pure instruction-ordering artifact with no behavioural difference, not a second bug.
'
' Field/Global/call mapping (all confirmed, not in doubt, unchanged from previous pass):
'   0x00C687CC g_sr_tblSeason:TTable   -- established name, src/recovered/
'     TScreen_SeasonReview.CreateScreen.bmx line 19 ("g_sr_tblSeason:TTable 0x00C687CC").
'   0x00C6F028 g_profile:TProfile      -- established name, src/recovered/
'     TScreen_SeasonReview.UpdateSeasonTournaments.bmx (a sibling in this same Type, same
'     "current season minus 1" pattern: `g_profile.date.GetYear() - 1`).
'   g_profile.date          TProfile +0x10 (:TMyDate);  TMyDate.GetYear()  slot 0x54
'   g_profile.GetStringStat  TProfile slot 0x8C, sig (i,i,i,i,i):$ (object_model.json)
'   g_sr_tblSeason.ClearItems()   TTable slot 0x9C
'   g_sr_tblSeason.AddItem([]$,$,$)i   TTable slot 0x94
'   GetText($):String takes exactly 1 argument at every site (Ghidra's printed argument
'   lists merge GetText's real arg with the pushes of the FOLLOWING call).
'   _bbStringConcat (0x004A7C20) confirmed via runtime_helpers.tsv.
'   _bbArrayNew1D (0x004A63D0) confirmed via runtime_helpers.tsv.
'
' Stat codes (raw immediates from the disassembly, decimal): row1 columns combine 13 and 12
' (see ROOT CAUSE 2); rows 2-7 are single-stat: 5=Goals, 4=Assists, 3=Passes, 17=Tackles,
' 15=Star Man, 18=Average Rating (final row's GetStringStat arg is 1 not 0 -- an extra flag,
' presumably "format as decimal"). The two GetStringStat calls per row use season-half codes
' 3 and 4 (home/away half of season or similar; semantics not needed for byte fidelity).
'
' Body-only format: statements only, no parameters (KIND=Function, no Self).
'!Global g_sr_tblSeason:TTable
'!Global g_profile:TProfile
g_sr_tblSeason.ClearItems()
Local yr:Int = g_profile.date.GetYear() - 1
Local lbl:String
Local s1:String
Local s2:String
lbl = GetText("Appearances") + " (" + GetText("tla_Substitute") + ")"
s1 = g_profile.GetStringStat(13, 3, 0, yr, 0) + " (" + g_profile.GetStringStat(12, 3, 0, yr, 0) + ")"
s2 = g_profile.GetStringStat(13, 4, 0, yr, 0) + " (" + g_profile.GetStringStat(12, 4, 0, yr, 0) + ")"
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Goals")
s1 = g_profile.GetStringStat(5, 3, 0, yr, 0)
s2 = g_profile.GetStringStat(5, 4, 0, yr, 0)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Assists")
s1 = g_profile.GetStringStat(4, 3, 0, yr, 0)
s2 = g_profile.GetStringStat(4, 4, 0, yr, 0)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Passes")
s1 = g_profile.GetStringStat(3, 3, 0, yr, 0)
s2 = g_profile.GetStringStat(3, 4, 0, yr, 0)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Tackles")
s1 = g_profile.GetStringStat(17, 3, 0, yr, 0)
s2 = g_profile.GetStringStat(17, 4, 0, yr, 0)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Star Man")
s1 = g_profile.GetStringStat(15, 3, 0, yr, 0)
s2 = g_profile.GetStringStat(15, 4, 0, yr, 0)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
lbl = GetText("Average Rating")
s1 = g_profile.GetStringStat(18, 3, 0, yr, 1)
s2 = g_profile.GetStringStat(18, 4, 0, yr, 1)
g_sr_tblSeason.AddItem([lbl, s1, s2], "", "")
Return 0

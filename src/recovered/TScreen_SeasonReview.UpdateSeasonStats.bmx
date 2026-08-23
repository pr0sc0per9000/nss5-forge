' TScreen_SeasonReview.UpdateSeasonStats
' VA 0x005601CA   1279 bytes   vtable slot 0x38   sig ()i
' KIND=Function (static, no Self)
' byte-identical vs NSS5.exe (1279/1279, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=84) under NSS5_NO_LEARN=1, no learned_helpers.
'
' HOW THE LAST 4 BYTES CLOSED (worker 214). The body sat at 1279/1279 length with exactly
' 4 real byte differences: the stat-code immediates of row 1's four GetStringStat calls,
' 0x0D where the original has 0x0C and vice versa (original offsets +137, +164, +232, +259).
' The previous header explained this as bcc reordering two calls that share a receiver, and
' concluded the swap could not be fixed without changing the game-visible text. That
' explanation was wrong, and the evidence that settles it is the STRING LITERALS, which
' nobody had read:
'   0x00C896B0 = "tla_Substitute"   0x00C896D8 = "Appearances"
'   0x00C70EF8 = ")"                0x00C70F08 = " ("
' In the label's own byte-perfect 4-term concat at 0x005601FA-0x0056023A the original pushes
' ")" first, then calls GetText("tla_Substitute"), then pushes " (", then calls
' GetText("Appearances"). So for `A + " (" + B + ")"` bcc emits term4, term3, term2, term1 --
' a flat + chain evaluates RIGHT TO LEFT (codegen-patterns 23.3), and the FIRST-EXECUTED call
' is the RIGHT operand. There is no receiver-caching reorder; ours and the original emit
' structurally identical code here, including the same two `mov <reg>,[g_profile]` loads in
' the same order (edi for the later-executed call, eax for the earlier one).
' Applying that rule to the stat pair: the original's first-executed call carries stat 13, so
' 13 is the RIGHT operand and 12 is the LEFT one. The source is
' `GetStringStat(12,...) + " (" + GetStringStat(13,...) + ")"`, i.e. the displayed text is
' "12 (13)" -- which also reads correctly against the label "Appearances (Substitute)":
' 12 = appearances, 13 = substitute appearances shown in brackets. Swapping the two stat
' codes was a single change and took the body straight from 4 subs to MATCH.
'
' ROOT CAUSE of the earlier -266 length deficit, kept because it is the load-bearing shape:
' the elements of the `[a, b, c]` array literal passed to AddItem must be pre-computed into
' Locals that are declared ONCE and reassigned per row. Writing the calls directly inside the
' `[...]` makes bcc allocate the array first (_bbArrayNew1D before any element) and store
' each element as it becomes ready -- a genuinely shorter, different shape (1013 bytes).
' With the element Locals, bcc evaluates all three into registers/slots first, calls
' _bbArrayNew1D once, then copies them in via `edx = <slot>; inc [edx+4]; mov [eax+off], edx`,
' which is the original's shape and the 32-byte frame (`sub esp,0x20`). The per-row distinct
' receiver slots ([ebp-0xC]..[ebp-0x20] for g_sr_tblSeason) fall out of that automatically;
' forcing the receiver into an explicit named Local was tried and made things worse.
'
' Field/Global/call mapping (all confirmed):
'   0x00C687CC g_sr_tblSeason:TTable   -- src/recovered/TScreen_SeasonReview.CreateScreen.bmx
'   0x00C6F028 g_profile:TProfile      -- src/recovered/TScreen_SeasonReview.UpdateSeasonTournaments.bmx
'   g_profile.date          TProfile +0x10 (:TMyDate);  TMyDate.GetYear()  slot 0x54
'   g_profile.GetStringStat TProfile slot 0x8C, sig (i,i,i,i,i):$
'   g_sr_tblSeason.ClearItems()        TTable slot 0x9C
'   g_sr_tblSeason.AddItem([]$,$,$)i   TTable slot 0x94
'   GetText($):String takes exactly 1 argument at every site (Ghidra's printed argument
'   lists merge GetText's real arg with the pushes of the FOLLOWING call).
'   _bbStringConcat 0x004A7C20, _bbArrayNew1D 0x004A63D0 (runtime_helpers.tsv).
'
' Stat codes (raw immediates, decimal): row 1 combines 12 and 13; rows 2-7 are single-stat:
' 5=Goals, 4=Assists, 3=Passes, 17=Tackles, 15=Star Man, 18=Average Rating (the last row's
' final GetStringStat argument is 1, not 0). The two columns per row use 3 and 4.
'
' Body-only format: statements only, no parameters (KIND=Function, no Self).
' g_sr_tblSeason is 0x00C687CC and g_profile is 0x00C6F028 (see the mapping block above).
' The addresses stay OFF the pragma lines: harness.GLOBAL_DECL_RX does not tolerate a
' trailing comment, so a commented pragma fails to parse, dedupes by whole-line text
' instead of by name, and collides with the module-scope g_profile ("Duplicate identifier").
'!Global g_sr_tblSeason:TTable
'!Global g_profile:TProfile
g_sr_tblSeason.ClearItems()
Local yr:Int = g_profile.date.GetYear() - 1
Local lbl:String
Local s1:String
Local s2:String
lbl = GetText("Appearances") + " (" + GetText("tla_Substitute") + ")"
s1 = g_profile.GetStringStat(12, 3, 0, yr, 0) + " (" + g_profile.GetStringStat(13, 3, 0, yr, 0) + ")"
s2 = g_profile.GetStringStat(12, 4, 0, yr, 0) + " (" + g_profile.GetStringStat(13, 4, 0, yr, 0) + ")"
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

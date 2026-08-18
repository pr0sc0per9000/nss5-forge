// NSS5CallGraph -- whole-program call-graph extraction for NSS5.exe.
//
// Emits three TSVs into the directory given as the single script argument:
//
//   callgraph_functions.tsv   addr, name, section, size, ninsn, ndirect, nindirect
//   callgraph_direct.tsv      caller, site, callee, kind          (call rel32 / tail jmp)
//   callgraph_indirect.tsv    caller, site, form, base_reg, slot, vt, term, chain, raw
//
// Why the indirect file matters: legacy BlitzMax compiles a METHOD call to
//     push args ; push Self ; mov R,[Self] ; call dword ptr [R + slot]
// so the callee is only known once you know the *static type* of the receiver.
// This script does NOT guess the type. Per indirect call site it records:
//   slot  -- the vtable displacement (directly usable against extracted/vtable_map.tsv)
//   vt    -- 1 if a `mov R,[X+0]` class-table load was found feeding the call, i.e. this
//            really is BlitzMax virtual dispatch and not a bare function pointer / IAT call
//   term  -- where the receiver ultimately came from:
//              PARAM+0xN     [ebp+N]; for a Method PARAM+0x8 == Self
//              LOCAL-0xN     [ebp-N]
//              STACK+0xN     [esp+N]  (frame-pointer-omitted .text runtime code)
//              GLOBAL:0xVA   absolute data address
//              RETVAL:0xVA   return value of the direct call at 0xVA
//              IMM:0xN / ARRAYELEM / GIVEUP:<mnem> / NOTFOUND / CROSSCALL / OUTOFBODY
//   chain -- the literal backward def-use walk, e.g. "EDX=[EAX+0x0];EAX=[EAX+0x18];EAX=[EBP+0x8]"
//            Owner-type inference is done downstream in Python from this string, so the
//            Ghidra pass stays a pure, auditable observation with no semantic guessing.
//
// Read-only: creates nothing, renames nothing. Run with -noanalysis -readOnly.
//
//@category NSS5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.FlowType;

import java.io.File;
import java.io.PrintWriter;
import java.util.*;
import java.util.regex.*;

public class NSS5CallGraph extends GhidraScript {

    private static final int MAX_BACK_STEPS = 1500;

    private static final Set<String> REGS32 = new HashSet<>(Arrays.asList(
            "EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP"));

    // "dword ptr [EAX + 0x4c]" / "[EBX]" / "[EBX + EDX*0x4 + 0x18]" / "[0x00c5bb38]"
    private static final Pattern MEMPAT = Pattern.compile("\\[([^\\]]*)\\]");

    private static String hx(Address a) { return a == null ? "" : String.format("0x%08x", a.getOffset()); }
    private static String hx(long v) {
        return v < 0 ? String.format("-0x%x", -v) : String.format("0x%x", v);
    }

    private static String regKey(Register r) {
        if (r == null) return null;
        Register b = r.getBaseRegister();
        String n = (b == null ? r : b).getName().toUpperCase(Locale.ROOT);
        return REGS32.contains(n) ? n : n;
    }

    private String sectionOf(Address a) {
        MemoryBlock b = currentProgram.getMemory().getBlock(a);
        return b == null ? "?" : b.getName();
    }

    // ---- operand decoding -------------------------------------------------

    /** Decoded source operand of a MOV. */
    private static class Src {
        String kind;     // "reg" | "mem" | "imm" | "absmem" | "other"
        String baseReg;  // for mem
        long disp;
        boolean hasIndex;
        long value;      // for imm / absmem
    }

    private Src decodeSrc(Instruction ins, int op) {
        Src s = new Src();
        String rep;
        try { rep = ins.getDefaultOperandRepresentation(op); }
        catch (Exception e) { s.kind = "other"; return s; }
        if (rep == null) { s.kind = "other"; return s; }
        rep = rep.trim();

        Matcher m = MEMPAT.matcher(rep);
        if (!m.find()) {
            String up = rep.toUpperCase(Locale.ROOT);
            if (REGS32.contains(up)) { s.kind = "reg"; s.baseReg = up; return s; }
            Register r = ins.getRegister(op);
            if (r != null) { s.kind = "reg"; s.baseReg = regKey(r); return s; }
            // scalar immediate
            for (Object o : ins.getOpObjects(op)) {
                if (o instanceof Scalar) { s.kind = "imm"; s.value = ((Scalar) o).getSignedValue(); return s; }
                if (o instanceof Address) { s.kind = "imm"; s.value = ((Address) o).getOffset(); return s; }
            }
            s.kind = "other";
            return s;
        }

        // memory operand -- decide base register / index / displacement from opObjects
        int nreg = 0;
        List<Long> scalars = new ArrayList<>();
        Long abs = null;
        for (Object o : ins.getOpObjects(op)) {
            if (o instanceof Register) {
                String k = regKey((Register) o);
                nreg++;
                if (nreg == 1) s.baseReg = k; else s.hasIndex = true;
            } else if (o instanceof Scalar) {
                scalars.add(((Scalar) o).getSignedValue());
            } else if (o instanceof Address) {
                abs = ((Address) o).getOffset();
            }
        }
        if (s.baseReg == null) {
            s.kind = "absmem";
            s.value = (abs != null) ? abs : (scalars.isEmpty() ? 0 : scalars.get(scalars.size() - 1));
            return s;
        }
        s.kind = "mem";
        if (abs != null) s.disp = abs;
        else if (!scalars.isEmpty()) s.disp = scalars.get(scalars.size() - 1);
        else s.disp = 0;
        return s;
    }

    /** Does this instruction write the 32-bit register `cur`? Uses Ghidra's result objects. */
    private boolean writes(Instruction ins, String cur) {
        Object[] res;
        try { res = ins.getResultObjects(); } catch (Exception e) { return false; }
        if (res == null) return false;
        for (Object o : res) {
            if (o instanceof Register && cur.equals(regKey((Register) o))) return true;
        }
        return false;
    }

    // ---- the backward def-use walk ---------------------------------------

    private static class Trace {
        boolean vt;
        String term = "NOTFOUND";
        StringBuilder chain = new StringBuilder();
    }

    private static void step(Trace t, String s) {
        if (t.chain.length() > 0) t.chain.append(';');
        t.chain.append(s);
    }

    /**
     * @param wantVT true for call receivers (the first `mov R,[X+0]` is the BBClass load);
     *               false when tracing an arbitrary value such as a global-store source.
     */
    private Trace traceReceiver(Function f, Instruction call, String startReg, boolean wantVT) {
        Trace t = new Trace();
        if (startReg == null) { t.term = "NOREG"; return t; }
        String cur = startReg;
        long curSlot = Long.MIN_VALUE;   // when >= MIN, we are chasing [EBP+curSlot] instead of a register
        Instruction ins = call.getPrevious();
        int steps = 0;

        while (ins != null && steps < MAX_BACK_STEPS) {
            if (!f.getBody().contains(ins.getAddress())) { t.term = "OUTOFBODY"; return t; }
            steps++;
            String mn = ins.getMnemonicString().toUpperCase(Locale.ROOT);
            FlowType ft = ins.getFlowType();

            // ---- chasing a stack slot: look for the store that defined it ----
            if (curSlot != Long.MIN_VALUE) {
                if (mn.equals("MOV")) {
                    Src d = decodeSrc(ins, 0);
                    if ("mem".equals(d.kind) && "EBP".equals(d.baseReg) && !d.hasIndex && d.disp == curSlot) {
                        Src s2 = decodeSrc(ins, 1);
                        if ("reg".equals(s2.kind)) {
                            step(t, "[EBP" + hx(curSlot) + "]=" + s2.baseReg);
                            cur = s2.baseReg; curSlot = Long.MIN_VALUE;
                            ins = ins.getPrevious();
                            continue;
                        }
                        step(t, "[EBP" + hx(curSlot) + "]=?");
                        t.term = "LOCALSTORE" + hx(curSlot);
                        return t;
                    }
                }
                ins = ins.getPrevious();
                continue;
            }

            if (ft != null && ft.isCall()) {
                // EAX/ECX/EDX are caller-saved -- a value there cannot predate the call.
                if (cur.equals("EAX")) {
                    Address[] fl = ins.getFlows();
                    step(t, cur + "=RET");
                    boolean dir = fl != null && fl.length == 1 && !ft.isComputed();
                    t.term = "RETVAL:" + (dir ? hx(fl[0]) : "?") + "@" + hx(ins.getAddress());
                    return t;
                }
                if (cur.equals("ECX") || cur.equals("EDX")) { t.term = "CROSSCALL"; return t; }
                ins = ins.getPrevious();
                continue;
            }

            if (!writes(ins, cur)) { ins = ins.getPrevious(); continue; }

            if (mn.equals("MOV")) {
                Src s = decodeSrc(ins, 1);
                if ("reg".equals(s.kind)) {
                    step(t, cur + "=" + s.baseReg);
                    cur = s.baseReg;
                    ins = ins.getPrevious();
                    continue;
                }
                if ("imm".equals(s.kind)) {
                    step(t, cur + "=#" + hx(s.value));
                    t.term = "IMM:" + hx(s.value);
                    return t;
                }
                if ("absmem".equals(s.kind)) {
                    step(t, cur + "=[" + hx(s.value) + "]");
                    t.term = "GLOBAL:" + hx(s.value);
                    return t;
                }
                if ("mem".equals(s.kind)) {
                    step(t, cur + "=[" + s.baseReg + (s.hasIndex ? "+idx" : "") + "+" + hx(s.disp) + "]");
                    if (!t.vt && wantVT && s.disp == 0 && !s.hasIndex) {  // *(obj+0) == BBClass pointer
                        t.vt = true;
                        cur = s.baseReg;
                        ins = ins.getPrevious();
                        continue;
                    }
                    if (s.baseReg.equals("EBP") && !s.hasIndex) {
                        if (s.disp >= 8) { t.term = "PARAM+" + hx(s.disp); return t; }
                        // a local: keep going and find the store that defined the slot
                        t.term = "LOCAL" + hx(s.disp);
                        curSlot = s.disp;
                        ins = ins.getPrevious();
                        continue;
                    }
                    if (s.baseReg.equals("ESP")) { t.term = "STACK+" + hx(s.disp); return t; }
                    // field load, or BBArray element load ([base + idx*4 + 0x18]);
                    // either way keep tracing the object it came from
                    cur = s.baseReg;
                    ins = ins.getPrevious();
                    continue;
                }
                t.term = "GIVEUP:MOVSRC";
                return t;
            }

            if (mn.equals("LEA")) {
                Src s = decodeSrc(ins, 1);
                step(t, cur + "=&[" + (s.baseReg == null ? "" : s.baseReg + "+") + hx(s.kind.equals("mem") ? s.disp : s.value) + "]");
                t.term = "LEA";
                return t;
            }
            if (mn.equals("POP")) { step(t, cur + "=POP"); t.term = "POP"; return t; }
            t.term = "GIVEUP:" + mn;
            return t;
        }
        if (steps >= MAX_BACK_STEPS) t.term = "GIVEUP:depth";
        return t;
    }

    /**
     * Recover the immediate-valued arguments of a cdecl call by walking backwards over
     * the PUSH sequence. `add esp,N` encountered on the way back is the cleanup of an
     * inner call, so the next N/4 pushes belong to that inner call and are skipped.
     * Returns arg index -> hex immediate (null where the arg was not an immediate).
     * This is what identifies bbObjectNew(BBClass*) / bbObjectDowncast(obj,BBClass*) sites.
     */
    private String[] recoverImmArgs(Function f, Instruction call, int maxArgs) {
        String[] out = new String[maxArgs];
        int skip = 0, k = 0, steps = 0;
        Instruction ins = call.getPrevious();
        while (ins != null && steps < 60 && k < maxArgs) {
            if (!f.getBody().contains(ins.getAddress())) break;
            steps++;
            String mn = ins.getMnemonicString().toUpperCase(Locale.ROOT);
            if (mn.equals("ADD") || mn.equals("SUB")) {
                Register r0 = ins.getRegister(0);
                if (r0 != null && "ESP".equals(regKey(r0))) {
                    Src s = decodeSrc(ins, 1);
                    if ("imm".equals(s.kind) && s.value > 0) {
                        if (mn.equals("ADD")) skip += (int) (s.value / 4);
                        else break;   // sub esp,N -> start of an argument area we cannot follow
                    }
                }
            } else if (mn.equals("PUSH")) {
                if (skip > 0) { skip--; }
                else {
                    Src s = decodeSrc(ins, 0);
                    out[k] = "imm".equals(s.kind) ? hx(s.value) : null;
                    k++;
                }
            }
            ins = ins.getPrevious();
        }
        return out;
    }

    // ---- main -------------------------------------------------------------

    public void run() throws Exception {
        String[] args = getScriptArgs();
        File outDir = new File(args.length > 0 && !args[0].isEmpty() ? args[0] : "extracted");
        outDir.mkdirs();

        PrintWriter fw = new PrintWriter(new File(outDir, "callgraph_functions.tsv"), "UTF-8");
        PrintWriter dw = new PrintWriter(new File(outDir, "callgraph_direct.tsv"), "UTF-8");
        PrintWriter iw = new PrintWriter(new File(outDir, "callgraph_indirect.tsv"), "UTF-8");
        PrintWriter gw = new PrintWriter(new File(outDir, "callgraph_globalstores.tsv"), "UTF-8");
        fw.println("addr\tname\tsection\tsize\tninsn\tndirect\tnindirect");
        dw.println("caller\tsite\tcallee\tkind");
        iw.println("caller\tsite\tform\tbase_reg\tslot\tvt\tcleanup\tterm\tchain\traw");
        gw.println("caller\tsite\tglobal\tsrc\tterm\tchain");
        PrintWriter aw = new PrintWriter(new File(outDir, "callgraph_callargs.tsv"), "UTF-8");
        aw.println("site\tcallee\targ0\targ1\targ2\targ3");

        Listing listing = currentProgram.getListing();
        FunctionIterator fit = currentProgram.getFunctionManager().getFunctions(true);
        int nf = 0, nd = 0, ni = 0;

        while (fit.hasNext() && !monitor.isCancelled()) {
            Function f = fit.next();
            Address fa = f.getEntryPoint();
            int ninsn = 0, ndir = 0, nind = 0;

            InstructionIterator iit = listing.getInstructions(f.getBody(), true);
            while (iit.hasNext()) {
                Instruction ins = iit.next();
                ninsn++;
                FlowType ft = ins.getFlowType();
                if (ft == null) continue;

                // ---- store to an absolute address: types a module-level Global ----
                if (ins.getMnemonicString().equalsIgnoreCase("MOV") && ins.getNumOperands() == 2) {
                    Src d0 = decodeSrc(ins, 0);
                    if ("absmem".equals(d0.kind)) {
                        Src s1 = decodeSrc(ins, 1);
                        if ("reg".equals(s1.kind)) {
                            Trace gt = traceReceiver(f, ins, s1.baseReg, false);
                            gw.printf("%s\t%s\t%s\t%s\t%s\t%s%n", hx(fa), hx(ins.getAddress()),
                                    hx(d0.value), s1.baseReg, gt.term, gt.chain.toString());
                        } else if ("imm".equals(s1.kind)) {
                            gw.printf("%s\t%s\t%s\t%s\tIMM:%s\t%n", hx(fa), hx(ins.getAddress()),
                                    hx(d0.value), "#", hx(s1.value));
                        }
                    }
                }

                boolean isCall = ft.isCall();
                boolean isTail = false;
                if (!isCall && ft.isJump() && !ft.isConditional()) {
                    Address[] fl = ins.getFlows();
                    if (fl != null && fl.length == 1 && !f.getBody().contains(fl[0])
                            && getFunctionAt(fl[0]) != null) isTail = true;
                }
                if (!isCall && !isTail) continue;

                Address[] flows = ins.getFlows();
                if (flows != null && flows.length >= 1 && !ft.isComputed()) {
                    for (Address tgt : flows) {
                        dw.printf("%s\t%s\t%s\t%s%n", hx(fa), hx(ins.getAddress()), hx(tgt),
                                isTail ? "tail" : "call");
                        nd++; ndir++;
                    }
                    if (isCall) {
                        String[] ia = recoverImmArgs(f, ins, 4);
                        if (ia[0] != null || ia[1] != null || ia[2] != null || ia[3] != null) {
                            aw.printf("%s\t%s\t%s\t%s\t%s\t%s%n", hx(ins.getAddress()), hx(flows[0]),
                                    ia[0] == null ? "" : ia[0], ia[1] == null ? "" : ia[1],
                                    ia[2] == null ? "" : ia[2], ia[3] == null ? "" : ia[3]);
                        }
                    }
                    continue;
                }
                if (!isCall) continue;

                String raw;
                try { raw = ins.getDefaultOperandRepresentation(0); }
                catch (Exception e) { raw = "?"; }
                if (raw == null) raw = "?";

                Src s = decodeSrc(ins, 0);
                String form, baseReg = "";
                long slot = 0;
                boolean haveSlot = false;
                if ("reg".equals(s.kind))          { form = "reg"; baseReg = s.baseReg; }
                else if ("mem".equals(s.kind))     { form = s.hasIndex ? "mem_idx" : "mem";
                                                     baseReg = s.baseReg; slot = s.disp;
                                                     haveSlot = !s.hasIndex; }
                else if ("absmem".equals(s.kind))  { form = "abs"; slot = s.value; haveSlot = true; }
                else                               { form = s.kind; }

                // cdecl stack cleanup immediately after the call gives the argument
                // count in dwords -- a hard arity constraint on the callee.
                int cleanup = -1;
                Instruction nx = ins.getNext();
                if (nx != null && f.getBody().contains(nx.getAddress())) {
                    String nmn = nx.getMnemonicString().toUpperCase(Locale.ROOT);
                    Register nr = nx.getRegister(0);
                    if (nmn.equals("ADD") && nr != null && "ESP".equals(regKey(nr))) {
                        Src cs = decodeSrc(nx, 1);
                        if ("imm".equals(cs.kind)) cleanup = (int) cs.value;
                    } else if (!nmn.equals("ADD") && !nmn.equals("SUB")) {
                        cleanup = 0;      // no cleanup emitted -> zero-dword argument list
                    }
                }

                Trace t = baseReg.isEmpty() ? new Trace() : traceReceiver(f, ins, baseReg, true);
                iw.printf("%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s%n",
                        hx(fa), hx(ins.getAddress()), form, baseReg,
                        haveSlot ? hx(slot) : "", t.vt ? 1 : 0, cleanup, t.term,
                        t.chain.toString(), raw.replace('\t', ' '));
                ni++; nind++;
            }

            fw.printf("%s\t%s\t%s\t%d\t%d\t%d\t%d%n", hx(fa), f.getName(), sectionOf(fa),
                    (int) f.getBody().getNumAddresses(), ninsn, ndir, nind);
            nf++;
        }

        fw.close(); dw.close(); iw.close(); gw.close(); aw.close();
        println("NSS5CallGraph: " + nf + " functions, " + nd + " direct edges, "
                + ni + " indirect call sites -> " + outDir.getAbsolutePath());
    }
}

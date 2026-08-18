// NSS5ExportList -- second half of the one-pass decompilation export.
//
// NSS5ExportAll.java exports the 2,600 slots that appear in vtable_map.tsv (done:
// 2,600/2,600 OK). It cannot export the 992 `code` functions that belong to no
// Type -- module-level Functions, the program's top-level body, and compiler
// helpers -- because they have no vtable_map row. This script takes a plain list
// of addresses instead, so that gap closes in ONE more locked Ghidra session.
//
// Generate the list first (no Ghidra needed):
//     python scripts/decomp_index.py --todo
//   -> extracted/decomp_todo.txt
//
// Then, in the single session that is allowed to hold the project lock:
//     tools/ghidra_12.1.2_PUBLIC/support/analyzeHeadless.bat ghidra-project NSS5 \
//       -process NSS5.exe -noanalysis -readOnly \
//       -scriptPath scripts/ghidra_scripts \
//       -postScript NSS5ExportList.java extracted/decomp_todo.txt extracted/decomp
//
// Output filenames match the existing convention closely enough to share a
// directory: Fn_<va>@<va>.c, with the same "// VA=" header the annotator reads.
// Existing files are skipped, so an interrupted run resumes where it stopped.
//@category NSS5
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.mem.MemoryBlock;

public class NSS5ExportList extends GhidraScript {

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) {
            println("usage: NSS5ExportList <addrListFile> <outDir> [timeoutSec]");
            return;
        }
        File listFile = new File(args[0]);
        File outDir = new File(args[1]);
        int timeout = args.length > 2 ? Integer.parseInt(args[2]) : 90;
        if (!outDir.exists()) outDir.mkdirs();

        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);

        PrintWriter idx = new PrintWriter(new File(outDir, "_index_unattributed.tsv"), "UTF-8");
        idx.println("va\tname\tsection\tsize\tfile\tdecomp_status\tbody_lines");

        BufferedReader r = new BufferedReader(new FileReader(listFile));
        String line;
        int ok = 0, fail = 0, cached = 0, n = 0;

        while ((line = r.readLine()) != null && !monitor.isCancelled()) {
            line = line.trim();
            if (line.isEmpty() || line.startsWith("#")) continue;
            String tok = line.split("[\\s\\t]+")[0];
            if (tok.startsWith("0x") || tok.startsWith("0X")) tok = tok.substring(2);
            n++;
            if (n % 200 == 0) println("[NSS5ExportList] " + n + " ...");

            String fname = "Fn_" + tok + "@" + tok + ".c";
            File out = new File(outDir, fname);
            if (out.exists() && out.length() > 0) {
                cached++;
                continue;
            }

            String status = "?";
            int bodyLines = 0;
            String name = "?", sect = "?";
            long size = 0;
            try {
                Address ad = currentProgram.getAddressFactory().getAddress(tok);
                Function fn = getFunctionAt(ad);
                if (fn == null) fn = createFunction(ad, null);
                MemoryBlock blk = currentProgram.getMemory().getBlock(ad);
                sect = (blk == null) ? "?" : blk.getName();
                if (fn == null) {
                    status = "NOFUNC";
                    fail++;
                } else {
                    name = fn.getName();
                    size = fn.getBody().getNumAddresses();
                    DecompileResults res = d.decompileFunction(fn, timeout, monitor);
                    if (res.decompileCompleted() && res.getDecompiledFunction() != null) {
                        String c = res.getDecompiledFunction().getC();
                        bodyLines = c.split("\n", -1).length;
                        PrintWriter w = new PrintWriter(out, "UTF-8");
                        // Deliberately NO "// TYPE=" line: these functions belong to
                        // no Type and we do NOT have their original names. Per
                        // methodology sec 7.3 they are named Fn_<VA> on purpose --
                        // a known unknown, not a fabricated name.
                        w.println("// TYPE=");
                        w.println("// KIND=FreeFunction");
                        w.println("// NAME=Fn_" + tok.toUpperCase());
                        w.println("// SIG=UNKNOWN");
                        w.println("// SLOT=");
                        w.println("// VA=0x" + tok);
                        w.println("// NOTE=no recovered name; see methodology sec 7.3");
                        w.println();
                        w.print(c);
                        w.close();
                        status = "OK";
                        ok++;
                    } else {
                        status = "DECOMPFAIL";
                        fail++;
                    }
                }
            } catch (Exception ex) {
                status = "ERR:" + ex.getClass().getSimpleName();
                fail++;
            }
            idx.println("0x" + tok + "\t" + name + "\t" + sect + "\t" + size + "\t"
                    + fname + "\t" + status + "\t" + bodyLines);
        }
        r.close();
        idx.close();
        d.dispose();
        println("[NSS5ExportList] total=" + n + " ok=" + ok + " cached=" + cached
                + " fail=" + fail);
    }
}

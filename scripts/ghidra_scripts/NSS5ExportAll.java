// Bulk-export decompilation for every address listed in a TSV, one .c file per function.
// Run ONCE; afterwards any number of passes can work on the exported files in parallel
// without contending for Ghidra's exclusive project lock.
//@category NSS5

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;

public class NSS5ExportAll extends GhidraScript {
    /**
     * Repo root, resolved at run time so this script works in any clone.
     * Set NSS5_REPO in the environment, or pass the repo path as the first
     * script argument:
     *     analyzeHeadless <project> NSS5 -scriptPath scripts/ghidra_scripts      *         -postScript NSS5ExportAll <path-to-repo>
     */
    private String repoRoot() {
        String[] a = getScriptArgs();
        if (a != null && a.length > 0 && a[0] != null && !a[0].isEmpty()) return a[0];
        String env = System.getenv("NSS5_REPO");
        if (env != null && !env.isEmpty()) return env;
        return System.getProperty("user.dir");
    }


    private String MAP =
            repoRoot() + java.io.File.separator + "extracted" + java.io.File.separator + "vtable_map.tsv";
    private String OUT =
            repoRoot() + java.io.File.separator + "extracted" + java.io.File.separator + "decomp";

    @Override
    public void run() throws Exception {
        File outDir = new File(OUT);
        if (!outDir.exists()) outDir.mkdirs();

        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);

        PrintWriter idx = new PrintWriter(new File(outDir, "_index.tsv"), "UTF-8");
        idx.println("type\tkind\tname\tsig\tslot\tva\tfile\tdecomp_status\tbody_lines");

        BufferedReader r = new BufferedReader(new FileReader(MAP));
        String line = r.readLine();                       // header
        int ok = 0, fail = 0, n = 0;

        while ((line = r.readLine()) != null && !monitor.isCancelled()) {
            String[] f = line.split("\t", -1);
            if (f.length < 6) continue;
            String type = f[0], kind = f[1], name = f[2], sig = f[3], slot = f[4], va = f[5];
            if (va == null || !va.startsWith("0x")) continue;

            n++;
            if (n % 200 == 0) println("[NSS5ExportAll] " + n + " ...");

            String fname = type + "." + name + "@" + va.substring(2) + ".c";
            fname = fname.replaceAll("[^A-Za-z0-9._@-]", "_");

            // Skip anything already exported: lets this be re-run incrementally after the
            // vtable map is regenerated, without disturbing files other processes are reading.
            File target = new File(outDir, fname);
            if (target.exists()) {
                idx.println(type + "\t" + kind + "\t" + name + "\t" + sig + "\t" + slot + "\t"
                        + va + "\t" + fname + "\tSKIP_EXISTS\t0");
                ok++;
                continue;
            }

            String status;
            int bodyLines = 0;
            try {
                Address ad = currentProgram.getAddressFactory().getAddress(va);
                Function fn = getFunctionAt(ad);
                if (fn == null) fn = createFunction(ad, null);
                if (fn == null) {
                    status = "NOFUNC";
                    fail++;
                } else {
                    DecompileResults res = d.decompileFunction(fn, 90, monitor);
                    if (res.decompileCompleted()) {
                        String c = res.getDecompiledFunction().getC();
                        bodyLines = c.split("\n", -1).length;
                        PrintWriter w = new PrintWriter(new File(outDir, fname), "UTF-8");
                        // header comment carries the metadata the annotator needs
                        w.println("// TYPE=" + type);
                        w.println("// KIND=" + kind);      // Method (has Self) | Function (no Self)
                        w.println("// NAME=" + name);
                        w.println("// SIG=" + sig);
                        w.println("// SLOT=" + slot);
                        w.println("// VA=" + va);
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
            idx.println(type + "\t" + kind + "\t" + name + "\t" + sig + "\t" + slot + "\t"
                    + va + "\t" + fname + "\t" + status + "\t" + bodyLines);
        }
        r.close();
        idx.close();
        d.dispose();
        println("[NSS5ExportAll] total=" + n + " ok=" + ok + " fail=" + fail);
        println("[NSS5ExportAll] output: " + OUT);
    }
}

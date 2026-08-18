//Decompile a list of addresses given via -scriptArgs addr1,addr2,...
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class NSS5Decompile extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);
        for (String a : args) {
            for (String one : a.split(",")) {
                one = one.trim();
                if (one.isEmpty()) continue;
                Address ad = currentProgram.getAddressFactory().getAddress(one);
                Function f = getFunctionAt(ad);
                if (f == null) f = createFunction(ad, null);
                if (f == null) { println("### NOFUNC " + one); continue; }
                DecompileResults r = d.decompileFunction(f, 60, monitor);
                println("### BEGIN " + one + " " + f.getName());
                if (r.decompileCompleted()) println(r.getDecompiledFunction().getC());
                else println("### FAILED " + r.getErrorMessage());
                println("### END " + one);
            }
        }
        d.dispose();
    }
}

//Find references to distinctive spill()-related string literals and decompile containing function(s).
//@category NSS5
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Data;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.listing.DataIterator;
import java.util.HashSet;
import java.util.Set;

public class NSS5FindSpill extends GhidraScript {
    public void run() throws Exception {
        String[] needles = new String[] {
            "Unable to find spill candidate",
            "trouble finding spill candidate"
        };

        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);

        Listing listing = currentProgram.getListing();

        for (String needle : needles) {
            println("### SEARCHING FOR: " + needle);
            Set<Address> stringAddrs = new HashSet<>();
            // Search defined data for strings containing the needle
            DataIterator dataIter = listing.getDefinedData(true);
            while (dataIter.hasNext()) {
                Data data = dataIter.next();
                if (data == null) continue;
                if (!data.hasStringValue()) continue;
                Object val = data.getValue();
                if (val != null && val.toString().contains(needle)) {
                    stringAddrs.add(data.getAddress());
                    println("  found string data at " + data.getAddress() + " = " + val.toString());
                }
            }
            if (stringAddrs.isEmpty()) {
                println("  no defined string data matched; doing raw byte scan");
                // raw scan of memory for ascii bytes
                byte[] pattern = needle.getBytes("US-ASCII");
                Memory mem = currentProgram.getMemory();
                Address start = mem.getMinAddress();
                Address found = mem.findBytes(start, pattern, null, true, monitor);
                while (found != null) {
                    println("  raw match at " + found);
                    stringAddrs.add(found);
                    Address next;
                    try {
                        next = found.add(1);
                    } catch (Exception e) { break; }
                    if (next.compareTo(mem.getMaxAddress()) >= 0) break;
                    found = mem.findBytes(next, pattern, null, true, monitor);
                }
            }

            for (Address sAddr : stringAddrs) {
                println("  -- references to " + sAddr + " --");
                ReferenceIterator refIter = currentProgram.getReferenceManager().getReferencesTo(sAddr);
                boolean any = false;
                while (refIter.hasNext()) {
                    Reference ref = refIter.next();
                    any = true;
                    Address fromAddr = ref.getFromAddress();
                    Function f = getFunctionContaining(fromAddr);
                    if (f == null) {
                        println("    ref from " + fromAddr + " (no containing function)");
                        continue;
                    }
                    println("    ref from " + fromAddr + " in function " + f.getName() + " @ " + f.getEntryPoint());
                }
                if (!any) {
                    println("    (no references found to this address -- may be PIC-loaded without a direct xref; will need manual disasm)");
                }
            }
        }
        d.dispose();
    }
}

//NSS5 seeding pass: harvest anchors from strings and label the binary.
//@category NSS5
//@author nss5-forge

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.data.StringDataInstance;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.SourceType;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class NSS5Seed extends GhidraScript {
    /**
     * Repo root, resolved at run time so this script works in any clone.
     * Set NSS5_REPO in the environment, or pass the repo path as the first
     * script argument:
     *     analyzeHeadless <project> NSS5 -scriptPath scripts/ghidra_scripts      *         -postScript NSS5Seed <path-to-repo>
     */
    private String repoRoot() {
        String[] a = getScriptArgs();
        if (a != null && a.length > 0 && a[0] != null && !a[0].isEmpty()) return a[0];
        String env = System.getenv("NSS5_REPO");
        if (env != null && !env.isEmpty()) return env;
        return System.getProperty("user.dir");
    }


    private String OUT_DIR =
            repoRoot() + java.io.File.separator + "extracted" + java.io.File.separator + "ghidra";

    // Debug labels the developer left in: "MatchLoop", "CreateBall:", "KeeperDive:" ...
    private static final Pattern DEBUG_LABEL = Pattern.compile("^([A-Za-z][A-Za-z0-9_]{2,40}):$");
    private static final Pattern IDENT = Pattern.compile("^[A-Za-z][A-Za-z0-9_]{2,40}$");

    // Engine.ini keys - each is a front door into the subsystem it controls.
    private static final String[] INI_KEYS = {
        "replaylength","gamesecond","limitscrollx","limitscrolly1","limitscrolly2",
        "pitchscale","sideline","goalline","goalpost","postwidth","crossbar","netline",
        "penboxside","penboxd","penspoty","sixyardside",
        "ballradius","fricAir","fricGrass","gravity","bounce",
        "kickpow_pass","kickheight_pass","kickpow_shoot","kickheight_shoot",
        "kickpow_lob","kickheight_lob","kickpow_head","kickheight_head",
        "kickdistratio_shoot","kickdistratio_lob","kickdistratio_pass","kickdistratio_cross",
        "aftertouchtime","curlinc","curlmax",
        "acceleration","keeperaccel","walkingspeed","joggingspeed","playerfriction",
        "slidevelocity","slidefriction","touchdist_ball","jumpspotradius","playerheight",
        "playerradius","passcheckradius","turningcircle","powerbarspeed","highlightpass",
        "fixkick","jumpvelocity","shotpowerparry","shotdistanceparry","injuryfrequency",
        "energydrain","framelength",
        "spritename_player","spritewidth_player","spriteheight_player","spritecount_player",
        "handlex_player","handley_player","spritescale","jumpframes","fallframes","holdballframes",
        "formationheight","formationwidth","withoutballformationwidth","wideplayerpush",
        "formationxshift","withoutballformationxshift","formationyshift","formationdepth",
        "ymarginmultiply","camerax1","cameray1","camerax2","cameray2",
        "ratingperminute","ratingpasses","ratingdefensiveheaders","ratingshots","ratinggoals",
        "ratingassists","ratingsaves","ratingtackles","ratingfouls","ratingyellows","ratingreds"
    };

    // CSV column names - xrefs to these land in the data loaders and reveal struct field order.
    private static final String[] CSV_COLUMNS = {
        "shortname","tla","strength","rivalclub1","rivalclub2","rivalclub3",
        "stadiumname","stadiumcapacity","stadiumlongitude","stadiumlatitude",
        "homestyle","homekitshirtcol1","homekitshirtcol2","homekitshortscol","homekitsockscol",
        "awaystyle","awaykitshirtcol1","thirdstyle","keeperstyle",
        "formation","nickname","nationid","leagueid","continentalcompid","bteamof",
        "nationality","continent","climate","primaryskin","secondaryskin",
        "locale","level","based","comptype","startyear","startweek","duration","recurring",
        "primarymatchday","secondarymatchday","groups","rounds","legs","townregion",
        "compstatus","minstrength","maxstrength",
        "parentid","place","promotiontoid",
        "teamid","teamname","teamstrength","played","drawn","lost","goalsf","goalsa","points",
        "continentality","federationname","federationshortname",
        "name","nation","capacity","longitude","latitude"
    };

    private PrintWriter open(String name) throws Exception {
        File d = new File(OUT_DIR);
        if (!d.exists()) d.mkdirs();
        return new PrintWriter(new File(d, name), "UTF-8");
    }

    private static String clean(String s) {
        if (s == null) return "";
        return s.replace("\t", "\\t").replace("\r", "\\r").replace("\n", "\\n");
    }

    private String blockOf(Address a) {
        MemoryBlock b = currentProgram.getMemory().getBlock(a);
        return b == null ? "?" : b.getName();
    }

    @Override
    public void run() throws Exception {

        Listing listing = currentProgram.getListing();

        // ---------------------------------------------------------------
        // 1. Collect every defined string with its address.
        // ---------------------------------------------------------------
        println("[NSS5Seed] collecting strings...");
        List<Address> strAddrs = new ArrayList<>();
        List<String> strVals = new ArrayList<>();
        Map<String, Address> byValue = new HashMap<>();

        DataIterator di = listing.getDefinedData(true);
        while (di.hasNext() && !monitor.isCancelled()) {
            Data d = di.next();
            if (!d.hasStringValue()) continue;
            StringDataInstance sdi = StringDataInstance.getStringDataInstance(d);
            if (sdi == null) continue;
            String v = sdi.getStringValue();
            if (v == null || v.length() < 2) continue;
            strAddrs.add(d.getAddress());
            strVals.add(v);
            if (!byValue.containsKey(v)) byValue.put(v, d.getAddress());
        }
        println("[NSS5Seed] strings found: " + strVals.size());

        // ---------------------------------------------------------------
        // 2. Dump every string with the functions that reference it.
        // ---------------------------------------------------------------
        PrintWriter wStr = open("strings_with_xrefs.tsv");
        wStr.println("string_addr\tblock\tstring\tref_count\treferencing_functions");
        for (int i = 0; i < strVals.size(); i++) {
            Address a = strAddrs.get(i);
            Set<String> funcs = new HashSet<>();
            int n = 0;
            ReferenceIterator ri = currentProgram.getReferenceManager().getReferencesTo(a);
            while (ri.hasNext()) {
                Reference r = ri.next();
                n++;
                Function f = getFunctionContaining(r.getFromAddress());
                if (f != null) funcs.add(f.getEntryPoint().toString() + "=" + f.getName());
            }
            wStr.println(a + "\t" + blockOf(a) + "\t" + clean(strVals.get(i)) + "\t" + n
                    + "\t" + String.join(";", funcs));
        }
        wStr.close();
        println("[NSS5Seed] wrote strings_with_xrefs.tsv");

        // ---------------------------------------------------------------
        // 3. Rename functions from the developer's own debug labels.
        //    A label like "KeeperDive:" is printed BY the function it names.
        // ---------------------------------------------------------------
        PrintWriter wLbl = open("debug_label_renames.tsv");
        wLbl.println("label\tstring_addr\tfunction_addr\told_name\tnew_name\tstatus");
        int renamed = 0;
        Set<String> usedNames = new HashSet<>();

        for (int i = 0; i < strVals.size(); i++) {
            String v = strVals.get(i);
            Matcher m = DEBUG_LABEL.matcher(v);
            String base;
            if (m.matches()) {
                base = m.group(1);
            } else if (IDENT.matcher(v).matches() && isKnownBareLabel(v)) {
                base = v;
            } else {
                continue;
            }

            Address a = strAddrs.get(i);
            ReferenceIterator ri = currentProgram.getReferenceManager().getReferencesTo(a);
            List<Function> targets = new ArrayList<>();
            while (ri.hasNext()) {
                Function f = getFunctionContaining(ri.next().getFromAddress());
                if (f != null && !targets.contains(f)) targets.add(f);
            }

            if (targets.isEmpty()) {
                wLbl.println(v + "\t" + a + "\t-\t-\t-\tNO_XREF");
                continue;
            }
            // Only rename when exactly one function prints the label - otherwise it is ambiguous
            // and a wrong name is worse than no name.
            if (targets.size() > 1) {
                StringBuilder sb = new StringBuilder();
                for (Function f : targets) sb.append(f.getEntryPoint()).append(",");
                wLbl.println(v + "\t" + a + "\t" + sb + "\t-\t-\tAMBIGUOUS_" + targets.size());
                continue;
            }

            Function f = targets.get(0);
            String old = f.getName();
            String newName = "nss_" + base;
            int suffix = 2;
            while (usedNames.contains(newName)) newName = "nss_" + base + "_" + (suffix++);

            if (old.startsWith("FUN_") || old.startsWith("thunk_FUN_")) {
                f.setName(newName, SourceType.USER_DEFINED);
                usedNames.add(newName);
                renamed++;
                wLbl.println(v + "\t" + a + "\t" + f.getEntryPoint() + "\t" + old + "\t" + newName + "\tRENAMED");
            } else {
                wLbl.println(v + "\t" + a + "\t" + f.getEntryPoint() + "\t" + old + "\t" + newName + "\tALREADY_NAMED");
            }
        }
        wLbl.close();
        println("[NSS5Seed] functions renamed from debug labels: " + renamed);

        // ---------------------------------------------------------------
        // 4. Anchor reports: Engine.ini keys and CSV column names.
        // ---------------------------------------------------------------
        writeAnchorReport("anchors_engine_ini.tsv", INI_KEYS, byValue);
        writeAnchorReport("anchors_csv_columns.tsv", CSV_COLUMNS, byValue);

        // ---------------------------------------------------------------
        // 5. Full function inventory.
        // ---------------------------------------------------------------
        PrintWriter wFun = open("function_inventory.tsv");
        wFun.println("addr\tname\tblock\tsize\tparam_count\tcalling_conv\tcalled_by_count\tcalls_count\thas_custom_name");
        FunctionIterator fi = currentProgram.getFunctionManager().getFunctions(true);
        int total = 0;
        while (fi.hasNext() && !monitor.isCancelled()) {
            Function f = fi.next();
            total++;
            int callers = f.getCallingFunctions(monitor).size();
            int callees = f.getCalledFunctions(monitor).size();
            boolean custom = !f.getName().startsWith("FUN_") && !f.getName().startsWith("thunk_FUN_");
            wFun.println(f.getEntryPoint() + "\t" + f.getName() + "\t" + blockOf(f.getEntryPoint())
                    + "\t" + f.getBody().getNumAddresses()
                    + "\t" + f.getParameterCount()
                    + "\t" + f.getCallingConventionName()
                    + "\t" + callers + "\t" + callees + "\t" + custom);
        }
        wFun.close();
        println("[NSS5Seed] total functions: " + total);

        // ---------------------------------------------------------------
        // 6. Summary.
        // ---------------------------------------------------------------
        PrintWriter wSum = open("seed_summary.txt");
        wSum.println("NSS5 Ghidra seeding pass");
        wSum.println("program        : " + currentProgram.getName());
        wSum.println("image base     : " + currentProgram.getImageBase());
        wSum.println("language       : " + currentProgram.getLanguageID());
        wSum.println("compiler spec  : " + currentProgram.getCompilerSpec().getCompilerSpecID());
        wSum.println("total functions: " + total);
        wSum.println("total strings  : " + strVals.size());
        wSum.println("renamed by label: " + renamed);
        wSum.close();

        println("[NSS5Seed] DONE. Output in " + OUT_DIR);
    }

    // Bare (colon-less) labels we independently confirmed are function names.
    private boolean isKnownBareLabel(String s) {
        switch (s) {
            case "MatchLoop":
            case "PlayFixtures":
            case "UpdateHealth":
            case "UpdateSelectedForMatch":
            case "UpdateOffset":
            case "UpdateReplayTable":
            case "UpdateTitlePanel":
            case "UpdateFaces":
            case "UpdateInterestedClubs":
            case "UpdateStakeCurrency":
            case "UpdateDesiredCombos":
            case "UpdateOfferButtons":
            case "UpdateClubsInterestedLabel":
                return true;
            default:
                return false;
        }
    }

    private void writeAnchorReport(String file, String[] keys, Map<String, Address> byValue) throws Exception {
        PrintWriter w = open(file);
        w.println("key\tstring_addr\tref_count\treferencing_functions");
        int hits = 0;
        for (String k : keys) {
            Address a = byValue.get(k);
            if (a == null) { w.println(k + "\t-\t0\tNOT_FOUND"); continue; }
            Set<String> funcs = new HashSet<>();
            int n = 0;
            ReferenceIterator ri = currentProgram.getReferenceManager().getReferencesTo(a);
            while (ri.hasNext()) {
                Reference r = ri.next();
                n++;
                Function f = getFunctionContaining(r.getFromAddress());
                if (f != null) funcs.add(f.getEntryPoint() + "=" + f.getName());
            }
            if (n > 0) hits++;
            w.println(k + "\t" + a + "\t" + n + "\t" + String.join(";", funcs));
        }
        w.close();
        println("[NSS5Seed] wrote " + file + " (" + hits + "/" + keys.length + " keys had xrefs)");
    }
}

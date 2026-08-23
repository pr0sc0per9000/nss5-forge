"""The window for nss5_setup.py.

Separate module so the installer still runs where tkinter is missing. nss5_setup falls
back to text mode on ImportError, which it cannot do if the import sits at its own top.
nss5_setup passes itself into run(), so neither module imports the other and there is no
cycle.

Tkinter only, no third-party packages, matching the project's rule that the standard
library is all of it and there is nothing to pip install.

THE WORK RUNS ON A THREAD, AND THE THREAD TOUCHES NO WIDGET.
Tk redraws nothing while a callback runs, so building on the UI thread gives a frozen
white rectangle for several minutes. So slow work goes to a worker. But Tk is also not
thread safe: calling .configure() from that worker is a Tcl call from the wrong thread,
which corrupts or crashes the interpreter at random. Both rules together mean the worker
may only put messages on a queue, and the UI thread drains that queue on a timer and is
the only thing that ever touches a widget. Every message is (kind, payload).
"""

import queue
import threading

import tkinter as tk
from tkinter import filedialog, ttk

PAD = 12


class App(object):
    def __init__(self, root, core, steam_path=None):
        self.root = root
        self.core = core
        self.steam_path = steam_path
        self.game_dir = None
        self.q = queue.Queue()
        self.busy = False

        root.title("New Star Soccer 5 reconstruction")
        root.minsize(720, 520)

        head = tk.Frame(root)
        head.pack(fill="x", padx=PAD, pady=(PAD, 0))
        tk.Label(head, text="New Star Soccer 5 reconstruction",
                 font=("Segoe UI", 15, "bold")).pack(anchor="w")
        tk.Label(head, justify="left", wraplength=680, fg="#555",
                 text="This builds the game from your own copy. None of the game is "
                      "included here or downloaded. You need New Star Soccer 5 on "
                      "Steam.").pack(anchor="w", pady=(2, 0))

        # Where the game is installed. Only meaningful in the built executable; running
        # from source the repository is already the tree.
        self.install_var = tk.StringVar(value=core.DEFAULT_INSTALL_DIR)
        if core.FROZEN:
            row0 = tk.Frame(root)
            row0.pack(fill="x", padx=PAD, pady=(PAD, 0))
            tk.Label(row0, text="Install to:").pack(side="left")
            tk.Entry(row0, textvariable=self.install_var).pack(
                side="left", fill="x", expand=True, padx=(8, 8))
            tk.Button(row0, text="Change...", command=self.on_pick_install).pack(
                side="left")

        self.status = tk.Label(root, text="Ready.", anchor="w", font=("Segoe UI", 10))
        self.status.pack(fill="x", padx=PAD, pady=(PAD, 4))

        self.bar = ttk.Progressbar(root, mode="determinate", maximum=4)
        self.bar.pack(fill="x", padx=PAD)

        body = tk.Frame(root)
        body.pack(fill="both", expand=True, padx=PAD, pady=PAD)
        self.log = tk.Text(body, wrap="none", height=18, font=("Consolas", 9),
                           bg="#1e1e1e", fg="#d4d4d4", insertbackground="#d4d4d4")
        scroll = tk.Scrollbar(body, command=self.log.yview)
        self.log.configure(yscrollcommand=scroll.set, state="disabled")
        self.log.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")

        row = tk.Frame(root)
        row.pack(fill="x", padx=PAD, pady=(0, PAD))
        self.btn_check = tk.Button(row, text="Check my setup", width=16,
                                   command=self.on_check)
        self.btn_check.pack(side="left")
        self.btn_build = tk.Button(row, text="Install and build", width=16,
                                   command=self.on_build)
        self.btn_build.pack(side="left", padx=(8, 0))
        self.btn_browse = tk.Button(row, text="Choose folder...", width=16,
                                    command=self.on_browse)
        self.btn_browse.pack(side="left", padx=(8, 0))
        self.btn_play = tk.Button(row, text="Play", width=10, state="disabled",
                                  command=self.on_play)
        self.btn_play.pack(side="right")

        self.root.after(60, self.drain)
        self.log_line("Press 'Check my setup' to see what is found. It changes nothing.")

    # ------------------------------------------------- worker -> UI messages

    def log_line(self, text=""):
        self.q.put(("log", text))

    def set_status(self, text):
        self.q.put(("status", text))

    def set_bar(self, value):
        self.q.put(("bar", value))

    def enable_play(self):
        self.q.put(("play", None))

    def drain(self):
        """The only place a widget is touched. Runs on the UI thread, on a timer."""
        appended = False
        try:
            while True:
                kind, payload = self.q.get_nowait()
                if kind == "log":
                    self.log.configure(state="normal")
                    self.log.insert("end", payload + "\n")
                    self.log.configure(state="disabled")
                    appended = True
                elif kind == "status":
                    self.status.configure(text=payload)
                elif kind == "bar":
                    self.bar.configure(value=payload)
                elif kind == "play":
                    self.btn_play.configure(state="normal")
                elif kind == "idle":
                    self.busy = False
                    for b in (self.btn_check, self.btn_build, self.btn_browse):
                        b.configure(state="normal")
        except queue.Empty:
            pass
        if appended:
            self.log.see("end")
        self.root.after(60, self.drain)

    def in_worker(self, fn):
        if self.busy:
            return
        self.busy = True
        for b in (self.btn_check, self.btn_build, self.btn_browse):
            b.configure(state="disabled")

        def wrapped():
            try:
                fn()
            finally:
                self.q.put(("idle", None))
        threading.Thread(target=wrapped, daemon=True).start()

    def report(self, result):
        self.log_line("  " + result.summary)
        for line in (result.detail or "").splitlines():
            self.log_line("  " + line)
        if result.hint:
            self.log_line("")
            for line in result.hint.splitlines():
                self.log_line("  " + line)
        return result.ok

    # ---------------------------------------------------------------- actions

    def on_pick_install(self):
        """Pick the folder the game is installed into. The folder itself is created if
        it does not exist, so a player can name a new one in the dialog."""
        chosen = filedialog.askdirectory(title="Install New Star Soccer 5 where?",
                                         mustexist=False)
        if chosen:
            self.install_var.set(chosen)

    def apply_install_dir(self):
        """Called at the start of every action, so an edit typed into the box counts
        even when Change was never pressed."""
        return self.core.set_install_root(self.install_var.get())

    def on_browse(self):
        chosen = filedialog.askdirectory(title="Where is New Star Soccer 5?")
        if chosen:
            self.steam_path = chosen
            self.log_line("")
            self.log_line("Using: " + chosen)

    def diagnose(self):
        """Steps 1 to 3. Returns True when a build could start."""
        self.set_bar(0)
        target = self.apply_install_dir()
        if self.core.FROZEN:
            self.log_line("Installing to: " + target)

        self.log_line("")
        self.log_line("Finding your copy of the game")
        r = self.core.step_find(self.steam_path)
        if not self.report(r):
            return False
        self.game_dir = r.detail
        self.set_bar(1)

        self.log_line("")
        self.log_line("Checking it is the build this targets")
        ok_verify = self.report(self.core.step_verify(self.game_dir))
        self.set_bar(2)

        self.log_line("")
        self.log_line("Checking the toolchain")
        ok_tools = self.report(self.core.step_toolchain())
        self.set_bar(3)

        # A missing toolchain is not a reason to refuse to build: installing it is what
        # the build does first. Only a missing or wrong copy of the game stops us.
        self.ok_tools = ok_tools
        return ok_verify

    def on_check(self):
        def work():
            ok = self.diagnose()
            self.set_status("Ready to build." if ok else "Something needs fixing first.")
            self.log_line("")
            self.log_line("Checked only. Nothing was written and nothing was built.")
        self.in_worker(work)

    def on_build(self):
        def work():
            if not self.diagnose():
                self.set_status("Cannot build. See above.")
                return
            if not getattr(self, "ok_tools", False):
                self.set_status("Getting the toolchain. This takes a while.")
                self.log_line("")
                tc = self.core.step_get_toolchain(self.log_line)
                self.report(tc)
                if not tc.ok:
                    self.set_status("Could not get the toolchain.")
                    return
            self.set_status("Building. This takes a few minutes.")
            self.log_line("")
            self.log_line("-" * 58)
            r = self.core.step_build(self.game_dir, self.log_line)
            self.log_line("-" * 58)
            self.report(r)
            self.set_bar(4)
            if r.ok:
                self.set_status("Done. Press Play.")
                self.enable_play()
            else:
                self.set_status("Build failed.")
        self.in_worker(work)

    def on_play(self):
        """Always through play.py. It forces windowed mode in every Options.ini the game
        reads, because the game can otherwise come up in exclusive fullscreen holding the
        display and the input queue until the machine is power cycled. Never launch the
        exe directly from here."""
        def work():
            self.log_line("")
            self.log_line("$ python scripts/play.py")
            self.core.run_script(["scripts/play.py"], self.log_line)
        self.in_worker(work)


def run(core, steam_path=None):
    root = tk.Tk()
    App(root, core, steam_path)
    root.mainloop()
    return 0

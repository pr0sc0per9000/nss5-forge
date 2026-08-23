"""play.exe -- starts the game.

This is the whole of what a player interacts with after installing. It sits beside
source_code/ and runs the release build through scripts/play.py.

WHY IT GOES THROUGH play.py AND NEVER STARTS THE EXE ITSELF
The game can come up in exclusive fullscreen and hold the display and the input queue
until the machine is power cycled. That has happened. play.py forces windowed mode in
every Options.ini the game reads before the process starts, which is the only safe order,
because which copy wins depends on how the game resolves its own user path at runtime.
Starting src/assembled/nss5_assembled.exe directly would skip that.

There is no console. Anything worth saying is said in a message box, because a player who
double-clicks an icon never sees stdout.
"""

import os
import sys
import runpy


def here():
    """The folder this executable sits in, which is the folder the player chose."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def complain(title, message):
    try:
        import tkinter
        from tkinter import messagebox
        root = tkinter.Tk()
        root.withdraw()
        messagebox.showerror(title, message)
        root.destroy()
    except Exception:
        # No tkinter and no console. Leave something on disk rather than vanishing.
        try:
            with open(os.path.join(here(), "play_error.txt"), "w") as f:
                f.write(title + "\n\n" + message + "\n")
        except Exception:
            pass


def main():
    root = os.path.join(here(), "source_code")
    play = os.path.join(root, "scripts", "play.py")

    if not os.path.isfile(play):
        complain("New Star Soccer 5",
                 "The source_code folder is missing or incomplete.\n\n"
                 "play.exe has to sit next to the source_code folder the installer "
                 "created. If you moved one of them, move it back, or run the installer "
                 "again.")
        return 1

    built = os.path.join(root, "src", "assembled", "nss5_assembled.exe")
    if not os.path.isfile(built):
        complain("New Star Soccer 5",
                 "The game has not been built yet.\n\n"
                 "Run the installer again and let it finish. It builds the game from "
                 "your own copy of New Star Soccer 5, and that step has not completed.")
        return 1

    # play.py derives its own location, so running it from its real path puts every
    # relative path it uses in the right place.
    os.chdir(root)
    sys.argv = [play]
    sys.path.insert(0, os.path.join(root, "scripts"))
    try:
        runpy.run_path(play, run_name="__main__")
    except SystemExit as e:
        return e.code or 0
    except Exception as e:
        complain("New Star Soccer 5",
                 "The game could not be started.\n\n%s: %s\n\n"
                 "If this keeps happening, please report it. README.txt says how."
                 % (type(e).__name__, e))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

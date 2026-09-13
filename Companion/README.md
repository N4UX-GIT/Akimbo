# Offhand Companion

Native Windows desktop companion application for the Offhand World of Warcraft add-on.

## Features
* **Auto-Spanning**: Detects World of Warcraft launches and spans the game window borderlessly across your multi-monitor virtual desktop.
* **Addon Verification**: Validates that the Offhand add-on is properly installed in your WoW client's `Interface\AddOns` folder.
* **Zero Console Flashing**: Compiled as a native Win32 subsystem application (`Offhand.exe`).
* **System Tray Integration**: Minimizes silently to the Windows notification tray with quick-actions and live status tips.
* **DPI-Aware**: Full Per-Monitor V2 scaling ensures crisp fonts and accurate window positioning on mixed-resolution / mixed-scale setups.

---

## Downloads & Distribution
* **`Offhand.exe`**: Ready-to-run standalone executable. No installer, runtime, or dependencies needed.
* **Open Source Auditability**: 
  * Full source code is in `Source/Program.cs`.
  * To compile yourself, run `build.bat`. It uses the native Windows C# compiler (`csc.exe`) built into Windows 10 & 11.
* **PowerShell Alternative**: `Offhand-Companion.ps1` is included for technical users who prefer raw script execution.
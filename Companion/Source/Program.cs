using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

[assembly: AssemblyTitle("Offhand Companion")]
[assembly: AssemblyDescription("Dual-Monitor Multi-Display Controller for World of Warcraft")]
[assembly: AssemblyCompany("Offhand Project")]
[assembly: AssemblyProduct("Offhand")]
[assembly: AssemblyCopyright("Copyright (C) 2026 Offhand Project")]
[assembly: AssemblyVersion("1.2.0.0")]
[assembly: AssemblyFileVersion("1.2.0.0")]

namespace Offhand.Companion
{
    public static class NativeMethods
    {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
            public int Width { get { return Right - Left; } }
            public int Height { get { return Bottom - Top; } }
        }

        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsZoomed(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        [DllImport("kernel32.dll")]
        public static extern void SetLastError(uint dwErrCode);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        public static extern int GetSystemMetrics(int nIndex);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);

        public const int GWL_STYLE = -16;
        public const int WS_CAPTION = 0x00C00000;
        public const int WS_THICKFRAME = 0x00040000;
        public const uint SWP_NOZORDER = 0x0004;
        public const uint SWP_NOACTIVATE = 0x0010;
        public const uint SWP_FRAMECHANGED = 0x0020;
        public const uint SWP_SHOWWINDOW = 0x0040;
        public const int SW_RESTORE = 9;

        public static IntPtr FindProcessWindow(int processId)
        {
            IntPtr found = IntPtr.Zero;
            EnumWindows(delegate (IntPtr h, IntPtr p)
            {
                uint id;
                GetWindowThreadProcessId(h, out id);
                if (id == processId && IsWindowVisible(h))
                {
                    found = h;
                    return false;
                }
                return true;
            }, IntPtr.Zero);
            return found;
        }
    }

    public class AddonStatus
    {
        public bool Installed;
        public string WowDir;
        public string Reason;
    }

    public class DesktopBounds
    {
        public int X, Y, Width, Height;
    }

    public class CompanionForm : Form
    {
        // Colors
        private readonly Color cBg = Color.FromArgb(8, 10, 18);
        private readonly Color cCard = Color.FromArgb(17, 24, 38);
        private readonly Color cBorder = Color.FromArgb(58, 74, 94);
        private readonly Color cBorderDim = Color.FromArgb(26, 48, 80);
        private readonly Color cText = Color.FromArgb(216, 232, 245);
        private readonly Color cMuted = Color.FromArgb(122, 150, 176);
        private readonly Color cBlue = Color.FromArgb(42, 144, 232);
        private readonly Color cBlueBright = Color.FromArgb(90, 184, 255);
        private readonly Color cBrass = Color.FromArgb(180, 138, 52);
        private readonly Color cGreen = Color.FromArgb(68, 204, 136);
        private readonly Color cRed = Color.FromArgb(204, 68, 68);
        private readonly Color cYellow = Color.FromArgb(220, 180, 60);
        private readonly Color cBtnBg = Color.FromArgb(26, 36, 56);
        private readonly Color cBtnDanger = Color.FromArgb(40, 16, 16);
        private readonly Color cLogBg = Color.FromArgb(6, 8, 14);
        private readonly Color cLogText = Color.FromArgb(140, 180, 218);

        // UI Controls
        private Label lblWowStatus;
        private Label lblAddonStatus;
        private Label lblDisplayInfo;
        private Label lblAddonReason;
        private CheckBox chkAutoSpan;
        private Button btnSpanNow;
        private Button btnToggleWatch;
        private ListBox logBox;
        private NotifyIcon trayIcon;
        private ToolStripMenuItem itemAuto;
        private Timer monitorTimer;

        // State
        private bool isMonitoring = true;
        private bool isExplicitExit = false;
        private readonly HashSet<int> spannedPids = new HashSet<int>();
        private readonly Dictionary<int, DateTime> retryAfter = new Dictionary<int, DateTime>();

        public CompanionForm()
        {
            InitializeUI();
            InitializeTray();
            InitializeTimer();

            AddLog("Offhand Companion v1.2 initialized.");
            AddLog("Monitoring active. Enable Offhand in WoW; calibrate with /offhand wizard.");
        }

        private void InitializeUI()
        {
            this.Text = "Offhand Companion";
            this.Size = new Size(524, 628);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.BackColor = cBg;
            this.ForeColor = cText;

            // Load Application Icon if available
            try
            {
                using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Offhand.Companion.Resources.offhand-logo.ico"))
                {
                    if (stream != null) this.Icon = new Icon(stream);
                }
            }
            catch { }

            // Header Panel
            Panel headerPanel = new Panel();
            headerPanel.Location = new Point(0, 0);
            headerPanel.Size = new Size(524, 90);
            headerPanel.BackColor = Color.FromArgb(10, 14, 24);
            headerPanel.Paint += (s, e) =>
            {
                using (Pen pen = new Pen(cBorder, 2))
                {
                    e.Graphics.DrawLine(pen, 0, headerPanel.Height - 1, headerPanel.Width, headerPanel.Height - 1);
                }
            };
            this.Controls.Add(headerPanel);

            // Header Logo
            PictureBox logoBox = new PictureBox();
            logoBox.Location = new Point(8, 5);
            logoBox.Size = new Size(80, 80);
            logoBox.SizeMode = PictureBoxSizeMode.Zoom;
            logoBox.BackColor = Color.Transparent;

            try
            {
                using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Offhand.Companion.Resources.offhand-logo.png"))
                {
                    if (stream != null)
                    {
                        logoBox.Image = Image.FromStream(stream);
                    }
                }
            }
            catch { }

            if (logoBox.Image == null)
            {
                // Fallback to disk asset if running unpackaged
                string[] diskFallbacks = new string[] {
                    Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\Media\offhand-logo.png"),
                    Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"Media\offhand-logo.png")
                };
                foreach (string path in diskFallbacks)
                {
                    if (File.Exists(path))
                    {
                        try { logoBox.Image = Image.FromFile(path); break; } catch { }
                    }
                }
            }
            headerPanel.Controls.Add(logoBox);

            // Title
            Label titleLabel = new Label();
            titleLabel.Text = "OFFHAND";
            titleLabel.Location = new Point(96, 10);
            titleLabel.Size = new Size(400, 36);
            titleLabel.Font = new Font("Georgia", 22, FontStyle.Bold);
            titleLabel.ForeColor = cBlue;
            titleLabel.BackColor = Color.Transparent;
            headerPanel.Controls.Add(titleLabel);

            // Subtitle
            Label subLabel = new Label();
            subLabel.Text = "Multi-Monitor Companion for World of Warcraft";
            subLabel.Location = new Point(98, 50);
            subLabel.Size = new Size(400, 18);
            subLabel.Font = new Font("Segoe UI", 8.5f);
            subLabel.ForeColor = cMuted;
            subLabel.BackColor = Color.Transparent;
            headerPanel.Controls.Add(subLabel);

            // Version
            Label verLabel = new Label();
            verLabel.Text = "v1.2";
            verLabel.Location = new Point(98, 68);
            verLabel.Size = new Size(100, 14);
            verLabel.Font = new Font("Segoe UI", 7.5f, FontStyle.Italic);
            verLabel.ForeColor = cMuted;
            verLabel.BackColor = Color.Transparent;
            headerPanel.Controls.Add(verLabel);

            // Status Card
            Panel statusPanel = CreateCardPanel(16, 102, 490, 118, "System Status");
            this.Controls.Add(statusPanel);

            lblWowStatus = new Label
            {
                Text = "  WoW Process: Checking...",
                Location = new Point(0, 30),
                Size = new Size(490, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = cMuted
            };
            statusPanel.Controls.Add(lblWowStatus);

            lblAddonStatus = new Label
            {
                Text = "  Offhand Addon: Checking...",
                Location = new Point(0, 54),
                Size = new Size(490, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = cMuted
            };
            statusPanel.Controls.Add(lblAddonStatus);

            lblDisplayInfo = new Label
            {
                Text = "  Virtual Desktop: Checking...",
                Location = new Point(0, 78),
                Size = new Size(490, 18),
                Font = new Font("Segoe UI", 8.5f),
                ForeColor = cMuted
            };
            statusPanel.Controls.Add(lblDisplayInfo);

            lblAddonReason = new Label
            {
                Text = "",
                Location = new Point(0, 98),
                Size = new Size(490, 16),
                Font = new Font("Segoe UI", 7.5f, FontStyle.Italic),
                ForeColor = cYellow
            };
            statusPanel.Controls.Add(lblAddonReason);

            // Configuration Card
            Panel configPanel = CreateCardPanel(16, 230, 490, 54, "Configuration");
            this.Controls.Add(configPanel);

            chkAutoSpan = new CheckBox
            {
                Text = "Automatically span WoW window on game launch",
                Location = new Point(10, 28),
                Size = new Size(460, 22),
                Font = new Font("Segoe UI", 9),
                ForeColor = cText,
                BackColor = Color.Transparent,
                Checked = true
            };
            chkAutoSpan.CheckedChanged += (s, e) =>
            {
                if (itemAuto != null) itemAuto.Checked = chkAutoSpan.Checked;
                AddLog("Auto-Span on launch: " + chkAutoSpan.Checked);
            };
            configPanel.Controls.Add(chkAutoSpan);

            // Action Buttons
            btnSpanNow = CreateButton("Span WoW Window Now", 16, 296, 238, 36, cBtnBg, cBlueBright, cBorder);
            btnSpanNow.Click += (s, e) => { InvokeSpanWindow(true); };
            this.Controls.Add(btnSpanNow);

            btnToggleWatch = CreateButton("Pause Monitoring", 262, 296, 244, 36, cBtnBg, cText, cBorderDim);
            btnToggleWatch.Click += (s, e) =>
            {
                isMonitoring = !isMonitoring;
                if (isMonitoring)
                {
                    btnToggleWatch.Text = "Pause Monitoring";
                    btnToggleWatch.ForeColor = cText;
                    AddLog("Background auto-watcher resumed.");
                }
                else
                {
                    btnToggleWatch.Text = "Resume Monitoring";
                    btnToggleWatch.ForeColor = cYellow;
                    AddLog("Background auto-watcher PAUSED by user.");
                }
            };
            this.Controls.Add(btnToggleWatch);

            // Activity Log Card
            Panel logPanel = CreateCardPanel(16, 344, 490, 200, "Activity Log");
            this.Controls.Add(logPanel);

            logBox = new ListBox
            {
                Location = new Point(4, 28),
                Size = new Size(482, 166),
                BackColor = cLogBg,
                ForeColor = cLogText,
                BorderStyle = BorderStyle.None,
                Font = new Font("Consolas", 8.5f)
            };
            logPanel.Controls.Add(logBox);

            // Footer Buttons
            Button btnMinimize = CreateButton("Minimize to Tray", 16, 556, 152, 30, cBtnBg, cMuted, cBorderDim);
            btnMinimize.Click += (s, e) =>
            {
                this.Hide();
                trayIcon.ShowBalloonTip(2000, "Offhand Running in Tray", "Monitoring in background. Double-click tray icon to restore.", ToolTipIcon.Info);
            };
            this.Controls.Add(btnMinimize);

            Button btnExit = CreateButton("Exit Companion", 356, 556, 152, 30, cBtnDanger, cRed, Color.FromArgb(120, 50, 40));
            btnExit.Click += (s, e) => { ExitApplication(); };
            this.Controls.Add(btnExit);

            this.FormClosing += (s, e) =>
            {
                if (!isExplicitExit && e.CloseReason == CloseReason.UserClosing)
                {
                    e.Cancel = true;
                    this.Hide();
                    trayIcon.ShowBalloonTip(1500, "Offhand Minimized", "Running in System Tray. Right-click or double-click to control.", ToolTipIcon.Info);
                }
            };
        }

        private Panel CreateCardPanel(int x, int y, int w, int h, string title)
        {
            Panel panel = new Panel
            {
                Location = new Point(x, y),
                Size = new Size(w, h),
                BackColor = cCard
            };

            Label lblTitle = new Label
            {
                Text = "  " + title,
                Location = new Point(0, 4),
                Size = new Size(w, 20),
                Font = new Font("Segoe UI", 8, FontStyle.Bold),
                ForeColor = cBlue
            };
            panel.Controls.Add(lblTitle);

            panel.Paint += (s, e) =>
            {
                using (Pen pen = new Pen(cBorder, 1))
                {
                    e.Graphics.DrawRectangle(pen, 0, 0, panel.ClientSize.Width - 1, panel.ClientSize.Height - 1);
                }
                using (Pen penDim = new Pen(cBorderDim, 1))
                {
                    e.Graphics.DrawLine(penDim, 1, 24, panel.ClientSize.Width - 2, 24);
                }
            };

            return panel;
        }

        private Button CreateButton(string text, int x, int y, int w, int h, Color bg, Color fg, Color border)
        {
            Button btn = new Button
            {
                Text = text,
                Location = new Point(x, y),
                Size = new Size(w, h),
                FlatStyle = FlatStyle.Flat,
                BackColor = bg,
                ForeColor = fg,
                Font = new Font("Georgia", 9, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            btn.FlatAppearance.BorderSize = 1;
            btn.FlatAppearance.BorderColor = border;
            return btn;
        }

        private void InitializeTray()
        {
            trayIcon = new NotifyIcon
            {
                Text = "Offhand Companion",
                Visible = true
            };

            // Programmatic icon or loaded icon
            if (this.Icon != null)
            {
                trayIcon.Icon = this.Icon;
            }
            else
            {
                using (Bitmap bmp = new Bitmap(16, 16))
                using (Graphics g = Graphics.FromImage(bmp))
                using (SolidBrush brush = new SolidBrush(Color.FromArgb(90, 184, 255)))
                using (Font font = new Font("Georgia", 9, FontStyle.Bold))
                {
                    g.Clear(Color.FromArgb(8, 10, 18));
                    g.DrawString("A", font, brush, 1, 0);
                    trayIcon.Icon = Icon.FromHandle(bmp.GetHicon());
                }
            }

            ContextMenuStrip trayMenu = new ContextMenuStrip
            {
                BackColor = cCard,
                ForeColor = cText
            };

            ToolStripMenuItem itemOpen = new ToolStripMenuItem("Open Dashboard");
            itemOpen.Click += (s, e) => { RestoreForm(); };
            trayMenu.Items.Add(itemOpen);

            trayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem itemSpan = new ToolStripMenuItem("Span WoW Now");
            itemSpan.Click += (s, e) => { InvokeSpanWindow(true); };
            trayMenu.Items.Add(itemSpan);

            itemAuto = new ToolStripMenuItem("Auto-Span Enabled")
            {
                Checked = chkAutoSpan.Checked
            };
            itemAuto.Click += (s, e) =>
            {
                chkAutoSpan.Checked = !chkAutoSpan.Checked;
                itemAuto.Checked = chkAutoSpan.Checked;
            };
            trayMenu.Items.Add(itemAuto);

            trayMenu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem itemExit = new ToolStripMenuItem("Exit");
            itemExit.Click += (s, e) => { ExitApplication(); };
            trayMenu.Items.Add(itemExit);

            trayIcon.ContextMenuStrip = trayMenu;
            trayIcon.DoubleClick += (s, e) => { RestoreForm(); };
        }

        private void RestoreForm()
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.Activate();
        }

        private void ExitApplication()
        {
            isExplicitExit = true;
            if (monitorTimer != null) monitorTimer.Stop();
            if (trayIcon != null) trayIcon.Visible = false;
            this.Close();
            Application.Exit();
        }

        private void AddLog(string message)
        {
            string time = DateTime.Now.ToString("HH:mm:ss");
            logBox.Items.Insert(0, string.Format("[{0}] {1}", time, message));
            while (logBox.Items.Count > 100)
            {
                logBox.Items.RemoveAt(logBox.Items.Count - 1);
            }
        }

        private void InitializeTimer()
        {
            monitorTimer = new Timer
            {
                Interval = 2000
            };
            monitorTimer.Tick += (s, e) => { OnTimerTick(); };
            monitorTimer.Start();
        }

        private void OnTimerTick()
        {
            try
            {
                DesktopBounds vs = GetDesktopBounds();
                lblDisplayInfo.Text = string.Format("  Virtual Desktop: {0} x {1} px  (Offset X:{2}, Y:{3})", vs.Width, vs.Height, vs.X, vs.Y);
            }
            catch
            {
                lblDisplayInfo.Text = "  Virtual Desktop: physical coordinates unavailable";
            }

            Process proc = GetWoWProcess();

            if (proc != null)
            {
                lblWowStatus.Text = string.Format("  * WoW Running  ({0}  PID: {1})", proc.ProcessName, proc.Id);
                lblWowStatus.ForeColor = cGreen;

                AddonStatus status = TestOffhandAddonStatus(proc);
                if (status.Installed)
                {
                    lblAddonStatus.Text = "  * Offhand Addon: INSTALLED";
                    lblAddonStatus.ForeColor = cGreen;
                    lblAddonReason.Text = "  Confirm Offhand is enabled in the current WoW session.";
                }
                else
                {
                    lblAddonStatus.Text = "  o Offhand Addon: NOT VERIFIED";
                    lblAddonStatus.ForeColor = cRed;
                    lblAddonReason.Text = "  " + status.Reason;
                }

                if (isMonitoring && chkAutoSpan.Checked && status.Installed)
                {
                    if (!spannedPids.Contains(proc.Id) &&
                        (!retryAfter.ContainsKey(proc.Id) || DateTime.Now >= retryAfter[proc.Id]))
                    {
                        AddLog(string.Format("New WoW launch detected (PID: {0}). Preparing auto-span...", proc.Id));
                        retryAfter[proc.Id] = DateTime.Now.AddSeconds(10);
                        if (InvokeSpanWindow(false))
                        {
                            spannedPids.Add(proc.Id);
                        }
                    }
                }
            }
            else
            {
                lblWowStatus.Text = "  o WoW Process: Not running";
                lblWowStatus.ForeColor = cMuted;
                lblAddonStatus.Text = "  o Offhand Addon: Waiting for WoW...";
                lblAddonStatus.ForeColor = cMuted;
                lblAddonReason.Text = "";
            }

            // Clean dead PIDs
            List<int> pidsToCheck = new List<int>(spannedPids);
            foreach (int pid in pidsToCheck)
            {
                try
                {
                    Process.GetProcessById(pid);
                }
                catch
                {
                    spannedPids.Remove(pid);
                    retryAfter.Remove(pid);
                    AddLog(string.Format("WoW process (PID: {0}) closed.", pid));
                }
            }
        }

        private Process GetWoWProcess()
        {
            List<Process> candidates = new List<Process>();
            string[] names = new string[] { "WowClassic", "Wow", "WowClassicEra" };
            foreach (string name in names)
            {
                candidates.AddRange(Process.GetProcessesByName(name));
            }
            if (candidates.Count == 1)
            {
                return candidates[0];
            }
            return null;
        }

        private AddonStatus TestOffhandAddonStatus(Process proc)
        {
            AddonStatus result = new AddonStatus { Installed = false, Reason = "Launch exactly one WoW client." };
            if (proc == null) return result;

            try
            {
                string mainModule = proc.MainModule.FileName;
                result.WowDir = Path.GetDirectoryName(mainModule);
                if (string.IsNullOrEmpty(result.WowDir))
                {
                    result.Reason = "Client path unavailable.";
                    return result;
                }

                string addonDir = Path.Combine(result.WowDir, @"Interface\AddOns\Offhand");
                string[] manifests = new string[] { "Offhand.toc", "Offhand_Vanilla.toc" };
                
                bool exists = false;
                if (Directory.Exists(addonDir))
                {
                    foreach (string m in manifests)
                    {
                        if (File.Exists(Path.Combine(addonDir, m))) { exists = true; break; }
                    }
                }

                if (exists)
                {
                    result.Installed = true;
                    result.Reason = "Installed; confirm enabled in WoW. Live addon state is unavailable.";
                }
                else
                {
                    result.Reason = "Install Offhand in this client's Interface\\AddOns folder.";
                }
            }
            catch
            {
                result.Reason = "Cannot verify the addon installation for this client.";
            }

            return result;
        }

        private IntPtr GetWoWWindowHandle(Process proc)
        {
            if (proc == null) return IntPtr.Zero;
            proc.Refresh();
            IntPtr handle = proc.MainWindowHandle;
            if (handle == IntPtr.Zero)
            {
                handle = NativeMethods.FindProcessWindow(proc.Id);
            }
            uint ownerPid;
            NativeMethods.GetWindowThreadProcessId(handle, out ownerPid);
            if (ownerPid != proc.Id) return IntPtr.Zero;
            return handle;
        }

        private DesktopBounds GetDesktopBounds()
        {
            IntPtr prevDpi = NativeMethods.SetThreadDpiAwarenessContext((IntPtr)(-4));
            try
            {
                return new DesktopBounds
                {
                    X = NativeMethods.GetSystemMetrics(76),
                    Y = NativeMethods.GetSystemMetrics(77),
                    Width = NativeMethods.GetSystemMetrics(78),
                    Height = NativeMethods.GetSystemMetrics(79)
                };
            }
            finally
            {
                if (prevDpi != IntPtr.Zero)
                {
                    NativeMethods.SetThreadDpiAwarenessContext(prevDpi);
                }
            }
        }

        private bool InvokeSpanWindow(bool manual)
        {
            try
            {
                Process proc = GetWoWProcess();
                if (proc == null) throw new Exception("Launch exactly one WoW client first.");

                AddonStatus status = TestOffhandAddonStatus(proc);
                if (!status.Installed) throw new Exception(status.Reason);

                IntPtr handle = GetWoWWindowHandle(proc);
                if (handle == IntPtr.Zero) throw new Exception("WoW window is not ready. Retry after it opens.");

                DesktopBounds bounds = GetDesktopBounds();
                if (bounds.Width <= 0 || bounds.Height <= 0) throw new Exception("Invalid virtual desktop dimensions.");

                if (NativeMethods.IsZoomed(handle) || NativeMethods.IsIconic(handle))
                {
                    NativeMethods.ShowWindow(handle, NativeMethods.SW_RESTORE);
                }

                NativeMethods.RECT oldRect;
                if (!NativeMethods.GetWindowRect(handle, out oldRect)) throw new Exception("Could not read WoW window bounds.");

                int oldStyle = NativeMethods.GetWindowLong(handle, NativeMethods.GWL_STYLE);
                int newStyle = oldStyle & ~(NativeMethods.WS_CAPTION | NativeMethods.WS_THICKFRAME);
                if (newStyle != oldStyle)
                {
                    NativeMethods.SetLastError(0);
                    int res = NativeMethods.SetWindowLong(handle, NativeMethods.GWL_STYLE, newStyle);
                    if (res == 0 && Marshal.GetLastWin32Error() != 0)
                    {
                        throw new Exception("Could not remove WoW window borders.");
                    }
                }

                try
                {
                    uint flags = NativeMethods.SWP_NOZORDER | NativeMethods.SWP_NOACTIVATE | NativeMethods.SWP_FRAMECHANGED | NativeMethods.SWP_SHOWWINDOW;
                    if (!NativeMethods.SetWindowPos(handle, IntPtr.Zero, bounds.X, bounds.Y, bounds.Width, bounds.Height, flags))
                    {
                        throw new Exception("Windows rejected the requested span.");
                    }

                    NativeMethods.RECT actual;
                    if (!NativeMethods.GetWindowRect(handle, out actual) ||
                        actual.Left != bounds.X || actual.Top != bounds.Y ||
                        actual.Width != bounds.Width || actual.Height != bounds.Height)
                    {
                        throw new Exception("WoW did not accept the requested bounds. Select Windowed mode and retry.");
                    }
                }
                catch
                {
                    NativeMethods.SetWindowLong(handle, NativeMethods.GWL_STYLE, oldStyle);
                    NativeMethods.SetWindowPos(handle, IntPtr.Zero, oldRect.Left, oldRect.Top, oldRect.Width, oldRect.Height, 0x0074);
                    throw;
                }

                AddLog(string.Format("Spanned {0}x{1}. Calibrate with /offhand wizard.", bounds.Width, bounds.Height));
                trayIcon.ShowBalloonTip(3000, "Offhand Spanned", "Window spanned. Use /offhand wizard to calibrate.", ToolTipIcon.Info);
                return true;
            }
            catch (Exception ex)
            {
                AddLog(ex.Message);
                if (manual)
                {
                    MessageBox.Show(ex.Message, "Offhand", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                return false;
            }
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new CompanionForm());
        }
    }
}
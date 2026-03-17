using System.Diagnostics;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

ApplicationConfiguration.Initialize();
Application.Run(new MainForm());

internal sealed partial class MainForm : Form
{
    private readonly ListBox _toolList = new();
    private readonly Label _descriptionValue = new();
    private readonly TextBox _exampleValue = new();
    private readonly TextBox _argsTextBox = new();
    private readonly RichTextBox _outputBox = new();
    private readonly Label _statusLabel = new();
    private readonly Button _runButton = new();
    private readonly Button _terminalButton = new();
    private readonly string _toolCacheDir;
    private readonly List<ToolDefinition> _tools;
    private const string RepoUrl = "https://github.com/DarkCatharsis013/WinSurvivalKit";

    public MainForm()
    {
        _toolCacheDir = EnsureToolCache();
        _tools = BuildTools();

        Text = "WinSurvivalKit";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(1000, 680);
        Size = new Size(1120, 760);
        BackColor = Color.FromArgb(17, 21, 28);

        var titleLabel = new Label
        {
            Text = "WinSurvivalKit",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 20, FontStyle.Bold),
            Location = new Point(18, 14),
            AutoSize = true
        };

        var subtitleLabel = new Label
        {
            Text = "Pick a tool, set optional arguments, and run it without the window disappearing.",
            ForeColor = Color.FromArgb(180, 190, 202),
            Font = new Font("Segoe UI", 10),
            Location = new Point(22, 54),
            AutoSize = true
        };

        _toolList.Location = new Point(22, 98);
        _toolList.Size = new Size(280, 560);
        _toolList.Font = new Font("Segoe UI", 10);
        _toolList.BackColor = Color.FromArgb(24, 29, 38);
        _toolList.ForeColor = Color.White;
        _toolList.BorderStyle = BorderStyle.FixedSingle;
        _toolList.DataSource = _tools;
        _toolList.DisplayMember = nameof(ToolDefinition.Name);
        _toolList.SelectedIndexChanged += (_, _) => SetToolSelection(GetSelectedTool());

        var descriptionLabel = new Label
        {
            Text = "Description",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 11, FontStyle.Bold),
            Location = new Point(328, 102),
            AutoSize = true
        };

        _descriptionValue.ForeColor = Color.FromArgb(210, 216, 224);
        _descriptionValue.Font = new Font("Segoe UI", 10);
        _descriptionValue.Location = new Point(330, 132);
        _descriptionValue.Size = new Size(740, 44);

        var exampleLabel = new Label
        {
            Text = "Example args",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 11, FontStyle.Bold),
            Location = new Point(328, 186),
            AutoSize = true
        };

        _exampleValue.Location = new Point(332, 214);
        _exampleValue.Size = new Size(738, 25);
        _exampleValue.ReadOnly = true;
        _exampleValue.BackColor = Color.FromArgb(24, 29, 38);
        _exampleValue.ForeColor = Color.FromArgb(150, 205, 255);
        _exampleValue.BorderStyle = BorderStyle.FixedSingle;

        var argsLabel = new Label
        {
            Text = "Arguments",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 11, FontStyle.Bold),
            Location = new Point(328, 252),
            AutoSize = true
        };

        _argsTextBox.Location = new Point(332, 280);
        _argsTextBox.Size = new Size(738, 25);
        _argsTextBox.BackColor = Color.FromArgb(24, 29, 38);
        _argsTextBox.ForeColor = Color.White;
        _argsTextBox.BorderStyle = BorderStyle.FixedSingle;

        _runButton.Text = "Run Here";
        _runButton.Location = new Point(332, 320);
        _runButton.Size = new Size(110, 34);
        _runButton.BackColor = Color.FromArgb(92, 214, 167);
        _runButton.FlatStyle = FlatStyle.Flat;
        _runButton.Click += async (_, _) => await RunSelectedToolAsync();

        _terminalButton.Text = "Open In Terminal";
        _terminalButton.Location = new Point(452, 320);
        _terminalButton.Size = new Size(138, 34);
        _terminalButton.BackColor = Color.FromArgb(103, 183, 255);
        _terminalButton.FlatStyle = FlatStyle.Flat;
        _terminalButton.Click += (_, _) => OpenSelectedToolInTerminal();

        var clearButton = new Button
        {
            Text = "Clear Output",
            Location = new Point(600, 320),
            Size = new Size(110, 34),
            BackColor = Color.FromArgb(231, 184, 75),
            FlatStyle = FlatStyle.Flat
        };
        clearButton.Click += (_, _) =>
        {
            _outputBox.Clear();
            _statusLabel.Text = "Output cleared.";
        };

        var readmeButton = new Button
        {
            Text = "Open README",
            Location = new Point(720, 320),
            Size = new Size(110, 34),
            BackColor = Color.FromArgb(58, 66, 82),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat
        };
        readmeButton.Click += (_, _) =>
        {
            Process.Start(new ProcessStartInfo(RepoUrl) { UseShellExecute = true });
        };

        var outputLabel = new Label
        {
            Text = "Output",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 11, FontStyle.Bold),
            Location = new Point(328, 372),
            AutoSize = true
        };

        _outputBox.Location = new Point(332, 400);
        _outputBox.Size = new Size(738, 258);
        _outputBox.BackColor = Color.FromArgb(15, 20, 27);
        _outputBox.ForeColor = Color.White;
        _outputBox.Font = new Font("Consolas", 10);
        _outputBox.ReadOnly = true;
        _outputBox.BorderStyle = BorderStyle.FixedSingle;

        _statusLabel.Text = "Ready.";
        _statusLabel.ForeColor = Color.FromArgb(180, 190, 202);
        _statusLabel.Font = new Font("Segoe UI", 9);
        _statusLabel.Location = new Point(22, 676);
        _statusLabel.Size = new Size(1048, 24);

        Controls.AddRange(
        [
            titleLabel, subtitleLabel, _toolList, descriptionLabel, _descriptionValue, exampleLabel, _exampleValue,
            argsLabel, _argsTextBox, _runButton, _terminalButton, clearButton, readmeButton, outputLabel, _outputBox, _statusLabel
        ]);

        _toolList.SelectedIndex = 0;
    }

    private async Task RunSelectedToolAsync()
    {
        var tool = GetSelectedTool();
        if (tool is null)
        {
            return;
        }

        var scriptPath = GetToolScriptPath(tool);
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = BuildPowerShellArguments(scriptPath, ParseArguments(_argsTextBox.Text), noExit: false),
            WorkingDirectory = Environment.CurrentDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        _runButton.Enabled = false;
        _terminalButton.Enabled = false;
        _statusLabel.Text = $"Running {tool.Name}...";
        _outputBox.Clear();

        try
        {
            using var process = new Process { StartInfo = psi };
            process.Start();
            var stdout = await process.StandardOutput.ReadToEndAsync();
            var stderr = await process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();

            var combined = (stdout + Environment.NewLine + stderr).Trim();
            _outputBox.Text = string.IsNullOrWhiteSpace(combined) ? "[No output]" : combined;
            _statusLabel.Text = process.ExitCode == 0
                ? $"{tool.Name} finished."
                : $"{tool.Name} finished with errors.";
        }
        finally
        {
            _runButton.Enabled = true;
            _terminalButton.Enabled = true;
        }
    }

    private void OpenSelectedToolInTerminal()
    {
        var tool = GetSelectedTool();
        if (tool is null)
        {
            return;
        }

        var scriptPath = GetToolScriptPath(tool);
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = BuildPowerShellArguments(scriptPath, ParseArguments(_argsTextBox.Text), noExit: true),
            WorkingDirectory = Environment.CurrentDirectory,
            UseShellExecute = true
        };
        Process.Start(psi);
    }

    private static string BuildPowerShellArguments(string scriptPath, IReadOnlyList<string> args, bool noExit)
    {
        var builder = new StringBuilder();
        if (noExit)
        {
            builder.Append("-NoExit ");
        }

        builder.Append("-ExecutionPolicy Bypass -File ");
        builder.Append(Quote(scriptPath));

        foreach (var arg in args)
        {
            builder.Append(' ');
            builder.Append(Quote(arg));
        }

        return builder.ToString();
    }

    private ToolDefinition? GetSelectedTool() => _toolList.SelectedItem as ToolDefinition;

    private string GetToolScriptPath(ToolDefinition tool) => Path.Combine(_toolCacheDir, tool.Script);

    private void SetToolSelection(ToolDefinition? tool)
    {
        if (tool is null)
        {
            return;
        }

        _descriptionValue.Text = tool.Description;
        _exampleValue.Text = tool.ExampleArgs;
        _argsTextBox.Text = tool.ExampleArgs;
        _outputBox.Clear();
        _statusLabel.Text = $"Selected {tool.Name}.";
    }

    private static IReadOnlyList<string> ParseArguments(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Array.Empty<string>();
        }

        var matches = Regex.Matches(input, "(\"([^\"\\\\]|\\\\.)*\"|'([^'\\\\]|\\\\.)*'|\\S+)");
        var tokens = new List<string>(matches.Count);

        foreach (Match match in matches)
        {
            var value = match.Value;
            if ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\'')))
            {
                tokens.Add(value[1..^1]);
            }
            else
            {
                tokens.Add(value);
            }
        }

        return tokens;
    }

    private static string Quote(string value) => "\"" + value.Replace("\"", "\\\"") + "\"";

    private static string EnsureToolCache()
    {
        var cacheDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WinSurvivalKit",
            "tools");
        Directory.CreateDirectory(cacheDir);

        var assembly = Assembly.GetExecutingAssembly();
        foreach (var resourceName in assembly.GetManifestResourceNames().Where(name => name.StartsWith("WinSurvivalKit.Tools.", StringComparison.Ordinal)))
        {
            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream is null)
            {
                continue;
            }

            var fileName = resourceName["WinSurvivalKit.Tools.".Length..];
            var targetPath = Path.Combine(cacheDir, fileName);
            using var fileStream = File.Create(targetPath);
            stream.CopyTo(fileStream);
        }

        return cacheDir;
    }

    private static List<ToolDefinition> BuildTools()
    {
        var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

        return
        [
            new("system-snapshot", "system-snapshot.ps1", "Quick machine summary for CPU, RAM, GPU, disks, OS, and IP addresses.", ""),
            new("port-party", "port-party.ps1", "List listening ports or inspect a specific port.", "-Port 3000"),
            new("path-doctor", "path-doctor.ps1", "Audit PATH entries for duplicates and missing folders.", "-Scope Machine"),
            new("junk-drawer", "junk-drawer.ps1", "Preview temp-file cleanup for common Windows temp folders.", "-IncludeWindowsTemp"),
            new("startup-snoop", "startup-snoop.ps1", "Show common startup entries from folders and Run keys.", ""),
            new("process-parade", "process-parade.ps1", "Show biggest running processes by memory or CPU time.", "-Top 10"),
            new("big-file-bouncer", "big-file-bouncer.ps1", "Find the biggest files in a folder.", $"-Path \"{Path.Combine(userProfile, "Downloads")}\" -Top 15"),
            new("extension-radar", "extension-radar.ps1", "Break down file types by count and total size.", $"-Path \"{Path.Combine(userProfile, "Desktop")}\""),
            new("desktop-radar", "desktop-radar.ps1", "Summarize files on your desktop or another folder.", $"-Path \"{Path.Combine(userProfile, "Desktop")}\""),
            new("screenshot-sweeper", "screenshot-sweeper.ps1", "Preview sorting screenshots into date-based folders.", $"-Path \"{Path.Combine(userProfile, "Pictures", "Screenshots")}\""),
            new("clipboard-carwash", "clipboard-carwash.ps1", "Clean clipboard text and preview the result.", "-TrimLines -CollapseBlankLines"),
            new("rename-rave", "rename-rave.ps1", "Preview batch renames with prefix, suffix, replace, and numbering.", "-Path .\\clips -Find \"take\" -Replace \"shot\"")
        ];
    }
}

internal sealed record ToolDefinition(string Name, string Script, string Description, string ExampleArgs);

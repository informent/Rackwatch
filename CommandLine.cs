using System.IO;
using System.Text.Json;
namespace Rackwatch;

public static class CommandLine
{
    public static int Run(string[] args)
    {
        if (args.Length < 5 || args[0] != "--scan") return 2;
        var options = new Dictionary<string, string>(StringComparer.Ordinal); var failOnFindings = false;
        for (var i = 1; i < args.Length; i++)
        {
            if (args[i] == "--fail-on-findings") { if (failOnFindings) return 2; failOnFindings = true; continue; }
            if (args[i] is not ("--folder" or "--output" or "--ports") || i + 1 == args.Length || !options.TryAdd(args[i], args[++i])) return 2;
        }
        if (!options.TryGetValue("--folder", out var root) || !options.TryGetValue("--output", out var output) || !output.EndsWith(".json", StringComparison.OrdinalIgnoreCase)) return 2;
        var ports = new List<int>();
        if (options.TryGetValue("--ports", out var text)) foreach (var part in text.Split(',')) { if (!int.TryParse(part, out var port) || port is < 1 or > 65535 || ports.Contains(port) || ports.Count >= 32) return 2; ports.Add(port); }
        string? temporary = null;
        try
        {
            var fullOutput = Path.GetFullPath(output); var fullRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root));
            if (File.Exists(fullOutput) || fullOutput.StartsWith(fullRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) return 2;
            if (!Directory.Exists(Path.GetDirectoryName(fullOutput))) return 2;
            using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(2));
            var result = ServerAudit.Scan(fullRoot, ports, timeout.Token);
            var report = AuditReport.Create(fullRoot, result);
            temporary = fullOutput + "." + Guid.NewGuid().ToString("N") + ".tmp";
            using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None)) JsonSerializer.Serialize(stream, report, new JsonSerializerOptions { WriteIndented = true });
            File.Move(temporary, fullOutput);
            return failOnFindings && (result.FindingCount > 0 || result.SkippedLinks > 0 || result.Ports.Any(p => !p.Open)) ? 3 : 0;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException or OperationCanceledException or System.Security.SecurityException) { return 1; }
        finally { if (temporary is not null && File.Exists(temporary)) File.Delete(temporary); }
    }
}

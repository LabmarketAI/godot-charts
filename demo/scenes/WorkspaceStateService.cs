using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

public partial class WorkspaceStateService : Node
{
	[Signal]
	public delegate void WorkspaceLoadedEventHandler(string workspaceName);

	[Signal]
	public delegate void WorkspaceListChangedEventHandler();

	private const string WorkspaceDir = "user://workspaces";
	private const string ActiveWorkspacePath = "user://workspaces/.active_workspace";

	public string ActiveWorkspaceName { get; private set; } = "";
	public Dictionary ActiveWorkspaceProfile { get; private set; } = new();

	public override void _Ready()
	{
		EnsureBootstrap();
	}

	public void EnsureBootstrap()
	{
		EnsureWorkspaceDir();

		var requested = ReadActiveWorkspaceName();
		if (string.IsNullOrWhiteSpace(requested) || !WorkspaceExists(requested))
		{
			if (!WorkspaceExists("default"))
				CreateWorkspace("default");
			requested = "default";
		}

		if (!LoadWorkspace(requested))
		{
			CreateWorkspace("default");
			LoadWorkspace("default");
		}
	}

	public string[] ListWorkspaceNames()
	{
		EnsureWorkspaceDir();
		var names = new List<string>();
		using var dir = DirAccess.Open(WorkspaceDir);
		if (dir == null)
			return System.Array.Empty<string>();

		dir.ListDirBegin();
		while (true)
		{
			var file = dir.GetNext();
			if (string.IsNullOrEmpty(file))
				break;
			if (dir.CurrentIsDir())
				continue;
			if (!file.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
				continue;
			names.Add(file[..^5]);
		}
		dir.ListDirEnd();
		names.Sort(StringComparer.OrdinalIgnoreCase);
		return names.ToArray();
	}

	public bool CreateWorkspace(string rawName)
	{
		var name = NormalizeName(rawName);
		if (string.IsNullOrEmpty(name) || WorkspaceExists(name))
			return false;

		var profile = BuildDefaultProfile(name);
		if (!WriteProfile(name, profile))
			return false;

		EmitSignal(SignalName.WorkspaceListChanged);
		if (string.IsNullOrEmpty(ActiveWorkspaceName))
			LoadWorkspace(name);
		return true;
	}

	public bool LoadWorkspace(string rawName)
	{
		var name = NormalizeName(rawName);
		if (string.IsNullOrEmpty(name))
			return false;
		if (!ReadProfile(name, out var profile))
			return false;

		ActiveWorkspaceName = name;
		ActiveWorkspaceProfile = profile;
		WriteActiveWorkspaceName(name);
		EmitSignal(SignalName.WorkspaceLoaded, name);
		return true;
	}

	public bool SaveActiveWorkspace(bool consoleVisible)
	{
		if (string.IsNullOrEmpty(ActiveWorkspaceName))
			return false;

		ActiveWorkspaceProfile["console_visible"] = consoleVisible;
		ActiveWorkspaceProfile["updated_utc"] = DateTime.UtcNow.ToString("o");
		return WriteProfile(ActiveWorkspaceName, ActiveWorkspaceProfile);
	}

	public bool DeleteWorkspace(string rawName)
	{
		var name = NormalizeName(rawName);
		if (string.IsNullOrEmpty(name) || !WorkspaceExists(name))
			return false;

		var path = WorkspaceFilePath(name);
		var err = DirAccess.RemoveAbsolute(path);
		if (err != Error.Ok)
			return false;

		var remaining = ListWorkspaceNames();
		if (remaining.Length == 0)
		{
			CreateWorkspace("default");
			remaining = ListWorkspaceNames();
		}

		if (name == ActiveWorkspaceName)
			LoadWorkspace(remaining.First());

		EmitSignal(SignalName.WorkspaceListChanged);
		return true;
	}

	private static string NormalizeName(string name)
	{
		if (string.IsNullOrWhiteSpace(name))
			return "";
		var sanitized = name.Trim();
		foreach (var c in System.IO.Path.GetInvalidFileNameChars())
			sanitized = sanitized.Replace(c, '_');
		return sanitized.Replace('/', '_').Replace('\\', '_');
	}

	private static Dictionary BuildDefaultProfile(string name)
	{
		var now = DateTime.UtcNow.ToString("o");
		return new Dictionary
		{
			{ "schema_version", 1 },
			{ "name", name },
			{ "created_utc", now },
			{ "updated_utc", now },
			{ "console_visible", false },
			{ "frames", new Godot.Collections.Array() },
		};
	}

	private static string WorkspaceFilePath(string name) => $"{WorkspaceDir}/{name}.json";

	private static void EnsureWorkspaceDir()
	{
		DirAccess.MakeDirRecursiveAbsolute(WorkspaceDir);
	}

	private static bool WorkspaceExists(string name)
	{
		return FileAccess.FileExists(WorkspaceFilePath(name));
	}

	private static bool WriteProfile(string name, Dictionary profile)
	{
		using var file = FileAccess.Open(WorkspaceFilePath(name), FileAccess.ModeFlags.Write);
		if (file == null)
			return false;
		file.StoreString(Json.Stringify(profile, "  "));
		return true;
	}

	private static bool ReadProfile(string name, out Dictionary profile)
	{
		profile = new Dictionary();
		var path = WorkspaceFilePath(name);
		if (!FileAccess.FileExists(path))
			return false;
		using var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);
		if (file == null)
			return false;

		var parsed = Json.ParseString(file.GetAsText());
		if (parsed.VariantType != Variant.Type.Dictionary)
			return false;

		profile = parsed.AsGodotDictionary();
		return true;
	}

	private static string ReadActiveWorkspaceName()
	{
		if (!FileAccess.FileExists(ActiveWorkspacePath))
			return "";
		using var file = FileAccess.Open(ActiveWorkspacePath, FileAccess.ModeFlags.Read);
		if (file == null)
			return "";
		return file.GetAsText().Trim();
	}

	private static void WriteActiveWorkspaceName(string name)
	{
		using var file = FileAccess.Open(ActiveWorkspacePath, FileAccess.ModeFlags.Write);
		if (file == null)
			return;
		file.StoreString(name);
	}
}

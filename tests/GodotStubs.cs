// Minimal stubs for Godot types referenced by CircuitLoader.
// Only used in the standalone NUnit test project; the real Godot build uses the actual types.

namespace Godot
{
    public static class GD
    {
        public static void PushWarning(string msg) { }
    }

    public static class ProjectSettings
    {
        public static string GlobalizePath(string path) => path;
    }
}

## 1. Standard-Godot CI

- [x] 1.1 Remove the obsolete .NET workflow job and orphaned C# test project.
- [x] 1.2 Make the M1 boundary audit work with or without ripgrep.
- [x] 1.3 Make visual-asset and M2 import validation wait for Godot import
  completion.
- [x] 1.4 Replace the M1 example's missing retired floor assets with a
  self-contained Godot mesh.

## 2. Verification

- [x] 2.1 Prove the boundary audit passes normally and rejects a fixture violation using its grep fallback.
- [x] 2.2 Run the visual-asset suite with standard Godot.
- [x] 2.3 Run addon synchronization and relevant standard-Godot CI scripts.
- [x] 2.4 Validate this OpenSpec strictly.

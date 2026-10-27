# Prototype baseline and ongoing development

Set up 27 October 2026 for **The Silent Keep: Moonlit Oath**.

## Versions

| Reference | Purpose |
| --- | --- |
| `main` | Stable, shareable game. Merge completed release work here. |
| `prototype-v0.1` | Annotated tag preserving this completed prototype, including rebranding and recent presentation/layout cleanup. Keep this tag fixed. |
| `develop` | Integration branch for the next version. |
| `feature/stage1-tutorial` | Next task: gradual, contextual introduction of the existing Stage 1 controls. |

All three branches initially point to the same prototype commit. The working folder is left on `feature/stage1-tutorial`. Creating the branch does not implement its tutorial task.

## Daily workflow

1. Work on the feature branch and commit small, descriptive changes.
2. Check the feature in Godot and record what was actually checked.
3. Merge completed work into `develop`.
4. When the next release is ready, merge `develop` into `main`, create a new version tag and export a new build.
5. Push branches/tags to GitHub to back up local commits.

Use `git status` before switching branches. Commit ongoing work before switching so edits stay associated with the intended task. In this single working folder, switching branches changes the files Godot opens; close a running game before switching.

## Returning to the prototype

For inspection, with a clean working tree: `git switch --detach prototype-v0.1`.

Return to ongoing work: `git switch feature/stage1-tutorial`.

To change the old prototype separately, create a new branch from the tag rather than moving the tag or resetting ongoing development.

## Playable backup

Windows release folder: `C:/Users/Owner/GodotRelease/prototype-v0.1/`.

ZIP: `C:/Users/Owner/GodotRelease/TheSilentKeep-MoonlitOath-prototype-v0.1-Windows.zip`.

The build folder contains the exported EXE/PCK and a README identifying the source commit. Builds stay outside the source project. Export completion does not establish that a full playthrough passed.

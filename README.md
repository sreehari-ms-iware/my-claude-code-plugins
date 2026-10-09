# My Claude Code plugins

The list of Claude Code marketplaces and plugins I use, with scripts to recreate the same set on
another machine. Logging in to Claude Code does not carry installed plugins across machines.

`plugins.json` holds only public identifiers: marketplace repositories and plugin names, with
whether each plugin is enabled. No settings, credentials, hooks or project data are stored here.

## Update the list

After adding, removing, enabling or disabling a plugin:

```powershell
.\backup.ps1
git add plugins.json
git commit -m "Update plugin list"
git push
```

## Set up a new machine

1. Install Claude Code and log in.
2. Clone this repository.
3. Run `.\restore.ps1`. Use `.\restore.ps1 -DryRun` first to see the commands it will run.
4. Restart Claude Code, or run `/reload-plugins`.

The script adds each marketplace, installs each plugin at user scope, and disables the ones marked
`"enabled": false`. A plugin whose marketplace is not in the list is reported at the end; install it
from the `/plugin` menu.

On macOS or Linux, run the same commands by hand:

```
claude plugin marketplace add <source>
claude plugin install <plugin-id> --scope user
claude plugin disable <plugin-id> --scope user
```

# USARF Area 51 v2

Rojo project for USARF Area 51 v2.

Only these Roblox service trees are managed by Rojo:

- `ReplicatedStorage`
- `ServerScriptService`
- `StarterPlayer`

The map, Workspace, StarterGui, StarterPack, ServerStorage, and other services remain managed in Roblox Studio.

## Development

Install the VS Code extensions Rojo, Luau Language Server, and StyLua. Then run:

```powershell
rokit install
rojo serve default.project.json
```

Open a development copy of the place in Roblox Studio, open the Rojo plugin, and connect to `localhost:34872`. Review the proposed changes before accepting the first sync.

Edit Rojo-managed scripts in VS Code. Test and publish from Roblox Studio.

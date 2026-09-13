-- Loaded first: it records the startup arguments before anything can alter
-- them. See lua/quiddam/session.lua.
require("quiddam.session")

require("quiddam.remap")
-- After remap.lua, which sets mapleader: this file maps <leader>z.
require("quiddam.vscode_debug")
require("quiddam.packer")
require("quiddam.set")

local ADDON_NAME = ...

local Core = _G.WoesAddonsCore or {}
_G.WoesAddonsCore = Core

Core.name = ADDON_NAME
Core.acronym = "WAC"
Core.version = "0.1"
Core.brandColor = Core.brandColor or "ffffd100"
Core.defaultIcon = Core.defaultIcon or "Interface\\Icons\\INV_Misc_Gear_01"

Core.modules = Core.modules or {}
Core.Internal = Core.Internal or {}
Core.Sounds = Core.Sounds or {}
Core.Media = Core.Media or {}
Core.Animation = Core.Animation or {}
Core.Tooltips = Core.Tooltips or {}
Core.Toasts = Core.Toasts or {}
Core.UI = Core.UI or {}
Core.UI.Windows = Core.UI.Windows or {}
Core.UI.Views = Core.UI.Views or {}
Core.UI.Widgets = Core.UI.Widgets or {}
Core.UI.Settings = Core.UI.Settings or {}

function Core:RegisterModule(name, module)
    if not name or not module then
        return module
    end

    self.modules[name] = module
    self[name] = module
    return module
end

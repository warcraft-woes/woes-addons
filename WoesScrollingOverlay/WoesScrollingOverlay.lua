local ADDON_NAME, addonTable = ...

local Overlay = addonTable or _G.WoesScrollingOverlay or {}
_G.WoesScrollingOverlay = Overlay

Overlay.name = ADDON_NAME
Overlay.displayName = "Woes Scrolling Overlay"
Overlay.Core = _G.WoesAddonsCore or {}
Overlay.Print = Overlay.Core.CreatePrinter and Overlay.Core.CreatePrinter(Overlay.displayName) or print

Overlay.Constants = Overlay.Constants or {}
Overlay.State = Overlay.State or {}
Overlay.Utils = Overlay.Utils or {}
Overlay.Theme = Overlay.Theme or {}
Overlay.DB = Overlay.DB or {}
Overlay.Skills = Overlay.Skills or {}
Overlay.Trackers = Overlay.Trackers or {}
Overlay.Providers = Overlay.Providers or {}
Overlay.Ticker = Overlay.Ticker or {}
Overlay.Editor = Overlay.Editor or {}
Overlay.Settings = Overlay.Settings or {}

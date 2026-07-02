local Core = _G.WoesAddonsCore

local Toasts = Core.Toasts

function Toasts.Show(message)
    Core.Print("Woes AddOns", message or "")
end

Core:RegisterModule("Toasts", Toasts)

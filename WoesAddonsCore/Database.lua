local Core = _G.WoesAddonsCore

Core.loadedAddons = Core.loadedAddons or {}
Core.loadedAddonOrder = Core.loadedAddonOrder or {
    "Core",
    "Chest Tracker",
    "Guild Artisans",
    "Hero Journey",
    "Scrolling Overlay",
}
Core.defaultOptions = Core.defaultOptions or {
    showLoadedMessage = true,
}

function Core.EnsureDB()
    if type(WoesAddonsCoreDB) ~= "table" then
        WoesAddonsCoreDB = {}
    end

    WoesAddonsCoreDB.options = Core.CopyDefaults(WoesAddonsCoreDB.options, Core.defaultOptions)
    Core.options = WoesAddonsCoreDB.options
    return Core.options
end

Core:RegisterModule("Database", {
    Ensure = Core.EnsureDB,
})

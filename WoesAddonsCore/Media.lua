local Core = _G.WoesAddonsCore

local Media = Core.Media

Media.textures = Media.textures or {
    defaultIcon = Core.defaultIcon,
    addonIcon = "Interface\\AddOns\\WoesAddonsCore\\Media\\Textures\\icon.blp",
}

function Media.GetTexture(key, fallback)
    return Media.textures[key] or fallback or Core.defaultIcon
end

Core:RegisterModule("Media", Media)

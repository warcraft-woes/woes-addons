local Core = _G.WoesAddonsCore

Core.Sounds.windowClose = Core.Sounds.windowClose or (SOUNDKIT and SOUNDKIT.IG_MAINMENU_CLOSE or 850)
Core.Sounds.buttonClick = Core.Sounds.buttonClick or (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
Core.buttonSoundsEnabled = Core.buttonSoundsEnabled ~= false

function Core.PlaySound(sound)
    if type(PlaySound) ~= "function" or not sound then
        return
    end

    PlaySound(sound)
end

function Core.Sounds.ResolveButtonSound(options)
    if options and options.sound == false then
        return nil
    end

    if options and options.sound and options.sound ~= true then
        return options.sound
    end

    if Core.buttonSoundsEnabled then
        return Core.Sounds.buttonClick
    end
end

function Core.Sounds.Play(sound)
    Core.PlaySound(sound)
end

Core:RegisterModule("Sounds", Core.Sounds)

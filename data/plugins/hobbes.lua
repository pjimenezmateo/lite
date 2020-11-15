local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

-- For Windows need to add git.exe to path
    -- C:\Users\Gef\AppData\Local\GitHubDesktop\app-2.5.7\resources\app\git\cmd

local hobbes = {}

-- Uses the correct git string depending on the OS
function hobbes.platform_git()

    if PLATFORM == "Windows" then
        system.exec("git pull; git add .; git commit -m \"Hobbes sync\"; git push")
    else
        system.exec("(git pull; git add .; git commit -m \"Hobbes sync\"; git push)")
    end
end

-- Returns the correct path separator depending on the OS
function hobbes.separator()

    if PLATFORM == "Windows" then
        return "\\"
    else
        return "/"
    end
end

-- Goes through each folder, pulls and pushes
function hobbes.git_sync()

    core.log("Syncing")

    local hobbes_path = system.absolute_path(".")

    local dirs = system.list_dir(hobbes_path)
    
    for _, filename in ipairs(system.list_dir(hobbes_path)) do

        system.chdir(filename)

        -- Chech that there is actually a git folder
        if system.get_file_info(".git") then

          core.log("Syncthing %s", filename)       
          
          -- For Windows the ; should be &
          hobbes.platform_git()
        end

        -- Return to the hobbes path
        system.chdir(hobbes_path)
    end
end


-- Checks if the clipboard contains a filepath
function hobbes.file_drop(dropped_path)

    print("Dropping ")

    -- Get the current open file path
    local doc = core.active_view.doc

    -- print("Active view name " .. core.active_view:get_name())

    if not doc.filename then
      core.error "Cannot copy location of unsaved doc"
      return
    end

    local current_path = system.absolute_path(doc.filename)
    local hobbes_path  = system.absolute_path(".")

    -- Move to the current path
    local cur_filename = string.match(doc.filename, '/.+%.md')
    -- print('Cur filename ' .. cur_filename)
    system.chdir(string.gsub(current_path, cur_filename, ""))

    -- print("Before moving " .. system.absolute_path("."))
    
    if system.get_file_info(".attachments") then

        -- Get the correct new name and path
        local dropped_filename = string.gsub(dropped_path, dropped_path:match("^(.*)[/\\].*$"), "")
        local new_path = system.absolute_path(".") .. "/.attachments" .. dropped_filename

        print("The new path would be " .. new_path)

        -- Read original file and create the new one
        local input_file  = io.open(dropped_path, "rb")
        local output_file = io.open(new_path, "wb")

        -- Read all the data
        local data = input_file:read("*all")
        output_file:write(data)

        input_file:close()
        output_file:close()

        -- Compute the relative path
        local _, count = string.gsub(cur_filename, "/", "")
        local rel_path = string.rep("../", count-1) .. ".attachments" .. dropped_filename

        print ("Rel path " .. rel_path)

        doc:text_input(rel_path)
    end

    system.chdir(hobbes_path)
end

command.add(nil, {
    ["hobbes:git-sync"] = hobbes.git_sync
})

keymap.add {
    ["ctrl+shift+h"] = "hobbes:git-sync"
}

return hobbes

local sprite = app.activeSprite


-- Check constrains
if sprite == nil then
  app.alert("No Sprite...")
  return
end
if sprite.colorMode ~= ColorMode.INDEXED then
  app.alert("Sprite needs to be indexed")
  return
end

if (sprite.width % 8) ~= 0 then
  app.alert("Sprite width needs to be a multiple of 8")
  return
end

if (sprite.height % 8) ~= 0 then
  app.alert("Sprite height needs to be a multiple of 8")
  return
end

local function getTileData(img, x, y)
    local res = ""

    for  cy = 0, 7 do
        local hi = 0
        local lo = 0

        for cx = 0, 7 do
            px = img:getPixel(cx+x, cy+y)
            

            if (px & 1) ~= 0 then
                lo = lo | (1 << 7-cx)
            end
            if (px & 2) ~= 0 then
                hi = hi | (1 << 7-cx)
            end
        end
        res = res .. string.format("$%02x, $%02x", lo, hi)
        if cy < 7 then
            res = res .. ", "
        end
        
    end

    return "DB " .. res .. "\n"
end

local spriteLookup = {}
local lastLookupId = 0

local function exportFrame(useLookup, frm)
    if frm == nil then
        frm = 1
    end

    local img = Image(sprite.spec)
    img:drawSprite(sprite, frm)

    local result = {}

    for x = 0, sprite.width-1, 8 do
        local column = {}
        for y = 0, sprite.height-1, 8 do
            local data = getTileData(img, x, y)
            local id = 0
            if useLookup then
                id = spriteLookup[data]
                if id == nil then
                    id = lastLookupId + 1
                    lastLookupId = id

                    spriteLookup[data] = id
                else
                    data = nil
                end 
            else
                id = lastLookupId + 1
                lastLookupId = id
            end
            table.insert(column, id)
            if data ~= nil then
                io.write(data)
            end
        end
        table.insert(result, column)
    end

    return result
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local dlg = Dialog()
dlg:file{ id="exportFile",
          label="File",
          title="Gameboy-Assembler Export",
          open=false,
          save=true,
        --filename= p .. fn .. "asm",
          filetypes={"asm", "inc", "z80" }}
dlg:file{ id="mapFile",
          label="Tile-Map-File",
          title="Gameboy-Assembler Export",
          open=false,
          save=true,
        --filename= p .. fn .. "asm",
          filetypes={"asm", "inc", "z80" }}

dlg:check{ id="onlyCurrentFrame",
           text="Export only current frame",
           selected=true }
dlg:check{ id="removeDuplicates",
           text="Remove duplicate tiles",
           selected=false}

dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()
local data = dlg.data
if data.ok then
    local f = io.open(data.exportFile, "w")
    io.output(f)

    local mapData = {}

    if data.onlyCurrentFrame then
        table.insert(mapData, exportFrame(data.removeDuplicates, app.activeFrame))
    else
        for i = 1,#sprite.frames do
            io.write(string.format(";Frame %d\n", i))
            table.insert(mapData, exportFrame(data.removeDuplicates, i))
        end
    end

    io.close(f)

    if data.mapFile ~= nil then
        
        local mf = io.open(data.mapFile, "w")


        for frameNo, frameMap in ipairs(mapData) do 
            if #mapData > 1 then
                mf:write(string.format(";Frame %d\n", frameNo))
            end

            for y = 1, #frameMap[1] do
                mf:write("DB ")
                for x = 1, #frameMap do
                    if x > 1 then
                        mf:write(", ")
                    end

                    mf:write(string.format("$%02x", frameMap[x][y]))
                end
                mf:write("\n")
            end
        end
        mf:close()
    end

    
end

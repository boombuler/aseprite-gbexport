local sprite = app.activeSprite


-- Check constraints
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

local function exportFrame(frm)
	if frm == nil then
		frm = 1
	end

	local img = Image(sprite.spec)
	img:drawSprite(sprite, frm)

	for x = 0, sprite.width-1, 8 do
		for y = 0, sprite.height-1, 8 do
			io.write(getTileData(img, x, y))
		end
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
dlg:check{ id="onlyCurrentFrame",
           text="Export only current frame",
           selected=true }

dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()
local data = dlg.data
if data.ok then
	local f = io.open(data.exportFile, "w")
	io.output(f)

	if data.onlyCurrentFrame then
		exportFrame(app.activeFrame)
	else
	 	for i = 1,#sprite.frames do
	 		io.write(string.format(";Frame %d\n", i))
	 		exportFrame(i)
		end
	end

	io.close(f)
end

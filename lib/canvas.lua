color = {}
local colorMt = {}
local colorPrototype = {type = "color"}

-- create a new color object
function color.new(elements)
   local elements = elements or {}
   local x = {}
   for k, v in pairs(colorPrototype) do
      x[k] = v
   end
   setmetatable(x, colorMt)
   x[4] = 1.0
   for i, e in ipairs(elements) do
      x[i] = e
   end
   return x
end


local function __call(_, ...)
   local args = {...}
   -- allow users to create a color from a flat table
   if type(args[1]) == "table" then
      args = args[1]
   end
   return color.new(args)
end
setmetatable(color, {__call=__call})

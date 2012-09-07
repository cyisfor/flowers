-- Flowers mod by VanessaE, 2012-08-01
-- Rewritten from Ironzorg's last update, 
-- as included in Nature Pack Controlled
--
-- License:  WTFPL (applies to all parts and textures)
--


local DEBUG = 1

local GROWING_DELAY = 500 -- larger numbers = ABM runs less often
local GROWCHANCE = 50 -- larger = less chance to grow

local DI = 5 -- base distance

local perlin = nil

local function weightedPick(l,pos)
   if perlin == nil then
      perlin = minetest.env:get_perlin(666, 1, 0, 50)
   end
   local tweight = 0
   for i,item in ipairs(l) do
      tweight = tweight + item.weight
   end
   -- somewhere between totally random and perlin
   --local pppp = (perlin:get2d({x=pos.x,y=pos.z})+1)/2
   local where = math.random()
   --print("HMMM "..pppp.." => "..where)
   where = tweight * where
   tweight = 0
   for i,item in ipairs(l) do
      tweight = tweight + item.weight
      if (where <= tweight) then
         return item
      end
   end
   return l[#l]
end

local dbg =
   function(s)
      if DEBUG == 1 then
         print("[FLOWERS] " .. s)
      end
   end

local is_node_loaded = function(node_pos)
	n = minetest.env:get_node_or_nil(node_pos)
	if (n == nil) or (n.name == "ignore") then
		return false
	end
	return true
 end

function nodeNear(top,radius,avoid)
   if type(avoid)=='string' then
      avoid = {avoid}
   elseif type(avoid)=='function' then
      return avoid(top,radius)
   end
   for what in ipairs(avoid) do
      if minetest.env:find_node_near(top, radius, avoid) then
         return true
      end
   end
   return false
end

local defaultRegisterArgs =
   {
   drawtype = "plantlike",
   sunlight_propagates = true,
   paramtype = "light",
   walkable = false,
   groups = { snappy = 3,flammable=2, flower=1 },
   sounds = default.node_sound_leaves_defaults(),
   selection_box = {
      type = "fixed",
      fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
   }
}

function table.clone(l)
   local nl = {}
   for n,v in pairs(l) do
      nl[n] = v
   end
   return nl
end

local external = {}

local function spawnOn(what)
   local flowers = {}
   function add(flower)
      dbg("adding "..flower.name)
      flower.id = flower.id or "flowers:flower_"..flower.name
      flower.fails = flower.fails or 0.10
      if flower.register == nil or flower.register ~= external then
         local registerargs = table.clone(defaultRegisterArgs)
         if flower.register then
            for name,value in pairs(flower.register) do
               registerargs[name] = value
            end
         end
         registerargs['tiles'] = registerargs['tiles'] or
            { "flower_"..flower.name..".png" }
         registerargs['inventory_image'] = registerargs['inventory_image'] or
            "flower_"..flower.name..".png"
         registerargs['wield_image'] = registerargs['wield_image'] or
            "flower_"..flower.name..".png"
         registerargs['description'] = flower.description
         minetest.register_node(flower.id, registerargs)
      end
      if flower.weight == nil then
         flower.weight = 1 / flower.rarity
      end
      if flower.avoid == nil then
         flower.avoid = flower.id
      end
      table.insert(flowers,flower)
   end

   if type(what) == 'string' then
      what = {what}
   end

   local function pickAFlower(pos,node)
      return weightedPick(flowers,pos)
   end

   minetest.register_abm(
      {
         nodenames = what,
         interval = GROWING_DELAY,
         chance = GROWCHANCE,
         action =
            function(pos, node, active_object_count, active_object_count_wider)
               local flower = pickAFlower(pos,node)

               if flower == nil then return end
               if math.random() < flower.fails then return end
               local p_top = { x = pos.x, y = pos.y + 1, z = pos.z }
               local n_top = minetest.env:get_node(p_top)
               if (n_top.name == "air") and is_node_loaded(p_top) then
                  if (not nodeNear(p_top,flower.radius,flower.avoid)) then
                     local n_light = minetest.env:get_node_light(p_top, nil)
                     if (n_light > 4) then
                        if (flower.additionalConditions == nil
                            or flower.additionalConditions(p_top,n_top,n_light)) then
                           dbg("Spawning "..flower.name.." at ("..p_top.x..", "..p_top.y..", "..p_top.z..") on "..node.name)
                           minetest.env:add_node(p_top, { name = flower.id })
                        end
                     end
                  end
               end
            end
      })
   return add
end

addFlower = spawnOn({"default:dirt_with_grass","default:dirt"})
addSeaFlower = spawnOn("default:water_source")
addSandFlower = spawnOn("group:sand")

addFlower(
   { description = "Rose",
     name = "rose",
     rarity = 3,
     radius = DI*3
  })
addFlower(
   { description = "Tulip",
     name = "tulip",
     rarity = 1,
     radius = DI*2
  })
addFlower(
   { description = "Yellow Dandelion",
     name = "dandelion_yellow",
     rarity = 1,
     radius = DI*2
  })
addFlower(
   { description = "White Dandelion",
     name = "dandelion_white",
     rarity = 2,
     radius = DI*3
  })
addFlower(
   { description = "Blue Geranium",
     name = "geranium",
     rarity = 3,
     radius = DI*2
  })
addFlower(
   { description = "Viola",
     name = "viola",
     rarity = 2,
     radius = DI*3
  })
addFlower(
   { description = "Cotton Plant",
     name = "cotton",
     rarity = 1,
     radius = DI*2
  })

addFlower(
   { description = "Tree Sapling",
     id = "default:sapling",
     name = "sapling",
     register = external,
     rarity = 3,
     radius = DI*10,
     avoid = {"default:sapling","group:tree"}
  })

addFlower(
   { description = "Papyrus",
     id = "default:papyrus",
     name = "papyrus",
     register = external,
     rarity = 1,
     radius = DI,
     additionalConditions =
        function(pos,node,light)
           return nodeNear({x=pos.x,y=pos.y-1,z=pos.z},1,"group:water")
        end
  })

addSandFlower(
   { description = "Cactus",
     id = "default:cactus",
     name = "cactus",
     register = external,
     rarity = 5,
     radius = DI*25,
  })

addSandFlower(
   { description = "Dry brush",
     id = "default:dry_shrub",
     name = "shrub",
     register = external,
     rarity = 1,
     radius = DI*5
  })

addSeaFlower(
   { description = "Waterlily",
     name = "waterlily",
     rarity = 3,
     radius = DI*3,
     register = {
        drawtype = "raillike",
        paramtype2 = "wallmounted",
        selection_box = {
           type = "fixed",
           fixed = { -0.4, -0.5, -0.4, 0.4, -0.45, 0.4 },
        }
     }
  })

addSeaFlower(
   { description = "Seaweed",
     name = "seaweed",
     rarity = 1,
     radius = DI,
     avoid = "flowers:flower_seaweed",
     register = {
        drawtype = "signlike",
        paramtype2 = "wallmounted",
        selection_box = {
           type = "fixed",
           fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 },
        }
     },
     additionalConditions =
        function(pos,node,light)
           if light > 10 then return false end
           return nodeNear(pos,1,{"default:dirt", "default:dirt_with_grass", "default:stone"})
        end
  })

-- Additional crafts, etc.

minetest.register_craftitem("flowers:flower_pot", {
        description = "Flower Pot",
        inventory_image = "flower_pot.png",
})

minetest.register_craft( {
        output = "flowers:flower_pot",
        recipe = {
                { "default:clay_brick", "", "default:clay_brick" },
                { "", "default:clay_brick", "" }
        },
})

minetest.register_craftitem("flowers:cotton", {
    description = "Cotton",
    image = "cotton.png",
})

minetest.register_craft({
    output = "flowers:cotton 3",
    recipe ={
        {"flowers:flower_cotton"},
    }
})

print("[Flowers] Loaded!")

/obj/item/stack/tile
	name = "broken tile"
	singular_name = "broken tile"
	desc = "A broken tile. This should not exist."
	lefthand_file = 'icons/mob/inhands/misc/tiles_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/tiles_righthand.dmi'
	icon = 'icons/obj/tiles.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	force = 1
	throwforce = 1
	throw_speed = 3
	throw_range = 7
	max_amount = 60
	novariants = TRUE
	/// What type of turf does this tile produce.
	var/turf_type = null
	/// Determines certain welder interactions.
	var/mineralType = null
	/// Cached associative lazy list to hold the radial options for tile reskinning. See tile_reskinning.dm for more information. Pattern: list[type] -> image
	var/list/tile_reskin_types


/obj/item/stack/tile/Initialize(mapload, amount)
	. = ..()
	pixel_x = rand(-3, 3)
	pixel_y = rand(-3, 3) //randomize a little
	if(tile_reskin_types)
		tile_reskin_types = tile_reskin_list(tile_reskin_types)


/obj/item/stack/tile/examine(mob/user)
	. = ..()
	if(throwforce && !is_cyborg) //do not want to divide by zero or show the message to borgs who can't throw
		var/verb
		switch(CEILING(MAX_LIVING_HEALTH / throwforce, 1)) //throws to crit a human
			if(1 to 3)
				verb = "superb"
			if(4 to 6)
				verb = "great"
			if(7 to 9)
				verb = "good"
			if(10 to 12)
				verb = "fairly decent"
			if(13 to 15)
				verb = "mediocre"
		if(!verb)
			return
		. += span_notice("Those could work as a [verb] throwing weapon.")


/obj/item/stack/tile/attackby(obj/item/W, mob/user, params)

	if (W.tool_behaviour == TOOL_WELDER)
		if(get_amount() < 4)
			to_chat(user, span_warning("You need at least four tiles to do this!"))
			return

		if(!mineralType)
			to_chat(user, span_warning("You can not reform this!"))
			return

		if(W.use_tool(src, user, 0, volume=40))
			if(mineralType == "plasma")
				atmos_spawn_air("plasma=5;TEMP=1000")
				user.visible_message(span_warning("[user.name] sets the plasma tiles on fire!"), \
									span_warning("You set the plasma tiles on fire!"))
				qdel(src)
				return

			if (mineralType == "metal")
				var/obj/item/stack/sheet/metal/new_item = new(user.loc)
				user.visible_message(
					span_notice("[user.name] shaped [src] into metal with the welding tool."),
					span_notice("You shaped [src] into metal with the welding tool."),
					span_hear("You hear welding.")
				)
				var/obj/item/stack/rods/R = src
				src = null
				var/replace = (user.get_inactive_held_item()==R)
				R.use(4)
				if (!R && replace)
					user.put_in_hands(new_item)

			else
				var/sheet_type = text2path("/obj/item/stack/sheet/mineral/[mineralType]")
				var/obj/item/stack/sheet/mineral/new_item = new sheet_type(user.loc)
				user.visible_message(
					span_notice("[user.name] shaped [src] into a sheet with the welding tool."),
					span_notice("You shaped [src] into a sheet with the welding tool."),
					span_hear("You hear welding.")
				)
				var/obj/item/stack/rods/R = src
				src = null
				var/replace = (user.get_inactive_held_item()==R)
				R.use(4)
				if (!R && replace)
					user.put_in_hands(new_item)
	else
		return ..()

//Grass
/obj/item/stack/tile/grass
	name = "grass tile"
	singular_name = "grass floor tile"
	desc = "A patch of grass like they use on space golf courses."
	icon_state = "tile_grass"
	item_state = "tile-grass"
	turf_type = /turf/open/floor/grass
	resistance_flags = FLAMMABLE

//Fairygrass
/obj/item/stack/tile/fairygrass
	name = "fairygrass tile"
	singular_name = "fairygrass floor tile"
	desc = "A patch of odd, glowing blue grass."
	icon_state = "tile_fairygrass"
	item_state = "tile-fairygrass"
	turf_type = /turf/open/floor/grass/fairy
	resistance_flags = FLAMMABLE

//Wood
/obj/item/stack/tile/wood
	name = "wood floor tile"
	singular_name = "wood floor tile"
	desc = "An easy to fit wood floor tile."
	icon_state = "tile-wood"
	item_state = "tile-wood"
	turf_type = /turf/open/floor/wood
	resistance_flags = FLAMMABLE
	color = WOOD_COLOR_GENERIC
	tile_reskin_types = list(
		/obj/item/stack/tile/wood,
		/obj/item/stack/tile/wood/mahogany,
		/obj/item/stack/tile/wood/maple,
		/obj/item/stack/tile/wood/ebony,
		/obj/item/stack/tile/wood/walnut,
		/obj/item/stack/tile/wood/bamboo,
		/obj/item/stack/tile/wood/birch,
		/obj/item/stack/tile/wood/yew
		)

/obj/item/stack/tile/wood/mahogany
	name = "mahogany wood floor tile"
	color = WOOD_COLOR_RICH
	turf_type = /turf/open/floor/wood/mahogany
	merge_type = /obj/item/stack/tile/wood/mahogany


/obj/item/stack/tile/wood/maple
	name = "maple wood floor tile"
	color = WOOD_COLOR_PALE
	turf_type = /turf/open/floor/wood/maple
	merge_type = /obj/item/stack/tile/wood/maple

/obj/item/stack/tile/wood/ebony
	name = "ebony wood floor tile"
	color = WOOD_COLOR_BLACK
	turf_type = /turf/open/floor/wood/ebony
	merge_type = /obj/item/stack/tile/wood/ebony

/obj/item/stack/tile/wood/walnut
	name = "walnut wood floor tile"
	color = WOOD_COLOR_CHOCOLATE
	turf_type = /turf/open/floor/wood/walnut
	merge_type = /obj/item/stack/tile/wood/walnut

/obj/item/stack/tile/wood/bamboo
	name = "bamboo wood floor tile"
	color = WOOD_COLOR_PALE2
	turf_type = /turf/open/floor/wood/bamboo
	merge_type = /obj/item/stack/tile/wood/bamboo

/obj/item/stack/tile/wood/birch
	name = "birch wood floor tile"
	color = WOOD_COLOR_PALE3
	turf_type = /turf/open/floor/wood/bamboo
	merge_type = /obj/item/stack/tile/wood/bamboo

/obj/item/stack/tile/wood/yew
	name = "yew wood floor tile"
	color = WOOD_COLOR_YELLOW
	turf_type = /turf/open/floor/wood/yew
	merge_type = /obj/item/stack/tile/wood/yew

//Basalt
/obj/item/stack/tile/basalt
	name = "basalt tile"
	singular_name = "basalt floor tile"
	desc = "Artificially made ashy soil themed on a hostile environment."
	icon_state = "tile_basalt"
	item_state = "tile-basalt"
	turf_type = /turf/open/floor/grass/fakebasalt

//Carpets
/obj/item/stack/tile/carpet
	name = "carpet"
	singular_name = "carpet"
	desc = "A piece of carpet. It is the same size as a floor tile."
	icon_state = "tile-carpet"
	item_state = "tile-carpet"
	turf_type = /turf/open/floor/carpet
	resistance_flags = FLAMMABLE
	tableVariant = /obj/structure/table/wood/fancy

/obj/item/stack/tile/carpet/red_gold
	name = "fancy red carpet"
	icon_state = "tile-carpet-red_gold"
	item_state = "tile-carpet-red_gold"
	turf_type = /turf/open/floor/carpet/red_gold
	tableVariant = /obj/structure/table/wood/fancy/red_gold

/obj/item/stack/tile/carpet/black
	name = "black carpet"
	icon_state = "tile-carpet-black"
	item_state = "tile-carpet-black"
	turf_type = /turf/open/floor/carpet/black
	tableVariant = /obj/structure/table/wood/fancy/black

/obj/item/stack/tile/carpet/blue
	name = "blue carpet"
	icon_state = "tile-carpet-blue"
	item_state = "tile-carpet-blue"
	turf_type = /turf/open/floor/carpet/blue
	tableVariant = /obj/structure/table/wood/fancy/blue

/obj/item/stack/tile/carpet/cyan
	name = "cyan carpet"
	icon_state = "tile-carpet-cyan"
	item_state = "tile-carpet-cyan"
	turf_type = /turf/open/floor/carpet/cyan
	tableVariant = /obj/structure/table/wood/fancy/cyan

/obj/item/stack/tile/carpet/green
	name = "green carpet"
	icon_state = "tile-carpet-green"
	item_state = "tile-carpet-green"
	turf_type = /turf/open/floor/carpet/green
	tableVariant = /obj/structure/table/wood/fancy/green

/obj/item/stack/tile/carpet/orange
	name = "orange carpet"
	icon_state = "tile-carpet-orange"
	item_state = "tile-carpet-orange"
	turf_type = /turf/open/floor/carpet/orange
	tableVariant = /obj/structure/table/wood/fancy/orange

/obj/item/stack/tile/carpet/purple
	name = "purple carpet"
	icon_state = "tile-carpet-purple"
	item_state = "tile-carpet-purple"
	turf_type = /turf/open/floor/carpet/purple
	tableVariant = /obj/structure/table/wood/fancy/purple

/obj/item/stack/tile/carpet/red
	name = "red carpet"
	icon_state = "tile-carpet-red"
	item_state = "tile-carpet-red"
	turf_type = /turf/open/floor/carpet/red
	tableVariant = /obj/structure/table/wood/fancy/red

/obj/item/stack/tile/carpet/royalblack
	name = "royal black carpet"
	icon_state = "tile-carpet-royalblack"
	item_state = "tile-carpet-royalblack"
	turf_type = /turf/open/floor/carpet/royalblack
	tableVariant = /obj/structure/table/wood/fancy/royalblack

/obj/item/stack/tile/carpet/royalblue
	name = "royal blue carpet"
	icon_state = "tile-carpet-royalblue"
	item_state = "tile-carpet-royalblue"
	turf_type = /turf/open/floor/carpet/royalblue
	tableVariant = /obj/structure/table/wood/fancy/royalblue

/obj/item/stack/tile/carpet/executive
	name = "executive carpet"
	icon_state = "tile_carpet_executive"
	item_state = "tile-carpet-royalblue"
	turf_type = /turf/open/floor/carpet/executive

/obj/item/stack/tile/carpet/stellar
	name = "stellar carpet"
	icon_state = "tile_carpet_stellar"
	item_state = "tile-carpet-royalblue"
	turf_type = /turf/open/floor/carpet/stellar

/obj/item/stack/tile/carpet/donk
	name = "donk co promotional carpet"
	icon_state = "tile_carpet_donk"
	item_state = "tile-carpet-orange"
	turf_type = /turf/open/floor/carpet/donk

/obj/item/stack/tile/carpet/nanoweave
	name = "nanoweave carpet"
	icon = 'icons/obj/tiles.dmi'
	desc = "A piece of nanoweave carpet."
	icon_state = "dark_carpet_tile"
	custom_materials = list(/datum/material/iron=500, /datum/material/plasma=500) //basically tiles made of plasteel
	resistance_flags = FIRE_PROOF
	turf_type = /turf/open/floor/carpet/nanoweave

/obj/item/stack/tile/carpet/nanoweave/red
	name = "nanoweave carpet (red)"
	icon_state = "red_carpet_tile"
	turf_type = /turf/open/floor/carpet/nanoweave/red

/obj/item/stack/tile/carpet/nanoweave/blue
	name = "nanoweave carpet (blue)"
	icon_state = "blue_carpet_tile"
	turf_type = /turf/open/floor/carpet/nanoweave/blue

/obj/item/stack/tile/carpet/nanoweave/purple
	name = "nanoweave carpet (purple)"
	icon_state = "purple_carpet_tile"
	turf_type = /turf/open/floor/carpet/nanoweave/purple

/obj/item/stack/tile/carpet/nanoweave/orange
	name = "nanoweave carpet (orange)"
	icon_state = "orange_carpet_tile"
	turf_type = /turf/open/floor/carpet/nanoweave/orange

/obj/item/stack/tile/carpet/nanoweave/beige
	name = "nanoweave carpet (beige)"
	icon_state = "beige_carpet_tile"
	turf_type = /turf/open/floor/carpet/nanoweave/beige

/obj/item/stack/tile/carpet/fifty
	amount = 50

/obj/item/stack/tile/carpet/black/fifty
	amount = 50

/obj/item/stack/tile/carpet/blue/fifty
	amount = 50

/obj/item/stack/tile/carpet/cyan/fifty
	amount = 50

/obj/item/stack/tile/carpet/green/fifty
	amount = 50

/obj/item/stack/tile/carpet/orange/fifty
	amount = 50

/obj/item/stack/tile/carpet/purple/fifty
	amount = 50

/obj/item/stack/tile/carpet/red/fifty
	amount = 50

/obj/item/stack/tile/carpet/royalblack/fifty
	amount = 50

/obj/item/stack/tile/carpet/royalblue/fifty
	amount = 50


/obj/item/stack/tile/fakespace
	name = "astral carpet"
	singular_name = "astral carpet"
	desc = "A piece of carpet with a convincing star pattern."
	icon_state = "tile_space"
	item_state = "tile-space"
	turf_type = /turf/open/floor/fakespace
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/tile/fakespace

/obj/item/stack/tile/fakespace/loaded
	amount = 30

/obj/item/stack/tile/fakepit
	name = "fake pits"
	singular_name = "fake pit"
	desc = "A piece of carpet with a forced perspective illusion of a pit. No way this could fool anyone!"
	icon_state = "tile_pit"
	item_state = "tile-basalt"
	turf_type = /turf/open/floor/fakepit
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/tile/fakepit

/obj/item/stack/tile/fakepit/loaded
	amount = 30

//High-traction
/obj/item/stack/tile/noslip
	name = "high-traction floor tile"
	singular_name = "high-traction floor tile"
	desc = "A high-traction floor tile. It feels rubbery in your hand."
	icon_state = "tile_noslip"
	item_state = "tile-noslip"
	turf_type = /turf/open/floor/noslip
	merge_type = /obj/item/stack/tile/noslip

/obj/item/stack/tile/noslip/thirty
	amount = 30

//Circuit
/obj/item/stack/tile/circuit
	name = "blue circuit tile"
	singular_name = "blue circuit tile"
	desc = "A blue circuit tile."
	icon_state = "tile_bcircuit"
	item_state = "tile-bcircuit"
	turf_type = /turf/open/floor/circuit
	custom_materials = list(/datum/material/iron = 500, /datum/material/glass = 500) // WS Edit - Item Materials
	tile_reskin_types = list(
		/obj/item/stack/tile/circuit,
		/obj/item/stack/tile/circuit/green,
		/obj/item/stack/tile/circuit/red
		)

/obj/item/stack/tile/circuit/green
	name = "green circuit tile"
	singular_name = "green circuit tile"
	desc = "A green circuit tile."
	icon_state = "tile_gcircuit"
	item_state = "tile-gcircuit"
	turf_type = /turf/open/floor/circuit/green

/obj/item/stack/tile/circuit/green/anim
	turf_type = /turf/open/floor/circuit/green/anim

/obj/item/stack/tile/circuit/red
	name = "red circuit tile"
	singular_name = "red circuit tile"
	desc = "A red circuit tile."
	icon_state = "tile_rcircuit"
	item_state = "tile-rcircuit"
	turf_type = /turf/open/floor/circuit/red

/obj/item/stack/tile/circuit/red/anim
	turf_type = /turf/open/floor/circuit/red/anim

//Pod floor
/obj/item/stack/tile/pod
	name = "pod floor tile"
	singular_name = "pod floor tile"
	desc = "A grooved floor tile."
	icon_state = "tile_pod"
	item_state = "tile-pod"
	turf_type = /turf/open/floor/pod
	tile_reskin_types = list(
		/obj/item/stack/tile/pod,
		/obj/item/stack/tile/pod/light,
		/obj/item/stack/tile/pod/dark
		)

/obj/item/stack/tile/pod/light
	name = "light pod floor tile"
	singular_name = "light pod floor tile"
	desc = "A lightly colored grooved floor tile."
	icon_state = "tile_podlight"
	turf_type = /turf/open/floor/pod/light

/obj/item/stack/tile/pod/dark
	name = "dark pod floor tile"
	singular_name = "dark pod floor tile"
	desc = "A darkly colored grooved floor tile."
	icon_state = "tile_poddark"
	turf_type = /turf/open/floor/pod/dark

//Plasteel (normal)
/obj/item/stack/tile/plasteel
	name = "floor tile"
	singular_name = "floor tile"
	desc = "The ground you walk on."
	icon_state = "tile"
	item_state = "tile"
	force = 6
	custom_materials = list(/datum/material/iron=500)
	throwforce = 10
	flags_1 = CONDUCT_1
	turf_type = /turf/open/floor/plasteel
	mineralType = "metal"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 70)
	resistance_flags = FIRE_PROOF
	color = COLOR_FLOORTILE_GRAY
	tile_reskin_types = list(
		/obj/item/stack/tile/plasteel,
		/obj/item/stack/tile/plasteel/dark,
		/obj/item/stack/tile/plasteel/white,
		/obj/item/stack/tile/plasteel/tech,
		/obj/item/stack/tile/plasteel/tech/grid,
		/obj/item/stack/tile/plasteel/tech/techmaint
		)

/obj/item/stack/tile/plasteel/cyborg
	custom_materials = null // All other Borg versions of items have no Metal or Glass - RR
	is_cyborg = 1
	cost = 125

/obj/item/stack/tile/plastic
	name = "plastic tile"
	singular_name = "plastic floor tile"
	desc = "A tile of cheap, flimsy plastic flooring."
	icon_state = "tile_plastic"
	custom_materials = list(/datum/material/plastic=500)
	turf_type = /turf/open/floor/plastic

/obj/item/stack/tile/plasteel/dark
	name = "dark tile"
	turf_type = /turf/open/floor/plasteel/dark
	merge_type = /obj/item/stack/tile/plasteel/dark
	color = COLOR_TILE_GRAY

/obj/item/stack/tile/plasteel/white
	name = "white tile"
	turf_type = /turf/open/floor/plasteel/white
	merge_type = /obj/item/stack/tile/plasteel/white
	color = COLOR_WHITE

/obj/item/stack/tile/plasteel/grimy
	name = "grimy floor tile"
	turf_type = /turf/open/floor/plasteel/grimy
	merge_type = /obj/item/stack/tile/plasteel/grimy
	color = null

/obj/item/stack/tile/plasteel/tech
	name = "techfloor tile"
	icon_state = "tile_podlight"
	turf_type = /turf/open/floor/plasteel/tech
	merge_type = /obj/item/stack/tile/plasteel/tech
	color = null

/obj/item/stack/tile/plasteel/tech/grid
	name = "techfloor grid tile"
	icon_state = "tile_poddark"
	turf_type = /turf/open/floor/plasteel/tech/grid
	merge_type = /obj/item/stack/tile/plasteel/tech/grid
	color = null

/obj/item/stack/tile/plasteel/tech/techmaint
	name = "techmaint tile"
	icon_state = "tile_pod"
	turf_type = /turf/open/floor/plasteel/tech/techmaint
	merge_type = /obj/item/stack/tile/plasteel/tech/techmaint
	color = null

/obj/item/stack/tile/material
	name = "floor tile"
	singular_name = "floor tile"
	desc = "The ground you walk on."
	throwforce = 10
	icon_state = "material_tile"
	turf_type = /turf/open/floor/material
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS

/obj/item/stack/tile/eighties
	name = "retro tile"
	singular_name = "retro floor tile"
	desc = "A stack of floor tiles that remind you of an age of funk."
	icon_state = "tile_eighties"
	turf_type = /turf/open/floor/eighties

/obj/item/stack/tile/eighties/loaded
	amount = 15

/obj/item/stack/tile/glass
	name = "glass tile"
	singular_name = "glass floor tile"
	desc = "The glass you walk on."
	icon_state = "glass_tile"
	turf_type = /turf/open/floor/glass

/obj/item/stack/tile/glass/reinforced
	name = "reinforced glass tile"
	singular_name = "reinforced glass tile"
	desc = "The glass you walk on."
	icon_state = "rglass_tile"
	turf_type = /turf/open/floor/glass/reinforced

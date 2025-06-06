/** # Snacks

Items in the "Snacks" subcategory are food items that people actually eat. The key points are that they are created
already filled with reagents and are destroyed when empty. Additionally, they make a "munching" noise when eaten.

Notes by Darem: Food in the "snacks" subtype can hold a maximum of 50 units. Generally speaking, you don't want to go over 40
total for the item because you want to leave space for extra condiments. If you want effect besides healing, add a reagent for
it. Try to stick to existing reagents when possible (so if you want a stronger healing effect, just use omnizine). On use
effect (such as the old officer eating a donut code) requires a unique reagent (unless you can figure out a better way).

The nutriment reagent and bitesize variable replace the old heal_amt and amount variables. Each unit of nutriment is equal to
2 of the old heal_amt variable. Bitesize is the rate at which the reagents are consumed. So if you have 6 nutriment and a
bitesize of 2, then it'll take 3 bites to eat. Unlike the old system, the contained reagents are evenly spread among all
the bites. No more contained reagents = no more bites.

Here is an example of the new formatting for anyone who wants to add more food items.
```
/obj/item/reagent_containers/food/snacks/xenoburger			//Identification path for the object.
	name = "Xenoburger"													//Name that displays in the UI.
	desc = "Smells caustic. Tastes like heresy."						//Duh
	icon_state = "xburger"												//Refers to an icon in food.dmi
/obj/item/reagent_containers/food/snacks/xenoburger/Initialize()		//Don't mess with this. | nO I WILL MESS WITH THIS
	. = ..()														//Same here.
	reagents.add_reagent(/datum/reagent/xenomicrobes, 10)						//This is what is in the food item. you may copy/paste
	reagents.add_reagent(/datum/reagent/consumable/nutriment, 2)							//this line of code for all the contents.
	bitesize = 3													//This is the amount each bite consumes.
```

All foods are distributed among various categories. Use common sense.
*/
/obj/item/reagent_containers/food/snacks
	name = "snack"
	desc = "Yummy."
	icon = 'icons/obj/food/food.dmi'
	icon_state = null
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	obj_flags = UNIQUE_RENAME
	grind_results = list() //To let them be ground up to transfer their reagents
	var/bitesize = 2
	var/bitecount = 0
	var/trash = null
	var/slice_path    // for sliceable food. path of the item resulting from the slicing
	var/slices_num
	var/eatverb
	var/dried_type = null
	var/dry = 0
	var/dunk_amount = 10 // how much reagent is transferred per dunk
	var/cooked_type = null  //for microwave cooking. path of the resulting item after microwaving
	var/filling_color = "#FFFFFF" //color to use when added to custom food.
	var/custom_food_type = null  //for food customizing. path of the custom food to create
	var/junkiness = 0  //for junk food. used to lower human satiety.
	var/list/bonus_reagents //the amount of reagents (usually nutriment and vitamin) added to crafted/cooked snacks, on top of the ingredients reagents.
	var/customfoodfilling = 1 // whether it can be used as filling in custom food
	var/list/tastes  // for example list("crisps" = 2, "salt" = 1)

	//Placeholder for effect that trigger on eating that aren't tied to reagents.

/obj/item/reagent_containers/food/snacks/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_FRIED, PROC_REF(on_fried))


/obj/item/reagent_containers/food/snacks/proc/on_fried(fry_object)
	reagents.trans_to(fry_object, reagents.total_volume)
	qdel()
	return COMSIG_FRYING_HANDLED

/obj/item/reagent_containers/food/snacks/add_initial_reagents()
	if(tastes && tastes.len)
		if(list_reagents)
			for(var/rid in list_reagents)
				var/amount = list_reagents[rid]
				if(rid == /datum/reagent/consumable/nutriment || rid == /datum/reagent/consumable/nutriment/vitamin)
					reagents.add_reagent(rid, amount, tastes.Copy())
				else
					reagents.add_reagent(rid, amount)
	else
		..()

/obj/item/reagent_containers/food/snacks/proc/On_Consume(mob/living/eater)
	if(!eater)
		return
	if(!reagents.total_volume)
		var/mob/living/location = loc
		var/obj/item/trash_item = generate_trash(location)
		qdel(src)
		if(istype(location))
			location.put_in_hands(trash_item)

/obj/item/reagent_containers/food/snacks/attack_self(mob/user)
	return


/obj/item/reagent_containers/food/snacks/attack(mob/living/M, mob/living/user, def_zone)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(!eatverb)
		eatverb = pick("bite","chew","nibble","gnaw","gobble","chomp")
	if(!reagents.total_volume)						//Shouldn't be needed but it checks to see if it has anything left in it.
		to_chat(user, span_warning("None of [src] left, oh no!"))
		qdel(src)
		return FALSE
	if(iscarbon(M))
		if(!canconsume(M, user))
			return FALSE

		var/fullness = M.nutrition + 10
		for(var/datum/reagent/consumable/C in M.reagents.reagent_list) //we add the nutrition value of what we're currently digesting
			fullness += C.nutriment_factor * C.volume / C.metabolization_rate

		if(M == user)								//If you're eating it yourself.
			if(junkiness && M.satiety < -150 && M.nutrition > NUTRITION_LEVEL_STARVING + 50 && !HAS_TRAIT(user, TRAIT_VORACIOUS))
				to_chat(M, span_warning("You don't feel like eating any more junk food at the moment!"))
				return FALSE
			else if(fullness <= 50)
				user.visible_message(span_notice("[user] hungrily [eatverb]s \the [src], gobbling it down!"), span_notice("You hungrily [eatverb] \the [src], gobbling it down!"))
			else if(fullness > 50 && fullness < 150)
				user.visible_message(span_notice("[user] hungrily [eatverb]s \the [src]."), span_notice("You hungrily [eatverb] \the [src]."))
			else if(fullness > 150 && fullness < 500)
				user.visible_message(span_notice("[user] [eatverb]s \the [src]."), span_notice("You [eatverb] \the [src]."))
			else if(fullness > 500 && fullness < 600)
				user.visible_message(span_notice("[user] unwillingly [eatverb]s a bit of \the [src]."), span_notice("You unwillingly [eatverb] a bit of \the [src]."))
			else if(fullness > (600 * (1 + M.overeatduration / 2000)))	// The more you eat - the more you can eat
				user.visible_message(span_warning("[user] cannot force any more of \the [src] to go down [user.p_their()] throat!"), span_warning("You cannot force any more of \the [src] to go down your throat!"))
				return FALSE
			if(HAS_TRAIT(M, TRAIT_VORACIOUS))
				M.changeNext_move(CLICK_CD_MELEE * 0.5) //nom nom nom
		else
			if(!isbrain(M))		//If you're feeding it to someone else.
				if(fullness <= (600 * (1 + M.overeatduration / 1000)))
					M.visible_message(span_danger("[user] attempts to feed [M] [src]."), \
										span_userdanger("[user] attempts to feed you [src]."))
				else
					M.visible_message(span_warning("[user] cannot force any more of [src] down [M]'s throat!"), \
										span_warning("[user] cannot force any more of [src] down your throat!"))
					return FALSE

				if(!do_after(user, target = M))
					return
				log_combat(user, M, "fed", reagents.log_list())
				M.visible_message(span_danger("[user] forces [M] to eat [src]!"), \
									span_userdanger("[user] forces you to eat [src]!"))

			else
				to_chat(user, span_warning("[M] doesn't seem to have a mouth!"))
				return

		if(reagents)								//Handle ingestion of the reagent.
			if(M.satiety > -200)
				M.satiety -= junkiness
			playsound(M.loc,'sound/items/eatfood.ogg', rand(10,50), TRUE)
			if(reagents.total_volume)
				SEND_SIGNAL(src, COMSIG_FOOD_EATEN, M, user)
				var/fraction = min(bitesize / reagents.total_volume, 1)
				reagents.trans_to(M, bitesize, transfered_by = user, method = INGEST)
				bitecount++
				On_Consume(M)
				checkLiked(fraction, M)
				return TRUE

	return 0

/obj/item/reagent_containers/food/snacks/examine(mob/user)
	. = ..()
	if(!in_container)
		switch (bitecount)
			if (0)
				return
			if(1)
				. += "[src] was bitten by someone!"
			if(2,3)
				. += "[src] was bitten [bitecount] times!"
			else
				. += "[src] was bitten multiple times!"

/obj/item/reagent_containers/food/snacks/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/storage))
		..() // -> item/attackby()
		return FALSE
	var/datum/component/edible/E = W.GetComponent(/datum/component/edible)
	if(istype(W, /obj/item/reagent_containers/food/snacks) || E)
		var/obj/item/reagent_containers/food/snacks/S = W
		if(custom_food_type && ispath(custom_food_type))
			if(W.w_class > WEIGHT_CLASS_SMALL)
				to_chat(user, span_warning("[S] is too big for [src]!"))
				return FALSE
			if(!S.customfoodfilling || istype(W, /obj/item/reagent_containers/food/snacks/customizable))
				to_chat(user, span_warning("[src] can't be filled with [S]!"))
				return FALSE
			if(contents.len >= 20)
				to_chat(user, span_warning("You can't add more ingredients to [src]!"))
				return FALSE
			var/obj/item/reagent_containers/food/snacks/customizable/C = new custom_food_type(get_turf(src))
			C.initialize_custom_food(src, W, user)
			return FALSE
	var/sharp = W.get_sharpness()
	if(sharp)
		if(slice(sharp, W, user))
			return TRUE
	else
		..()

//Called when you finish tablecrafting a snack.
/obj/item/reagent_containers/food/snacks/CheckParts(list/parts_list, datum/crafting_recipe/food/R)
	..()
	reagents.clear_reagents()
	for(var/obj/item/reagent_containers/RC in contents)
		RC.reagents.trans_to(reagents, RC.reagents.maximum_volume)
	if(istype(R))
		contents_loop:
			for(var/A in contents)
				for(var/B in R.real_parts)
					if(istype(A, B))
						continue contents_loop
				qdel(A)
	SSblackbox.record_feedback("tally", "food_made", 1, type)

	if(bonus_reagents && bonus_reagents.len)
		for(var/r_id in bonus_reagents)
			var/amount = bonus_reagents[r_id]
			if(r_id == /datum/reagent/consumable/nutriment || r_id == /datum/reagent/consumable/nutriment/vitamin)
				reagents.add_reagent(r_id, amount, tastes)
			else
				reagents.add_reagent(r_id, amount)

/obj/item/reagent_containers/food/snacks/proc/slice(accuracy, obj/item/W, mob/user)
	if((slices_num <= 0 || !slices_num) || !slice_path) //is the food sliceable?
		return FALSE

	if ( \
			!isturf(src.loc) || \
			!(locate(/obj/structure/table) in src.loc) && \
			!(locate(/obj/structure/table/optable) in src.loc) && \
			!(locate(/obj/item/storage/bag/tray) in src.loc) \
		)
		to_chat(user, span_warning("You cannot slice [src] here! You need a table or at least a tray."))
		return FALSE

	var/slices_lost = 0
	if (accuracy >= IS_SHARP_ACCURATE)
		user.visible_message( \
			"[user] slices [src].", \
			span_notice("You slice [src].") \
		)
	else
		user.visible_message( \
			"[user] inaccurately slices [src] with [W]!", \
			span_notice("You inaccurately slice [src] with your [W]!") \
		)
		slices_lost = rand(1,min(1,round(slices_num/2)))

	var/reagents_per_slice = reagents.total_volume/slices_num
	for(var/i=1 to (slices_num-slices_lost))
		var/obj/item/reagent_containers/food/snacks/slice = new slice_path (loc)
		initialize_slice(slice, reagents_per_slice)
	qdel(src)
	return TRUE

/obj/item/reagent_containers/food/snacks/proc/initialize_slice(obj/item/reagent_containers/food/snacks/slice, reagents_per_slice)
	slice.create_reagents(slice.volume)
	reagents.trans_to(slice,reagents_per_slice)
	if(name != initial(name))
		slice.name = "slice of [name]"
	if(desc != initial(desc))
		slice.desc = "[desc]"
	if(foodtype != initial(foodtype))
		slice.foodtype = foodtype //if something happens that overrode our food type, make sure the slice carries that over

/obj/item/reagent_containers/food/snacks/proc/generate_trash(atom/location)
	if(trash)
		if(ispath(trash, /obj/item))
			. = new trash(location)
			trash = null
			return
		else if(isitem(trash))
			var/obj/item/trash_item = trash
			trash_item.forceMove(location)
			. = trash
			trash = null
			return

/obj/item/reagent_containers/food/snacks/proc/update_customizable_overlays(obj/item/reagent_containers/food/snacks/S)
	cut_overlays()
	var/mutable_appearance/filling = mutable_appearance(icon, "[initial(icon_state)]_filling")
	if(S.filling_color == "#FFFFFF")
		filling.color = pick("#FF0000","#0000FF","#008000","#FFFF00")
	else
		filling.color = S.filling_color

	add_overlay(filling)

// initialize_cooked_food() is called when microwaving the food
/obj/item/reagent_containers/food/snacks/proc/initialize_cooked_food(obj/item/reagent_containers/food/snacks/S, cooking_efficiency = 1)
	S.create_reagents(S.volume)
	if(reagents)
		reagents.trans_to(S, reagents.total_volume)
	if(S.bonus_reagents && S.bonus_reagents.len)
		for(var/r_id in S.bonus_reagents)
			var/amount = S.bonus_reagents[r_id] * cooking_efficiency
			if(r_id == /datum/reagent/consumable/nutriment || r_id == /datum/reagent/consumable/nutriment/vitamin)
				S.reagents.add_reagent(r_id, amount, tastes)
			else
				S.reagents.add_reagent(r_id, amount)

/obj/item/reagent_containers/food/snacks/microwave_act(obj/machinery/microwave/M)
	var/turf/T = get_turf(src)
	var/obj/item/result

	if(cooked_type)
		result = new cooked_type(T)
		if(istype(M))
			initialize_cooked_food(result, M.efficiency)
		else
			initialize_cooked_food(result, 1)
		SSblackbox.record_feedback("tally", "food_made", 1, result.type)
	else
		result = new /obj/item/reagent_containers/food/snacks/badrecipe(T)
		if(istype(M) && M.dirty < 100)
			M.dirty++
	qdel(src)

	return result

/obj/item/reagent_containers/food/snacks/deconstruct(disassembled)
	if(contents)
		for(var/atom/movable/something in contents)
			something.forceMove(drop_location())
	return ..()

/obj/item/reagent_containers/food/snacks/attack_animal(mob/M)
	if(isanimal(M))
		if(isdog(M))
			var/mob/living/L = M
			if(bitecount == 0 || prob(50))
				M.manual_emote("nibbles away at \the [src]")
			bitecount++
			L.taste(reagents) // why should carbons get all the fun?
			if(bitecount >= 5)
				var/sattisfaction_text = pick("burps from enjoyment", "yaps for more", "woofs twice", "looks at the area where \the [src] was")
				if(sattisfaction_text)
					M.emote(sattisfaction_text)
				qdel(src)


// //////////////////////////////////////////////Store////////////////////////////////////////
/// All the food items that can store an item inside itself, like bread or cake.
/obj/item/reagent_containers/food/snacks/store
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/reagent_containers/food/snacks/store/Initialize()
	. = ..()
	AddComponent(/datum/component/food_storage)

/obj/item/reagent_containers/food/snacks/MouseDrop(atom/over)
	var/turf/T = get_turf(src)
	var/obj/structure/table/TB = locate(/obj/structure/table) in T
	if(TB)
		TB.MouseDrop(over)
	else
		return ..()

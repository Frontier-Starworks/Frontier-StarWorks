/obj/singularity/academy
	dissipate = 0
	move_self = 0
	grav_pull = 1

/obj/singularity/academy/admin_investigate_setup()
	return

/obj/singularity/academy/process(seconds_per_tick)
	eat()
	if(prob(1))
		mezzer()

/obj/structure/academy_wizard_spawner
	name = "Academy Defensive System"
	desc = "Made by Abjuration, Inc."
	icon = 'icons/obj/cult.dmi'
	icon_state = "forge"
	anchored = TRUE
	max_integrity = 200
	var/mob/living/current_wizard = null
	var/next_check = 0
	var/cooldown = 600
	var/faction = ROLE_WIZARD
	var/braindead_check = 0

/obj/structure/academy_wizard_spawner/New()
	START_PROCESSING(SSobj, src)

/obj/structure/academy_wizard_spawner/Destroy()
	if(!broken)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/academy_wizard_spawner/process(seconds_per_tick)
	if(next_check < world.time)
		if(!current_wizard)
			for(var/mob/living/L in GLOB.player_list)
				if(L.virtual_z() == src.virtual_z() && L.stat != DEAD && !(faction in L.faction))
					summon_wizard()
					break
		else
			if(current_wizard.stat == DEAD)
				current_wizard = null
				summon_wizard()
			if(!current_wizard.client)
				if(!braindead_check)
					braindead_check = 1
				else
					braindead_check = 0
					give_control()
		next_check = world.time + cooldown

/obj/structure/academy_wizard_spawner/proc/give_control()
	set waitfor = FALSE

	if(!current_wizard)
		return
	var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as Wizard Academy Defender?", ROLE_WIZARD, null, ROLE_WIZARD, 50, current_wizard, POLL_IGNORE_ACADEMY_WIZARD)

	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		message_admins("[ADMIN_LOOKUPFLW(C)] was spawned as Wizard Academy Defender")
		current_wizard.ghostize() // on the off chance braindead defender gets back in
		current_wizard.key = C.key

/obj/structure/academy_wizard_spawner/proc/summon_wizard()
	var/turf/T = src.loc
	var/mob/living/carbon/human/wizbody = new(T)
	wizbody.fully_replace_character_name(wizbody.real_name, "Academy Teacher")
	wizbody.mind_initialize()
	var/datum/mind/wizmind = wizbody.mind
	wizmind.special_role = "Academy Defender"
	wizmind.add_antag_datum(/datum/antagonist/wizard/academy)
	current_wizard = wizbody

	give_control()

/obj/structure/academy_wizard_spawner/deconstruct(disassembled = TRUE)
	if(!broken)
		broken = 1
		visible_message(span_warning("[src] breaks down!"))
		icon_state = "forge_off"
		STOP_PROCESSING(SSobj, src)

/obj/item/dice/d20/fate
	name = "\improper Die of Fate"
	desc = "A die with twenty sides. You can feel unearthly energies radiating from it. Using this might be VERY risky."
	icon_state = "d20"
	sides = 20
	microwave_riggable = FALSE
	var/reusable = TRUE
	var/used = FALSE

/obj/item/dice/d20/fate/one_use
	reusable = FALSE

/obj/item/dice/d20/fate/cursed
	name = "cursed Die of Fate"
	desc = "A die with twenty sides. You feel that rolling this is a REALLY bad idea."
	color = "#00BB00"

	rigged = DICE_TOTALLY_RIGGED
	rigged_value = 1

/obj/item/dice/d20/fate/cursed/one_use
	reusable = FALSE

/obj/item/dice/d20/fate/stealth
	name = "d20"
	desc = "A die with twenty sides. The preferred die to throw at the GM."

/obj/item/dice/d20/fate/stealth/one_use
	reusable = FALSE

/obj/item/dice/d20/fate/stealth/cursed
	rigged = DICE_TOTALLY_RIGGED
	rigged_value = 1

/obj/item/dice/d20/fate/stealth/cursed/one_use
	reusable = FALSE

/obj/item/dice/d20/fate/diceroll(mob/user)
	. = ..()
	if(!used)
		if(!ishuman(user) || !user.mind || (user.mind in SSticker.mode.wizards))
			to_chat(user, span_warning("You feel the magic of the dice is restricted to ordinary humans!"))
			return

		if(!reusable)
			used = TRUE

		var/turf/T = get_turf(src)
		T.visible_message(span_userdanger("[src] flares briefly."))

		addtimer(CALLBACK(src, PROC_REF(effect), user, .), 1 SECONDS)

/obj/item/dice/d20/fate/equipped(mob/user, slot)
	. = ..()
	if(!ishuman(user) || !user.mind || (user.mind in SSticker.mode.wizards))
		to_chat(user, span_warning("You feel the magic of the dice is restricted to ordinary humans! You should leave it alone."))
		user.dropItemToGround(src)


/obj/item/dice/d20/fate/proc/effect(mob/living/carbon/human/user,roll)
	var/turf/T = get_turf(src)
	switch(roll)
		if(1)
			//Dust
			T.visible_message(span_userdanger("[user] turns to dust!"))
			user.hellbound = TRUE
			user.dust()
		if(2)
			//Death
			T.visible_message(span_userdanger("[user] suddenly dies!"))
			user.death()
		if(3)
			//Swarm of creatures
			T.visible_message(span_userdanger("A swarm of creatures surround [user]!"))
			for(var/direction in GLOB.alldirs)
				new /mob/living/simple_animal/hostile/netherworld(get_step(get_turf(user),direction))
		if(4)
			//Destroy Equipment
			T.visible_message(span_userdanger("Everything [user] is holding and wearing disappears!"))
			for(var/obj/item/I in user)
				if(istype(I, /obj/item/implant))
					continue
				qdel(I)
		if(5)
			//Monkeying
			T.visible_message(span_userdanger("[user] transforms into a monkey!"))
			user.monkeyize()
		if(6)
			//Cut speed
			T.visible_message(span_userdanger("[user] starts moving slower!"))
			user.add_movespeed_modifier(/datum/movespeed_modifier/die_of_fate)
		if(7)
			//Throw
			T.visible_message(span_userdanger("Unseen forces throw [user]!"))
			user.Stun(60)
			user.adjustBruteLoss(50)
			var/throw_dir = pick(GLOB.cardinals)
			var/atom/throw_target = get_edge_target_turf(user, throw_dir)
			user.throw_at(throw_target, 200, 4)
		if(8)
			//Fueltank Explosion
			T.visible_message(span_userdanger("An explosion bursts into existence around [user]!"))
			explosion(get_turf(user),-1,0,2, flame_range = 2)
		if(9)
			//Cold
			var/datum/disease/D = new /datum/disease/cold()
			T.visible_message(span_userdanger("[user] looks a little under the weather!"))
			user.ForceContractDisease(D, FALSE, TRUE)
		if(10)
			//Nothing
			T.visible_message(span_userdanger("Nothing seems to happen."))
		if(11)
			//Cookie
			T.visible_message(span_userdanger("A cookie appears out of thin air!"))
			var/obj/item/food/cookie/C = new(drop_location())
			do_smoke(0, drop_location())
			C.name = "Cookie of Fate"
		if(12)
			//Healing
			T.visible_message(span_userdanger("[user] looks very healthy!"))
			user.revive(full_heal = TRUE, admin_revive = TRUE)
		if(13)
			//Mad Dosh
			T.visible_message(span_userdanger("Mad dosh shoots out of [src]!"))
			var/turf/Start = get_turf(src)
			for(var/direction in GLOB.alldirs)
				var/turf/dirturf = get_step(Start,direction)
				if(rand(0,1))
					new /obj/item/spacecash/bundle/c1000(dirturf)
				else
					var/obj/item/storage/bag/money/M = new(dirturf)
					for(var/i in 1 to rand(5,50))
						new /obj/item/coin/gold(M)
		if(14)
			//Free Gun
			T.visible_message(span_userdanger("An impressive gun appears!"))
			do_smoke(0, drop_location())
			new /obj/item/gun/ballistic/revolver/mateba(drop_location())
		if(15)
			//Random One-use spellbook
			T.visible_message(span_userdanger("A magical looking book drops to the floor!"))
			do_smoke(0, drop_location())
			new /obj/item/book/granter/spell/random(drop_location())
		if(16)
			//Servant & Servant Summon
			T.visible_message(span_userdanger("A Dice Servant appears in a cloud of smoke!"))
			var/mob/living/carbon/human/H = new(drop_location())
			do_smoke(0, drop_location())

			H.equipOutfit(/datum/outfit/butler)
			var/datum/mind/servant_mind = new /datum/mind()
			var/datum/antagonist/magic_servant/A = new
			servant_mind.add_antag_datum(A)
			A.setup_master(user)
			servant_mind.transfer_to(H)

			var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as [user.real_name] Servant?", ROLE_WIZARD, null, ROLE_WIZARD, 50, H)
			if(LAZYLEN(candidates))
				var/mob/dead/observer/C = pick(candidates)
				message_admins("[ADMIN_LOOKUPFLW(C)] was spawned as Dice Servant")
				H.key = C.key

			var/obj/effect/proc_holder/spell/targeted/summonmob/S = new
			S.target_mob = H
			user.mind.AddSpell(S)

		if(17)
			//Tator Kit
			T.visible_message(span_userdanger("A suspicious box appears!"))
			new /obj/item/storage/box/syndicate/bundle_A(drop_location())
			do_smoke(0, drop_location())
		if(18)
			//Captain ID
			T.visible_message(span_userdanger("A golden identification card appears!"))
			new /obj/item/card/id/captains_spare(drop_location())
			do_smoke(0, drop_location())
		if(19)
			//Instrinct Resistance
			T.visible_message(span_userdanger("[user] looks very robust!"))
			user.physiology.brute_mod *= 0.5
			user.physiology.burn_mod *= 0.5

		if(20)
			//Free wizard! //NOT ANY MORE FUCKING CHRIST
			T.visible_message(span_userdanger("Magic arches out of [src] and into ground under [user]!"))
			new /obj/item/clothing/suit/wizrobe(drop_location())
			new /obj/item/clothing/head/wizard(drop_location())
			new /obj/item/clothing/gloves/combat/wizard(drop_location())
			new /obj/item/staff(drop_location())
			new /obj/structure/mirror/magic(drop_location())

/datum/outfit/butler
	name = "Butler"
	uniform = /obj/item/clothing/under/suit/black_really
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/white

/obj/effect/proc_holder/spell/targeted/summonmob
	name = "Summon Servant"
	desc = "This spell can be used to call your servant, whenever you need it."
	charge_max = 100
	clothes_req = 0
	invocation = "JE VES"
	invocation_type = INVOCATION_WHISPER
	range = -1
	level_max = 0 //cannot be improved
	cooldown_min = 100
	include_user = 1

	var/mob/living/target_mob

	action_icon_state = "summons"

/obj/effect/proc_holder/spell/targeted/summonmob/cast(list/targets,mob/user = usr)
	if(!target_mob)
		return
	var/turf/Start = get_turf(user)
	for(var/direction in GLOB.alldirs)
		var/turf/T = get_step(Start,direction)
		if(!T.density)
			target_mob.Move(T)

/obj/structure/ladder/unbreakable/rune
	name = "\improper Teleportation Rune"
	desc = "Could lead anywhere."
	icon = 'icons/obj/rune.dmi'
	icon_state = "1"
	color = rgb(0,0,255)

/obj/structure/ladder/unbreakable/rune/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_blocker)

/obj/structure/ladder/unbreakable/rune/show_fluff_message(up,mob/user)
	user.visible_message(span_notice("[user] activates \the [src]."), span_notice("You activate \the [src]."))

/obj/structure/ladder/unbreakable/rune/use(mob/user, is_ghost=FALSE)
	if(is_ghost || !(user.mind in SSticker.mode.wizards))
		..()

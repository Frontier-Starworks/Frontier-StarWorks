// So much of atmospherics.dm was used solely by components, so separating this makes things all a lot cleaner.
// On top of that, now people can add component-speciic procs/vars if they want!

/obj/machinery/atmospherics/components
	hide = FALSE

	var/welded = FALSE //Used on pumps and scrubbers
	var/showpipe = TRUE
	var/shift_underlay_only = TRUE //Layering only shifts underlay?

	var/update_parents_after_rebuild = FALSE

	var/list/datum/pipeline/parents
	var/list/datum/gas_mixture/airs

/obj/machinery/atmospherics/components/New()
	parents = new(device_type)
	airs = new(device_type)

	..()

	for(var/i in 1 to device_type)
		var/datum/gas_mixture/A = new(200)
		airs[i] = A

/obj/machinery/atmospherics/components/Initialize()
	. = ..()

	if(hide)
		RegisterSignal(src, COMSIG_OBJ_HIDE, PROC_REF(hide_pipe))

// Iconnery

/obj/machinery/atmospherics/components/proc/update_icon_nopipes()
	return

/obj/machinery/atmospherics/components/proc/hide_pipe(datum/source, covered)
	showpipe = !covered
	update_appearance()

/obj/machinery/atmospherics/components/update_icon()
	update_icon_nopipes()

	underlays.Cut()
	plane = showpipe ? FLOOR_PLANE : FLOOR_PLANE

	if(!showpipe)
		return ..()

	var/connected = 0 //Direction bitset

	for(var/i in 1 to device_type) //adds intact pieces
		if(nodes[i])
			var/obj/machinery/atmospherics/node = nodes[i]
			var/image/img = get_pipe_underlay("pipe_intact", get_dir(src, node), node.pipe_color)
			underlays += img
			connected |= img.dir

	for(var/direction in GLOB.cardinals)
		if((initialize_directions & direction) && !(connected & direction))
			underlays += get_pipe_underlay("pipe_exposed", direction)

	if(!shift_underlay_only)
		PIPING_LAYER_SHIFT(src, piping_layer)
	return ..()

/obj/machinery/atmospherics/components/proc/get_pipe_underlay(state, dir, color = null)
	if(color)
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, color, piping_layer = shift_underlay_only ? piping_layer : 3)
	else
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, piping_layer = shift_underlay_only ? piping_layer : 3)

// Pipenet stuff; housekeeping

/obj/machinery/atmospherics/components/nullifyNode(i)
	// Every node has a parent pipeline and an air associated with it, but we need to accomdate for edge cases like init dir cache building...
	if(parents[i])
		nullifyPipenet(parents[i])
	airs[i] = null
	if(!QDELETED(src))
		airs[i] = new /datum/gas_mixture(200)
	return ..()

/obj/machinery/atmospherics/components/on_construction()
	..()
	update_parents()

/obj/machinery/atmospherics/components/rebuild_pipes()
	. = ..()
	if(update_parents_after_rebuild)
		update_parents()

/obj/machinery/atmospherics/components/get_rebuild_targets()
	var/list/to_return = list()
	for(var/i in 1 to device_type)
		if(parents[i])
			continue
		parents[i] = new /datum/pipeline()
		to_return += parents[i]
	return to_return

/obj/machinery/atmospherics/components/proc/nullifyPipenet(datum/pipeline/reference)
	if(!reference)
		CRASH("nullifyPipenet(null) called by [type] on [COORD(src)]")

	for (var/i in 1 to length(parents))
		if (parents[i] == reference)
			reference.other_airs -= airs[i] // Disconnects from the pipeline side
			parents[i] = null // Disconnects from the machinery side.

	reference.other_atmosmch -= src

	/*
	We explicitly qdel pipeline when this particular pipeline
	is projected to have no member and cause GC problems.
	We have to do this because components don't qdel pipelines
	while pipes must and will happily wreck and rebuild
	everything again every time they are qdeleted.
	*/
	if(length(reference.other_atmosmch) || length(reference.members) || QDESTROYING(reference))
		return

	qdel(reference)

/obj/machinery/atmospherics/components/returnPipenetAirs(datum/pipeline/reference)
	var/list/returned_air = list()

	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			returned_air += airs[i]
	return returned_air

/obj/machinery/atmospherics/components/pipeline_expansion(datum/pipeline/reference)
	if(reference)
		return list(nodes[parents.Find(reference)])
	return ..()

/obj/machinery/atmospherics/components/setPipenet(datum/pipeline/reference, obj/machinery/atmospherics/connection)
	var/connection_index = nodes.Find(connection)
	if(!connection_index)
		message_admins("Doubled pipe found at [ADMIN_VERBOSEJMP(connection)]! Please report to mappers.") //This will cascade into even more errors. Sorry!
		CRASH("Doubled pipe found, causing an error in setPipenet")
	var/list/datum/pipeline/to_replace = parents[connection_index]
	//Some references to clean up if it isn't empty
	if(to_replace)
		nullifyPipenet(to_replace)
	parents[connection_index] = reference

/obj/machinery/atmospherics/components/returnPipenet(obj/machinery/atmospherics/A = nodes[1]) //returns parents[1] if called without argument
	return parents[nodes.Find(A)]

/obj/machinery/atmospherics/components/replacePipenet(datum/pipeline/old_pipeline, datum/pipeline/new_pipeline)
	parents[parents.Find(old_pipeline)] = new_pipeline

/obj/machinery/atmospherics/components/unsafe_pressure_release(mob/user, pressures)
	..()

	var/turf/T = get_turf(src)
	if(T)
		//Remove the gas from airs and assume it
		var/datum/gas_mixture/environment = T.return_air()
		var/lost = null
		var/times_lost = 0
		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			lost += pressures*environment.return_volume()/(air.return_temperature() * R_IDEAL_GAS_EQUATION)
			times_lost++
		var/shared_loss = lost/times_lost

		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			T.assume_air_moles(air, shared_loss)
		air_update_turf(TRUE)

/obj/machinery/atmospherics/components/proc/safe_input(title, text, default_set)
	var/new_value = input(usr,text,title,default_set) as num|null

	if (isnull(new_value))
		return default_set

	if(usr.canUseTopic(src))
		return new_value

	return default_set

// Helpers

/obj/machinery/atmospherics/components/proc/update_parents()
	if(!SSair.initialized)
		return
	if(rebuilding)
		update_parents_after_rebuild = TRUE
		return
	for(var/i in 1 to device_type)
		var/datum/pipeline/parent = parents[i]
		if(!parent)
			//WARNING("Component is missing a pipenet! Rebuilding...")
			SSair.add_to_rebuild_queue(src)
			return
		parent.update = TRUE

/obj/machinery/atmospherics/components/returnPipenets()
	. = list()
	for(var/i in 1 to device_type)
		. += returnPipenet(nodes[i])

// UI Stuff

/obj/machinery/atmospherics/components/ui_status(mob/user)
	if(allowed(user))
		return ..()
	to_chat(user, span_danger("Access denied."))
	return UI_CLOSE

// Tool acts

/obj/machinery/atmospherics/components/return_analyzable_air()
	return airs

/datum/tlv
	var/min2
	var/min1
	var/max1
	var/max2

/datum/tlv/New(min2 as num, min1 as num, max1 as num, max2 as num)
	if(min2) src.min2 = min2
	if(min1) src.min1 = min1
	if(max1) src.max1 = max1
	if(max2) src.max2 = max2

/datum/tlv/proc/get_danger_level(val as num)
	if(max2 != -1 && val >= max2)
		return 2
	if(min2 != -1 && val <= min2)
		return 2
	if(max1 != -1 && val >= max1)
		return 1
	if(min1 != -1 && val <= min1)
		return 1
	return 0

/datum/tlv/no_checks
	min2 = -1
	min1 = -1
	max1 = -1
	max2 = -1

/datum/tlv/dangerous
	min2 = -1
	min1 = -1
	max1 = 0.2
	max2 = 0.5

/obj/item/electronics/airalarm
	name = "air alarm electronics"
	custom_price = 50
	icon_state = "airalarm_electronics"

/obj/item/wallframe/airalarm
	name = "air alarm frame"
	desc = "Used for building Air Alarms."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "alarm_bitem"
	result_path = /obj/machinery/airalarm
	pixel_shift = 28
	inverse_pixel_shift = TRUE

#define AALARM_MODE_SCRUBBING 1
#define AALARM_MODE_VENTING 2 //makes draught
#define AALARM_MODE_PANIC 3 //like siphon, but stronger (enables widenet)
#define AALARM_MODE_REPLACEMENT 4 //sucks off all air, then refill and swithes to scrubbing
#define AALARM_MODE_OFF 5
#define AALARM_MODE_FLOOD 6 //Emagged mode; turns off scrubbers and pressure checks on vents
#define AALARM_MODE_SIPHON 7 //Scrubbers suck air
#define AALARM_MODE_CONTAMINATED 8 //Turns on all filtering and widenet scrubbing.
#define AALARM_MODE_REFILL 9 //just like normal, but with triple the air output

#define AALARM_REPORT_TIMEOUT 100

/obj/machinery/airalarm
	name = "air alarm"
	desc = "A machine that monitors atmosphere levels. Goes off if the area is dangerous."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "alarm"
	use_power = IDLE_POWER_USE
	idle_power_usage = IDLE_DRAW_MINIMAL
	active_power_usage = ACTIVE_DRAW_MEDIUM
	power_channel = AREA_USAGE_ENVIRON
	//req_access = list(ACCESS_ATMOSPHERICS)
	max_integrity = 250
	integrity_failure = 0.33
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 100, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 90, "acid" = 30)
	resistance_flags = FIRE_PROOF
	clicksound = 'sound/machines/terminal_select.ogg'
	req_ship_access = TRUE

	//Heating System
	var/heating_manage = TRUE
	var/heating_current_mode = "Idle"
	var/heating_temp_inc = 0.5
	var/heating_temp_minvalue = 288.15
	var/heating_temp_maxvalue = 303.15
	var/heating_temp_setpoint = T20C

	FASTDMM_PROP(\
		set_instance_vars(\
			pixel_x = (dir & 3)? INSTANCE_VAR_DEFAULT : (dir == 4 ? -24 : 24),\
			pixel_y = (dir & 3)? (dir == 1 ? -24 : 24) : INSTANCE_VAR_DEFAULT\
		),\
		dir_amount = 4\
	)

	COOLDOWN_DECLARE(decomp_alarm)

	var/danger_level = 0
	var/mode = AALARM_MODE_SCRUBBING

	var/locked = TRUE
	var/aidisabled = 0
	var/shorted = 0
	var/buildstage = 2 // 2 = complete, 1 = no wires,  0 = circuit gone

	var/frequency = FREQ_ATMOS_CONTROL
	var/alarm_frequency = FREQ_ATMOS_ALARMS
	var/datum/radio_frequency/radio_connection

	//anything outright hazardous (flammable, toxic, generally Weird)
	var/list/filter_basic = list(GAS_CO2, GAS_PLASMA, GAS_NITROUS, GAS_BZ, GAS_TRITIUM, GAS_FREON, GAS_HYDROGEN, GAS_CHLORINE, GAS_HYDROGEN_CHLORIDE, GAS_CO, GAS_AMMONIA, GAS_METHANE, GAS_SO2, GAS_O3)
	//anything that isn't o2 or n2.
	var/list/filter_extra = list(GAS_CO2, GAS_PLASMA, GAS_NITROUS, GAS_BZ, GAS_TRITIUM, GAS_FREON, GAS_HYDROGEN, GAS_CHLORINE, GAS_HYDROGEN_CHLORIDE, GAS_H2O, GAS_CO, GAS_ARGON, GAS_AMMONIA, GAS_METHANE, GAS_SO2, GAS_O3)

	var/list/TLV = list( // Breathable air.
		"pressure"					= new/datum/tlv(HAZARD_LOW_PRESSURE, WARNING_LOW_PRESSURE, WARNING_HIGH_PRESSURE, HAZARD_HIGH_PRESSURE), // kPa. Values are min2, min1, max1, max2
		"temperature"				= new/datum/tlv(T0C, T0C+10, T0C+40, T0C+66),
		GAS_O2						= new/datum/tlv(16, 19, 40, 50), // Partial pressure, kpa
		GAS_N2						= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_CO2						= new/datum/tlv(-1, -1, 5, 10),
		GAS_PLASMA					= new/datum/tlv/dangerous,
		GAS_NITROUS					= new/datum/tlv/dangerous,
		GAS_BZ						= new/datum/tlv/dangerous,
		GAS_H2O						= new/datum/tlv/dangerous,
		GAS_TRITIUM					= new/datum/tlv/dangerous,
		GAS_FREON 					= new/datum/tlv/dangerous,
		GAS_HYDROGEN				= new/datum/tlv/dangerous,
		GAS_CHLORINE				= new/datum/tlv/dangerous,
		GAS_HYDROGEN_CHLORIDE		= new/datum/tlv/dangerous,
		GAS_CO						= new/datum/tlv/dangerous,
		GAS_ARGON					= new/datum/tlv(-1, -1, 1000, 1000), //inert and nontoxic
		GAS_AMMONIA					= new/datum/tlv/dangerous,
		GAS_METHANE					= new/datum/tlv/dangerous,
		GAS_SO2						= new/datum/tlv/dangerous,
		GAS_O3						= new/datum/tlv/dangerous,
	)

/obj/machinery/airalarm/freezer // Won't go off for low temps; Won't heat the room
	desc = "A machine that monitors atmosphere levels. This one is set to go off in room temperature, as to not let freezer contents spoil."
	heating_manage = FALSE

	TLV = list( // Breathable air.
		"pressure"					= new/datum/tlv(HAZARD_LOW_PRESSURE, WARNING_LOW_PRESSURE, WARNING_HIGH_PRESSURE, HAZARD_HIGH_PRESSURE), // kPa. Values are min2, min1, max1, max2
		"temperature"				= new/datum/tlv(T0C-10, T0C, T0C+10, T0C+66), // Lowered since it's a freezer
		GAS_O2						= new/datum/tlv(16, 19, 40, 50),
		GAS_N2						= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_CO2						= new/datum/tlv(-1, -1, 5, 10),
		GAS_PLASMA					= new/datum/tlv/dangerous,
		GAS_NITROUS					= new/datum/tlv/dangerous,
		GAS_BZ						= new/datum/tlv/dangerous,
		GAS_H2O						= new/datum/tlv/dangerous,
		GAS_TRITIUM					= new/datum/tlv/dangerous,
		GAS_FREON 					= new/datum/tlv/dangerous,
		GAS_HYDROGEN				= new/datum/tlv/dangerous,
		GAS_CHLORINE				= new/datum/tlv/dangerous,
		GAS_HYDROGEN_CHLORIDE		= new/datum/tlv/dangerous,
		GAS_CO						= new/datum/tlv/dangerous,
		GAS_ARGON					= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_AMMONIA					= new/datum/tlv/dangerous,
		GAS_METHANE					= new/datum/tlv/dangerous,
		GAS_SO2						= new/datum/tlv/dangerous,
		GAS_O3						= new/datum/tlv/dangerous,
	)

/obj/machinery/airalarm/server // No checks here.
	TLV = list(
		"pressure"					= new/datum/tlv/no_checks,
		"temperature"				= new/datum/tlv/no_checks,
		GAS_O2						= new/datum/tlv/no_checks,
		GAS_N2						= new/datum/tlv/no_checks,
		GAS_CO2						= new/datum/tlv/no_checks,
		GAS_PLASMA					= new/datum/tlv/no_checks,
		GAS_NITROUS					= new/datum/tlv/no_checks,
		GAS_BZ						= new/datum/tlv/no_checks,
		GAS_H2O						= new/datum/tlv/no_checks,
		GAS_TRITIUM					= new/datum/tlv/no_checks,
		GAS_FREON					= new/datum/tlv/no_checks,
		GAS_HYDROGEN				= new/datum/tlv/no_checks,
		GAS_CHLORINE				= new/datum/tlv/dangerous,
		GAS_HYDROGEN_CHLORIDE		= new/datum/tlv/dangerous,
		GAS_CO						= new/datum/tlv/dangerous,
		GAS_ARGON					= new/datum/tlv/no_checks,
		GAS_AMMONIA					= new/datum/tlv/no_checks,
		GAS_METHANE					= new/datum/tlv/no_checks,
		GAS_SO2						= new/datum/tlv/no_checks,
		GAS_O3						= new/datum/tlv/no_checks,
	)
	heating_manage = FALSE

/obj/machinery/airalarm/kitchen_cold_room // Kitchen cold rooms start off at -80°C or 193.15°K.
	TLV = list(
		"pressure"					= new/datum/tlv(ONE_ATMOSPHERE * 0.8, ONE_ATMOSPHERE*  0.9, ONE_ATMOSPHERE * 1.1, ONE_ATMOSPHERE * 1.2), // kPa
		"temperature"				= new/datum/tlv(T0C-273.15, T0C-80, T0C-10, T0C+10),
		GAS_O2						= new/datum/tlv(16, 19, 135, 140), // Partial pressure, kpa
		GAS_N2						= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_CO2						= new/datum/tlv(-1, -1, 5, 10),
		GAS_PLASMA					= new/datum/tlv/dangerous,
		GAS_NITROUS					= new/datum/tlv/dangerous,
		GAS_BZ						= new/datum/tlv/dangerous,
		GAS_H2O						= new/datum/tlv/dangerous,
		GAS_TRITIUM					= new/datum/tlv/dangerous,
		GAS_FREON					= new/datum/tlv/dangerous,
		GAS_HYDROGEN				= new/datum/tlv/dangerous,
		GAS_CHLORINE				= new/datum/tlv/dangerous,
		GAS_HYDROGEN_CHLORIDE		= new/datum/tlv/dangerous,
		GAS_CO						= new/datum/tlv/dangerous,
		GAS_ARGON					= new/datum/tlv(-1, -1, 1000, 1000), //inert and nontoxic
		GAS_AMMONIA					= new/datum/tlv/dangerous,
		GAS_METHANE					= new/datum/tlv/dangerous,
		GAS_SO2						= new/datum/tlv/dangerous,
		GAS_O3						= new/datum/tlv/dangerous,
	)
	heating_manage = FALSE

/obj/machinery/airalarm/unlocked
	locked = FALSE

/obj/machinery/airalarm/engine
	name = "engine air alarm"
	locked = FALSE
	req_access = null
	req_one_access = list(ACCESS_ATMOSPHERICS, ACCESS_ENGINE)

/obj/machinery/airalarm/mixingchamber
	name = "chamber air alarm"
	locked = FALSE
	req_access = null
	req_one_access = list(ACCESS_ATMOSPHERICS, ACCESS_TOX, ACCESS_TOX_STORAGE)

/obj/machinery/airalarm/all_access
	name = "all-access air alarm"
	desc = "This particular atmos control unit appears to have no access restrictions."
	locked = FALSE
	req_access = null
	req_one_access = null

/obj/machinery/airalarm/syndicate //general syndicate access
	req_access = list(ACCESS_SYNDICATE)

/obj/machinery/airalarm/away //general away mission access
	req_access = list(ACCESS_AWAY_GENERAL)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/airalarm, 27)

//all air alarms in area are connected via magic
/area
	var/list/air_vent_names = list()
	var/list/air_vent_ids = list()
	var/list/air_vent_info = list()

	var/list/air_scrub_names = list()
	var/list/air_scrub_ids = list()
	var/list/air_scrub_info = list()

	var/list/dp_air_vent_names = list()
	var/list/dp_air_vent_ids = list()
	var/list/dp_air_vent_info = list()

/obj/machinery/airalarm/New(loc, ndir, nbuild)
	..()
	wires = new /datum/wires/airalarm(src)
	if(ndir)
		setDir(ndir)

	if(nbuild)
		buildstage = 0
		panel_open = TRUE

	if(name == initial(name))
		name = "[get_area_name(src)] Air Alarm"

	update_appearance()

/obj/machinery/airalarm/Destroy()
	SSradio.remove_object(src, frequency)
	QDEL_NULL(wires)
	var/area/ourarea = get_area(src)
	ourarea.atmosalert(FALSE, src)
	return ..()

/obj/machinery/airalarm/Initialize(mapload)
	. = ..()
	set_frequency(frequency)

/obj/machinery/airalarm/examine(mob/user)
	. = ..()
	switch(buildstage)
		if(0)
			. += span_notice("It is missing air alarm electronics.")
		if(1)
			. += span_notice("It is missing wiring.")
		if(2)
			. += span_notice("Alt-click to [locked ? "unlock" : "lock"] the interface.")

/obj/machinery/airalarm/examine_more(mob/user)
	. = ..()
	if(buildstage == 2)
		ui_interact(user)


/obj/machinery/airalarm/ui_status(mob/user)
	if(user.has_unlimited_silicon_privilege && aidisabled)
		to_chat(user, "AI control has been disabled.")
	else if(!shorted)
		return ..()
	return UI_CLOSE


/obj/machinery/airalarm/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AirAlarm", name)
		ui.open()

/obj/machinery/airalarm/ui_data(mob/user)
	var/data = list(
		"locked" = locked,
		"siliconUser" = user.has_unlimited_silicon_privilege && check_ship_ai_access(user),
		"emagged" = (obj_flags & EMAGGED ? 1 : 0),
		"danger_level" = danger_level,
	)

	var/area/A = get_area(src)
	data["atmos_alarm"] = A.atmosalm
	data["fire_alarm"] = A.fire
	data["heating"] = list(
		"mode" = heating_current_mode,
		"enabled" = heating_manage,
		"setPoint" = heating_temp_setpoint,
		"minValue" = heating_temp_minvalue,
		"maxValue" = heating_temp_maxvalue
	)

	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = T.return_air()
	var/datum/tlv/cur_tlv

	data["environment_data"] = list()
	var/pressure = environment.return_pressure()
	cur_tlv = TLV["pressure"]
	data["environment_data"] += list(list(
							"name" = "Pressure",
							"value" = pressure,
							"unit" = "kPa",
							"danger_level" = cur_tlv.get_danger_level(pressure)
	))
	var/temperature = environment.return_temperature()
	cur_tlv = TLV["temperature"]
	data["environment_data"] += list(list(
							"name" = "Temperature",
							"value" = temperature,
							"unit" = "K ([round(temperature - T0C, 0.1)]C)",
							"danger_level" = cur_tlv.get_danger_level(temperature)
	))
	var/total_moles = environment.total_moles()
	var/partial_pressure = R_IDEAL_GAS_EQUATION * environment.return_temperature() / environment.return_volume()
	for(var/gas_id in environment.get_gases())
		if(!(gas_id in TLV)) // We're not interested in this gas, it seems.
			continue
		cur_tlv = TLV[gas_id]
		data["environment_data"] += list(list(
								"name" = GLOB.gas_data.names[gas_id],
								"value" = environment.get_moles(gas_id) / total_moles * 100,
								"unit" = "%",
								"danger_level" = cur_tlv.get_danger_level(environment.get_moles(gas_id) * partial_pressure)
		))

	if(!locked || user.has_unlimited_silicon_privilege)
		data["vents"] = list()
		for(var/id_tag in A.air_vent_ids)
			if (id_tag == null)
				continue
			var/long_name = A.air_vent_names[id_tag]
			var/list/info = A.air_vent_info[id_tag]
			if(!info || info["frequency"] != frequency || info["has_aac"])
				continue
			data["vents"] += list(list(
					"id_tag"	= id_tag,
					"long_name" = sanitize(long_name),
					"power"		= info["power"],
					"checks"	= info["checks"],
					"excheck"	= info["checks"]&1,
					"incheck"	= info["checks"]&2,
					"direction"	= info["direction"],
					"external"	= info["external"],
					"internal"	= info["internal"],
					"extdefault"= (info["external"] == ONE_ATMOSPHERE),
					"intdefault"= (info["internal"] == 0)
				))
		data["scrubbers"] = list()
		for(var/id_tag in A.air_scrub_ids)
			if (id_tag == null)
				continue
			var/long_name = A.air_scrub_names[id_tag]
			var/list/info = A.air_scrub_info[id_tag]
			if(!info || info["frequency"] != frequency)
				continue
			data["scrubbers"] += list(list(
					"id_tag"				= id_tag,
					"long_name" 			= sanitize(long_name),
					"power"					= info["power"],
					"scrubbing"				= info["scrubbing"],
					"widenet"				= info["widenet"],
					"filter_types"			= info["filter_types"]
				))
		data["mode"] = mode
		data["modes"] = list()
		data["modes"] += list(list("name" = "Filtering - Scrubs out contaminants", 				"mode" = AALARM_MODE_SCRUBBING,		"selected" = mode == AALARM_MODE_SCRUBBING, 	"danger" = 0))
		data["modes"] += list(list("name" = "Contaminated - Scrubs out ALL contaminants quickly","mode" = AALARM_MODE_CONTAMINATED,	"selected" = mode == AALARM_MODE_CONTAMINATED,	"danger" = 0))
		data["modes"] += list(list("name" = "Draught - Siphons out air while replacing",		"mode" = AALARM_MODE_VENTING,		"selected" = mode == AALARM_MODE_VENTING,		"danger" = 0))
		data["modes"] += list(list("name" = "Refill - Triple vent output",						"mode" = AALARM_MODE_REFILL,		"selected" = mode == AALARM_MODE_REFILL,		"danger" = 1))
		data["modes"] += list(list("name" = "Cycle - Siphons air before replacing", 			"mode" = AALARM_MODE_REPLACEMENT,	"selected" = mode == AALARM_MODE_REPLACEMENT, 	"danger" = 1))
		data["modes"] += list(list("name" = "Siphon - Siphons air out of the room", 			"mode" = AALARM_MODE_SIPHON,		"selected" = mode == AALARM_MODE_SIPHON, 		"danger" = 1))
		data["modes"] += list(list("name" = "Panic Siphon - Siphons air out of the room quickly","mode" = AALARM_MODE_PANIC,		"selected" = mode == AALARM_MODE_PANIC, 		"danger" = 1))
		data["modes"] += list(list("name" = "Off - Shuts off vents and scrubbers", 				"mode" = AALARM_MODE_OFF,			"selected" = mode == AALARM_MODE_OFF, 			"danger" = 0))
		if(obj_flags & EMAGGED)
			data["modes"] += list(list("name" = "Flood - Shuts off scrubbers and opens vents",	"mode" = AALARM_MODE_FLOOD,			"selected" = mode == AALARM_MODE_FLOOD, 		"danger" = 1))

		var/datum/tlv/selected
		var/list/thresholds = list()

		selected = TLV["pressure"]
		thresholds += list(list("name" = "Pressure", "settings" = list()))
		thresholds[thresholds.len]["settings"] += list(list("env" = "pressure", "val" = "min2", "selected" = selected.min2))
		thresholds[thresholds.len]["settings"] += list(list("env" = "pressure", "val" = "min1", "selected" = selected.min1))
		thresholds[thresholds.len]["settings"] += list(list("env" = "pressure", "val" = "max1", "selected" = selected.max1))
		thresholds[thresholds.len]["settings"] += list(list("env" = "pressure", "val" = "max2", "selected" = selected.max2))

		selected = TLV["temperature"]
		thresholds += list(list("name" = "Temperature", "settings" = list()))
		thresholds[thresholds.len]["settings"] += list(list("env" = "temperature", "val" = "min2", "selected" = selected.min2))
		thresholds[thresholds.len]["settings"] += list(list("env" = "temperature", "val" = "min1", "selected" = selected.min1))
		thresholds[thresholds.len]["settings"] += list(list("env" = "temperature", "val" = "max1", "selected" = selected.max1))
		thresholds[thresholds.len]["settings"] += list(list("env" = "temperature", "val" = "max2", "selected" = selected.max2))

		for(var/gas_id in GLOB.gas_data.names)
			if(!(gas_id in TLV)) // We're not interested in this gas, it seems.
				continue
			selected = TLV[gas_id]
			thresholds += list(list("name" = GLOB.gas_data.names[gas_id], "settings" = list()))
			thresholds[thresholds.len]["settings"] += list(list("env" = gas_id, "val" = "min2", "selected" = selected.min2))
			thresholds[thresholds.len]["settings"] += list(list("env" = gas_id, "val" = "min1", "selected" = selected.min1))
			thresholds[thresholds.len]["settings"] += list(list("env" = gas_id, "val" = "max1", "selected" = selected.max1))
			thresholds[thresholds.len]["settings"] += list(list("env" = gas_id, "val" = "max2", "selected" = selected.max2))

		data["thresholds"] = thresholds
	return data

/obj/machinery/airalarm/ui_act(action, params)
	. = ..()

	if(. || buildstage != 2)
		return
	if((locked && !usr.has_unlimited_silicon_privilege) || (usr.has_unlimited_silicon_privilege && aidisabled))
		return
	var/device_id = params["id_tag"]
	switch(action)
		if("lock")
			if(usr.has_unlimited_silicon_privilege && !wires.is_cut(WIRE_IDSCAN))
				locked = !locked
				. = TRUE
		if("power", "toggle_filter", "widenet", "scrubbing", "direction")
			send_signal(device_id, list("[action]" = params["val"]), usr)
			. = TRUE
		if("excheck")
			send_signal(device_id, list("checks" = text2num(params["val"])^1), usr)
			. = TRUE
		if("incheck")
			send_signal(device_id, list("checks" = text2num(params["val"])^2), usr)
			. = TRUE
		if("set_external_pressure", "set_internal_pressure")
			var/target = params["value"]
			if(!isnull(target))
				send_signal(device_id, list("[action]" = target), usr)
				. = TRUE
		if("reset_external_pressure")
			send_signal(device_id, list("reset_external_pressure"), usr)
			. = TRUE
		if("reset_internal_pressure")
			send_signal(device_id, list("reset_internal_pressure"), usr)
			. = TRUE
		if("threshold")
			var/env = params["env"]
			if(text2path(env))
				env = text2path(env)

			var/name = params["var"]
			var/datum/tlv/tlv = TLV[env]
			if(isnull(tlv))
				return
			var/value = input("New [name] for [env]:", name, tlv.vars[name]) as num|null
			if(!isnull(value) && !..())
				if(value < 0)
					tlv.vars[name] = -1
				else
					tlv.vars[name] = round(value, 0.01)
				investigate_log(" treshold value for [env]:[name] was set to [value] by [key_name(usr)]",INVESTIGATE_ATMOS)
				. = TRUE
		if("mode")
			mode = text2num(params["mode"])
			investigate_log("was turned to [get_mode_name(mode)] mode by [key_name(usr)]",INVESTIGATE_ATMOS)
			apply_mode(usr)
			. = TRUE
		if("alarm")
			var/area/A = get_area(src)
			if(A.atmosalert(TRUE, src))
				post_alert(2)
			. = TRUE
		if("reset")
			var/area/A = get_area(src)
			if(A.atmosalert(FALSE, src))
				post_alert(0)
			. = TRUE
		if("heat_mode")
			investigate_log("has had its heat mode by [key_name(usr)]",INVESTIGATE_ATMOS)
			airalarm_toggleheat()
			. = TRUE
		if("heat_setpoint")
			heating_temp_setpoint = params["setPoint"]
			investigate_log("has had its setpoint changed to [heating_temp_setpoint] by [key_name(usr)]",INVESTIGATE_ATMOS)
			. = TRUE

	update_appearance()


/obj/machinery/airalarm/proc/reset(wire)
	switch(wire)
		if(WIRE_POWER)
			if(!wires.is_cut(WIRE_POWER))
				shorted = FALSE
				update_appearance()
		if(WIRE_AI)
			if(!wires.is_cut(WIRE_AI))
				aidisabled = FALSE


/obj/machinery/airalarm/proc/shock(mob/user, prb)
	if((machine_stat & (NOPOWER)))		// unpowered, no shock
		return 0
	if(!prob(prb))
		return 0 //you lucked out, no shock for you
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(5, 1, src)
	s.start() //sparks always.
	if (electrocute_mob(user, get_area(src), src, 1, TRUE))
		return 1
	else
		return 0

/obj/machinery/airalarm/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_TO_AIRALARM)

/obj/machinery/airalarm/proc/send_signal(target, list/command, atom/user)//sends signal 'command' to 'target'. Returns 0 if no radio connection, 1 otherwise
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new(command)
	signal.data["tag"] = target
	signal.data["sigtype"] = "command"
	signal.data["user"] = user
	radio_connection.post_signal(src, signal, RADIO_FROM_AIRALARM)

	return 1

/obj/machinery/airalarm/proc/get_mode_name(mode_value)
	switch(mode_value)
		if(AALARM_MODE_SCRUBBING)
			return "Filtering"
		if(AALARM_MODE_CONTAMINATED)
			return "Contaminated"
		if(AALARM_MODE_VENTING)
			return "Draught"
		if(AALARM_MODE_REFILL)
			return "Refill"
		if(AALARM_MODE_PANIC)
			return "Panic Siphon"
		if(AALARM_MODE_REPLACEMENT)
			return "Cycle"
		if(AALARM_MODE_SIPHON)
			return "Siphon"
		if(AALARM_MODE_OFF)
			return "Off"
		if(AALARM_MODE_FLOOD)
			return "Flood"

/obj/machinery/airalarm/proc/apply_mode(atom/signal_source)
	var/area/A = get_area(src)
	switch(mode)
		if(AALARM_MODE_SCRUBBING)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = filter_basic,
					"scrubbing" = 1,
					"widenet" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE
				), signal_source)
		if(AALARM_MODE_CONTAMINATED)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = filter_extra,
					"scrubbing" = 1,
					"widenet" = 1
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE
				), signal_source)
		if(AALARM_MODE_VENTING)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 0,
					"scrubbing" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE*2
				), signal_source)
		if(AALARM_MODE_REFILL)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = filter_basic,
					"scrubbing" = 1,
					"widenet" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE * 3
				), signal_source)
		if(AALARM_MODE_PANIC,
			AALARM_MODE_REPLACEMENT)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 1,
					"scrubbing" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 0
				), signal_source)
		if(AALARM_MODE_SIPHON)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 0,
					"scrubbing" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 0
				), signal_source)

		if(AALARM_MODE_OFF)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 0
				), signal_source)
		if(AALARM_MODE_FLOOD)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 0
				), signal_source)
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 2,
					"set_internal_pressure" = 0
				), signal_source)

/obj/machinery/airalarm/update_icon_state()
	if(panel_open)
		switch(buildstage)
			if(2)
				icon_state = "alarmx"
			if(1)
				icon_state = "alarm_b2"
			if(0)
				icon_state = "alarm_b1"
		return ..()

	icon_state = "alarm"
	return ..()

/obj/machinery/airalarm/update_overlays()
	. = ..()
	if((machine_stat & (NOPOWER|BROKEN)) || shorted)
		return
	var/area/A = get_area(src)
	var/perc_danger_level = max(danger_level, A.atmosalm)
	if(!panel_open)
		var/emissive_state
		switch(perc_danger_level)
			if(0)
				emissive_state = "alarm0"
			if(1)
				emissive_state = "alarm1"
			if(2)
				emissive_state = "alarm2"

		. += mutable_appearance(icon, emissive_state)
		. += mutable_appearance(icon, "light_emissive", layer, EMISSIVE_PLANE)

	if(perc_danger_level) //When there's any danger level, light up the "AIR" sign too
		. += mutable_appearance(icon, "alarm_sign")
		. += mutable_appearance(icon, "alarm_sign", layer, EMISSIVE_PLANE)

/obj/machinery/airalarm/process(seconds_per_tick)
	if((machine_stat & (NOPOWER|BROKEN)) || shorted)
		return

	var/turf/location = get_turf(src)
	if(!location)
		return

	var/datum/tlv/cur_tlv

	var/datum/gas_mixture/environment = location.return_air()
	var/partial_pressure = R_IDEAL_GAS_EQUATION * environment.return_temperature() / environment.return_volume()

	cur_tlv = TLV["pressure"]
	var/environment_pressure = environment.return_pressure()
	var/pressure_dangerlevel = cur_tlv.get_danger_level(environment_pressure)

	cur_tlv = TLV["temperature"]
	var/temperature_dangerlevel = cur_tlv.get_danger_level(environment.return_temperature())

	var/gas_dangerlevel = 0
	for(var/gas_id in environment.get_gases())
		if(!(gas_id in TLV)) // We're not interested in this gas, it seems.
			continue
		cur_tlv = TLV[gas_id]
		gas_dangerlevel = max(gas_dangerlevel, cur_tlv.get_danger_level(environment.get_moles(gas_id) * partial_pressure))

	var/old_danger_level = danger_level
	danger_level = max(pressure_dangerlevel, temperature_dangerlevel, gas_dangerlevel)

	if(old_danger_level != danger_level)
		apply_danger_level()
	if(mode == AALARM_MODE_REPLACEMENT && environment_pressure < ONE_ATMOSPHERE * 0.05)
		mode = AALARM_MODE_SCRUBBING
		apply_mode(src)
	if(heating_manage)
		airalarm_heat()

/obj/machinery/airalarm/proc/airalarm_toggleheat()
	if(heating_manage)
		if(heating_current_mode == "Heat")
			visible_message(span_notice("The air alarm makes a quiet click as it stops heating the area"))
			heating_current_mode = "Idle"
			heating_manage = FALSE
			return
		else
			heating_manage = FALSE
			return
	else
		heating_manage = TRUE

/obj/machinery/airalarm/proc/airalarm_heat()
	var/wanted_mode = ""
	var/turf/open/location = get_turf(src)
	var/datum/gas_mixture/environment = location.return_air()
	if(!isopenturf(get_turf(src)))
		return
	if(environment.return_temperature() >= (heating_temp_setpoint) & heating_current_mode == "Idle") // Quick kill the proc if not heating
		return
	if(environment.return_temperature() < (heating_temp_setpoint)) //Start heating
		wanted_mode = "Heat"

	if(environment.return_temperature() > (heating_temp_setpoint + 2)) //Allow for some over run, to stop flip-floping
		wanted_mode = "Idle"

	if(wanted_mode == "Idle" & heating_current_mode == "Heat")
		visible_message(span_notice("The air alarm makes a quiet click as it stops heating the area"))
		playsound(src, 'sound/machines/terminal_off.ogg', 40)
		heating_current_mode = "Idle"
		set_idle_power()
		return

	if(wanted_mode == "Heat" & heating_current_mode == "Idle")
		visible_message(span_notice("The air alarm makes a quiet click as it starts heating the area"))
		playsound(src, 'sound/machines/terminal_on.ogg', 40)
		heating_current_mode = "Heat"
		set_active_power()

	if(heating_current_mode == "Heat")
		var/temperature = environment.return_temperature()
		environment.adjust_heat(temperature += heating_temp_inc)

	location.air = environment
	location.air_update_turf(TRUE)

/obj/machinery/airalarm/proc/post_alert(alert_level)
	var/datum/radio_frequency/frequency = SSradio.return_frequency(alarm_frequency)

	if(!frequency)
		return

	var/datum/signal/alert_signal = new(list(
		"zone" = get_area_name(src),
		"type" = "Atmospheric"
	))
	var/area/A = get_area(src)
	if(alert_level==2)
		alert_signal.data["alert"] = "severe"
		A.set_vacuum_alarm_effect()
	else if (alert_level==1)
		alert_signal.data["alert"] = "minor"
	else if (alert_level==0)
		alert_signal.data["alert"] = "clear"
		A.unset_vacuum_alarm_effect()

	frequency.post_signal(src, alert_signal, range = -1)

/obj/machinery/airalarm/proc/apply_danger_level()
	var/area/A = get_area(src)

	var/new_area_danger_level = 0
	for(var/obj/machinery/airalarm/AA in A)
		if (!(AA.machine_stat & (NOPOWER|BROKEN)) && !AA.shorted)
			new_area_danger_level = clamp(max(new_area_danger_level, AA.danger_level), 0, 2)
	if(A.atmosalert(new_area_danger_level,src)) //if area was in normal state or if area was in alert state
		post_alert(new_area_danger_level)

	update_appearance()

/obj/machinery/airalarm/attackby(obj/item/W, mob/user, params)
	switch(buildstage)
		if(2)
			if(W.tool_behaviour == TOOL_WIRECUTTER && panel_open && wires.is_all_cut())
				W.play_tool_sound(src)
				to_chat(user, span_notice("You cut the final wires."))
				new /obj/item/stack/cable_coil(loc, 5)
				buildstage = 1
				update_appearance()
				return
			else if(W.tool_behaviour == TOOL_SCREWDRIVER)  // Opening that Air Alarm up.
				W.play_tool_sound(src)
				panel_open = !panel_open
				to_chat(user, span_notice("The wires have been [panel_open ? "exposed" : "unexposed"]."))
				update_appearance()
				return
			else if(istype(W, /obj/item/card/id) || istype(W, /obj/item/pda))// trying to unlock the interface with an ID card
				togglelock(user)
				return
			else if(panel_open && is_wire_tool(W))
				wires.interact(user)
				return
		if(1)
			if(W.tool_behaviour == TOOL_CROWBAR)
				user.visible_message(span_notice("[user.name] removes the electronics from [src.name]."), \
									span_notice("You start prying out the circuit..."))
				W.play_tool_sound(src)
				if (W.use_tool(src, user, 20))
					if (buildstage == 1)
						to_chat(user, span_notice("You remove the air alarm electronics."))
						new /obj/item/electronics/airalarm(src.loc)
						playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
						buildstage = 0
						update_appearance()
				return

			if(istype(W, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/cable = W
				if(cable.get_amount() < 5)
					to_chat(user, span_warning("You need five lengths of cable to wire the air alarm!"))
					return
				user.visible_message(span_notice("[user.name] wires the air alarm."), \
									span_notice("You start wiring the air alarm..."))
				if (do_after(user, 20, target = src))
					if (cable.get_amount() >= 5 && buildstage == 1)
						cable.use(5)
						to_chat(user, span_notice("You wire the air alarm."))
						wires.repair()
						aidisabled = 0
						locked = FALSE
						mode = 1
						shorted = 0
						post_alert(0)
						buildstage = 2
						update_appearance()
				return
		if(0)
			if(istype(W, /obj/item/electronics/airalarm))
				if(user.temporarilyRemoveItemFromInventory(W))
					to_chat(user, span_notice("You insert the circuit."))
					buildstage = 1
					update_appearance()
					qdel(W)
				return

			if(istype(W, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = W
				if(!P.adapt_circuit(user, 25))
					return
				user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
				span_notice("You adapt an air alarm circuit and slot it into the assembly."))
				buildstage = 1
				update_appearance()
				return

			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(user, span_notice("You detach \the [src] from the wall."))
				W.play_tool_sound(src)
				new /obj/item/wallframe/airalarm(user.loc)
				qdel(src)
				return

	return ..()

/obj/machinery/airalarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/airalarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
			span_notice("You adapt an air alarm circuit and slot it into the assembly."))
			buildstage = 1
			update_appearance()
			return TRUE
	return FALSE

/obj/machinery/airalarm/AltClick(mob/user)
	..()
	if(!user.canUseTopic(src, !issilicon(user)) || !isturf(loc))
		return
	else
		togglelock(user)

/obj/machinery/airalarm/proc/togglelock(mob/living/user)
	if(machine_stat & (NOPOWER|BROKEN))
		to_chat(user, span_warning("It does nothing!"))
	else
		if(src.allowed(usr) && !wires.is_cut(WIRE_IDSCAN))
			locked = !locked
			to_chat(user, span_notice("You [ locked ? "lock" : "unlock"] the air alarm interface."))
			updateUsrDialog()
		else
			to_chat(user, span_danger("Access denied."))
	return

/obj/machinery/airalarm/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	visible_message(span_warning("Sparks fly out of [src]!"), span_notice("You emag [src], disabling its safeties."))
	playsound(src, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/airalarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 2)
		var/obj/item/I = new /obj/item/electronics/airalarm(loc)
		if(!disassembled)
			I.obj_integrity = I.max_integrity * 0.5
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

/obj/machinery/airalarm/proc/handle_decomp_alarm()
	if(!COOLDOWN_FINISHED(src, decomp_alarm))
		return
	playsound(loc, 'sound/machines/FireAlarm.ogg', 75)
	COOLDOWN_START(src, decomp_alarm, 1 SECONDS)

#undef AALARM_MODE_SCRUBBING
#undef AALARM_MODE_VENTING
#undef AALARM_MODE_PANIC
#undef AALARM_MODE_REPLACEMENT
#undef AALARM_MODE_OFF
#undef AALARM_MODE_FLOOD
#undef AALARM_MODE_SIPHON
#undef AALARM_MODE_CONTAMINATED
#undef AALARM_MODE_REFILL
#undef AALARM_REPORT_TIMEOUT


//generic (by snowflake) tile smoothing code; smooth your icons with this!
/*
	Each tile is divided in 4 corners, each corner has an appearance associated to it; the tile is then overlayed by these 4 appearances
	To use this, just set your atom's 'smoothing_flags' var to 1. If your atom can be moved/unanchored, set its 'can_be_unanchored' var to 1.
	If you don't want your atom's icon to smooth with anything but atoms of the same type, set the list 'canSmoothWith' to null;
	Otherwise, put all the smoothing groups you want the atom icon to smooth with in 'canSmoothWith', including the group of the atom itself.
	Smoothing groups are just shared flags between objects. If one of the 'canSmoothWith' of A matches one of the `smoothing_groups` of B, then A will smooth with B.

	Each atom has its own icon file with all the possible corner states. See 'smooth_wall.dmi' for a template.

	DIAGONAL SMOOTHING INSTRUCTIONS
	To make your atom smooth diagonally you need all the proper icon states (see 'smooth_wall.dmi' for a template) and
	to add the 'SMOOTH_DIAGONAL_CORNERS' flag to the atom's smoothing_flags var (in addition to either SMOOTH_TRUE or SMOOTH_MORE).

	For turfs, what appears under the diagonal corners depends on the turf that was in the same position previously: if you make a wall on
	a plating floor, you will see plating under the diagonal wall corner, if it was space, you will see space.

	If you wish to map a diagonal wall corner with a fixed underlay, you must configure the turf's 'fixed_underlay' list var, like so:
		fixed_underlay = list("icon"='icon_file.dmi', "icon_state"="iconstatename")
	A non null 'fixed_underlay' list var will skip copying the previous turf appearance and always use the list. If the list is
	not set properly, the underlay will default to regular floor plating.

	To see an example of a diagonal wall, see '/turf/closed/wall/mineral/titanium' and its subtypes.
*/

//Redefinitions of the diagonal directions so they can be stored in one var without conflicts
#define NORTH_JUNCTION NORTH //(1<<0)
#define SOUTH_JUNCTION SOUTH //(1<<1)
#define EAST_JUNCTION EAST  //(1<<2)
#define WEST_JUNCTION WEST  //(1<<3)
#define NORTHEAST_JUNCTION (1<<4)
#define SOUTHEAST_JUNCTION (1<<5)
#define SOUTHWEST_JUNCTION (1<<6)
#define NORTHWEST_JUNCTION (1<<7)

DEFINE_BITFIELD(smoothing_junction, list(
	"NORTH_JUNCTION" = NORTH_JUNCTION,
	"SOUTH_JUNCTION" = SOUTH_JUNCTION,
	"EAST_JUNCTION" = EAST_JUNCTION,
	"WEST_JUNCTION" = WEST_JUNCTION,
	"NORTHEAST_JUNCTION" = NORTHEAST_JUNCTION,
	"SOUTHEAST_JUNCTION" = SOUTHEAST_JUNCTION,
	"SOUTHWEST_JUNCTION" = SOUTHWEST_JUNCTION,
	"NORTHWEST_JUNCTION" = NORTHWEST_JUNCTION,
))


#define NO_ADJ_FOUND 0
#define ADJ_FOUND 1
#define NULLTURF_BORDER 2

#define DEFAULT_UNDERLAY_ICON 'icons/turf/floors.dmi'
#define DEFAULT_UNDERLAY_ICON_STATE "plating"

#define SET_ADJ_IN_DIR(source, src_area, junction, conn_junction, direction, direction_flag) \
	do { \
		var/turf/neighbor = get_step(source, direction); \
		var/area/ship/source_area = src_area; \
		var/area/ship/target_area = get_area(neighbor); \
		if(!neighbor) { \
			if(source.smoothing_flags & SMOOTH_BORDER) { \
				junction |=  direction_flag; \
				conn_junction |= direction_flag; \
			continue; \
			}; \
		}; \
		else if( \
			((source_area.area_flags & SHIP_SMOOTHING) != (target_area.area_flags & SHIP_SMOOTHING)) || \
			( \
			((source_area.area_flags & SHIP_SMOOTHING) & (target_area.area_flags & SHIP_SMOOTHING)) && \
			source_area.mobile_port != target_area.mobile_port \
			) \
			) { \
				continue; \
				}; \
		else { \
			if(!isnull(neighbor.smoothing_groups)) { \
				for(var/target in source.canSmoothWith) { \
					if(!(source.canSmoothWith[target] & neighbor.smoothing_groups[target])) { \
						continue; \
					}; \
					junction |= direction_flag; \
					if(!is_type_in_typecache(neighbor, source.no_connector_typecache)) { \
						conn_junction |= direction_flag; \
					}; \
					break; \
				}; \
			}; \
			if(!(junction & direction_flag) && source.smoothing_flags & SMOOTH_OBJ) { \
				for(var/obj/thing in neighbor) { \
					if(!thing.anchored || isnull(thing.smoothing_groups)) { \
						continue; \
					}; \
					for(var/target in source.canSmoothWith) { \
						if(!(source.canSmoothWith[target] & thing.smoothing_groups[target])) { \
							continue; \
						}; \
						junction |= direction_flag; \
						if(!is_type_in_typecache(thing, source.no_connector_typecache)) { \
							conn_junction |= direction_flag; \
						}; \
						break; \
					}; \
					if(junction & direction_flag) { \
						break; \
					}; \
				}; \
			}; \
		}; \
	} while(FALSE)

///Scans all adjacent turfs to find targets to smooth with.
/atom/proc/calculate_adjacencies()
	. = NONE

	if(!loc)
		return

	var/area/ship/src_area = get_area(src)

	for(var/direction in GLOB.cardinals)
		switch(find_type_in_direction(direction, src_area))
			if(NULLTURF_BORDER)
				if((smoothing_flags & SMOOTH_BORDER))
					. |= direction //BYOND and smooth dirs are the same for cardinals
			if(ADJ_FOUND)
				. |= direction //BYOND and smooth dirs are the same for cardinals

	if(. & NORTH_JUNCTION)
		if(. & WEST_JUNCTION)
			switch(find_type_in_direction(NORTHWEST, src_area))
				if(NULLTURF_BORDER)
					if((smoothing_flags & SMOOTH_BORDER))
						. |= NORTHWEST_JUNCTION
				if(ADJ_FOUND)
					. |= NORTHWEST_JUNCTION

		if(. & EAST_JUNCTION)
			switch(find_type_in_direction(NORTHEAST, src_area))
				if(NULLTURF_BORDER)
					if((smoothing_flags & SMOOTH_BORDER))
						. |= NORTHEAST_JUNCTION
				if(ADJ_FOUND)
					. |= NORTHEAST_JUNCTION

	if(. & SOUTH_JUNCTION)
		if(. & WEST_JUNCTION)
			switch(find_type_in_direction(SOUTHWEST, src_area))
				if(NULLTURF_BORDER)
					if((smoothing_flags & SMOOTH_BORDER))
						. |= SOUTHWEST_JUNCTION
				if(ADJ_FOUND)
					. |= SOUTHWEST_JUNCTION

		if(. & EAST_JUNCTION)
			switch(find_type_in_direction(SOUTHEAST, src_area))
				if(NULLTURF_BORDER)
					if((smoothing_flags & SMOOTH_BORDER))
						. |= SOUTHEAST_JUNCTION
				if(ADJ_FOUND)
					. |= SOUTHEAST_JUNCTION


/atom/movable/calculate_adjacencies()
	if(can_be_unanchored && !anchored)
		return NONE
	return ..()


//do not use, use QUEUE_SMOOTH(atom)
/atom/proc/smooth_icon()
	smoothing_flags &= ~SMOOTH_QUEUED
	flags_1 |= HTML_USE_INITAL_ICON_1
	if (!z)
		CRASH("[type] called smooth_icon() without being on a z-level")
	if(smoothing_flags & SMOOTH_CORNERS)
		if(smoothing_flags & SMOOTH_DIAGONAL_CORNERS)
			corners_diagonal_smooth(calculate_adjacencies())
		else
			corners_cardinal_smooth(calculate_adjacencies())
	else if(smoothing_flags & SMOOTH_BITMASK)
		bitmask_smooth()
	else
		CRASH("smooth_icon called for [src] with smoothing_flags == [smoothing_flags]")


/atom/proc/corners_diagonal_smooth(adjacencies)
	switch(adjacencies)
		if(NORTH_JUNCTION|WEST_JUNCTION)
			replace_smooth_overlays("d-se","d-se-0")
		if(NORTH_JUNCTION|EAST_JUNCTION)
			replace_smooth_overlays("d-sw","d-sw-0")
		if(SOUTH_JUNCTION|WEST_JUNCTION)
			replace_smooth_overlays("d-ne","d-ne-0")
		if(SOUTH_JUNCTION|EAST_JUNCTION)
			replace_smooth_overlays("d-nw","d-nw-0")

		if(NORTH_JUNCTION|WEST_JUNCTION|NORTHWEST_JUNCTION)
			replace_smooth_overlays("d-se","d-se-1")
		if(NORTH_JUNCTION|EAST_JUNCTION|NORTHEAST_JUNCTION)
			replace_smooth_overlays("d-sw","d-sw-1")
		if(SOUTH_JUNCTION|WEST_JUNCTION|SOUTHWEST_JUNCTION)
			replace_smooth_overlays("d-ne","d-ne-1")
		if(SOUTH_JUNCTION|EAST_JUNCTION|SOUTHEAST_JUNCTION)
			replace_smooth_overlays("d-nw","d-nw-1")

		else
			corners_cardinal_smooth(adjacencies)
			return FALSE

	icon_state = ""
	return TRUE


/atom/proc/corners_cardinal_smooth(adjacencies)
	//NW CORNER
	var/nw = "1-i"
	if((adjacencies & NORTH_JUNCTION) && (adjacencies & WEST_JUNCTION))
		if(adjacencies & NORTHWEST_JUNCTION)
			nw = "1-f"
		else
			nw = "1-nw"
	else
		if(adjacencies & NORTH_JUNCTION)
			nw = "1-n"
		else if(adjacencies & WEST_JUNCTION)
			nw = "1-w"

	//NE CORNER
	var/ne = "2-i"
	if((adjacencies & NORTH_JUNCTION) && (adjacencies & EAST_JUNCTION))
		if(adjacencies & NORTHEAST_JUNCTION)
			ne = "2-f"
		else
			ne = "2-ne"
	else
		if(adjacencies & NORTH_JUNCTION)
			ne = "2-n"
		else if(adjacencies & EAST_JUNCTION)
			ne = "2-e"

	//SW CORNER
	var/sw = "3-i"
	if((adjacencies & SOUTH_JUNCTION) && (adjacencies & WEST_JUNCTION))
		if(adjacencies & SOUTHWEST_JUNCTION)
			sw = "3-f"
		else
			sw = "3-sw"
	else
		if(adjacencies & SOUTH_JUNCTION)
			sw = "3-s"
		else if(adjacencies & WEST_JUNCTION)
			sw = "3-w"

	//SE CORNER
	var/se = "4-i"
	if((adjacencies & SOUTH_JUNCTION) && (adjacencies & EAST_JUNCTION))
		if(adjacencies & SOUTHEAST_JUNCTION)
			se = "4-f"
		else
			se = "4-se"
	else
		if(adjacencies & SOUTH_JUNCTION)
			se = "4-s"
		else if(adjacencies & EAST_JUNCTION)
			se = "4-e"

	var/list/new_overlays

	if(top_left_corner != nw)
		cut_overlay(top_left_corner)
		top_left_corner = nw
		LAZYADD(new_overlays, nw)

	if(top_right_corner != ne)
		cut_overlay(top_right_corner)
		top_right_corner = ne
		LAZYADD(new_overlays, ne)

	if(bottom_right_corner != sw)
		cut_overlay(bottom_right_corner)
		bottom_right_corner = sw
		LAZYADD(new_overlays, sw)

	if(bottom_left_corner != se)
		cut_overlay(bottom_left_corner)
		bottom_left_corner = se
		LAZYADD(new_overlays, se)

	if(new_overlays)
		add_overlay(new_overlays)


///Scans direction to find targets to smooth with.
/atom/proc/find_type_in_direction(direction, area/ship/source_area)
	var/turf/target_turf = get_step(src, direction)
	if(!target_turf)
		return NULLTURF_BORDER

	/*Special case for smoothing ships. They should only blend in their own areas, not elsewhere.
	Note that smoothing is mostly done through the SET_ADJ_IN_DIR() macro, not here, which has the same exception.*/
	var/area/ship/target_area = get_area(target_turf)

	/*If one has SHIP_SMOOTHING and the other does not, no smoothing. Both areas need SHIP_SMOOTHING and then be of the same mobile port to tile together.
	Bitmath is very fast. The only way to make this faster is if mobile_port was a global area variable, so then you can compare mobile_port without checking for SHIP_SMOOTHING.*/
	if((source_area.area_flags & SHIP_SMOOTHING) != (target_area.area_flags & SHIP_SMOOTHING) || \
		( \
		((source_area.area_flags & SHIP_SMOOTHING) & (target_area.area_flags & SHIP_SMOOTHING)) && source_area.mobile_port != target_area.mobile_port \
		))
		return NO_ADJ_FOUND

	if(isnull(canSmoothWith)) //special case in which it will only smooth with itself
		if(isturf(src))
			return (type == target_turf.type) ? ADJ_FOUND : NO_ADJ_FOUND
		var/atom/matching_obj = locate(type) in target_turf
		return (matching_obj && matching_obj.type == type) ? ADJ_FOUND : NO_ADJ_FOUND

	if(!isnull(target_turf.smoothing_groups))
		for(var/target in canSmoothWith)
			if(!(canSmoothWith[target] & target_turf.smoothing_groups[target]))
				continue
			return ADJ_FOUND

	if(smoothing_flags & SMOOTH_OBJ)
		for(var/am in target_turf)
			var/atom/movable/thing = am
			if(!thing.anchored || isnull(thing.smoothing_groups))
				continue
			for(var/target in canSmoothWith)
				if(!(canSmoothWith[target] & thing.smoothing_groups[target]))
					continue
				return ADJ_FOUND

	return NO_ADJ_FOUND


/**
 * Basic smoothing proc. The atom checks for adjacent directions to smooth with and changes the icon_state based on that.
 *
 * Returns the previous smoothing_junction state so the previous state can be compared with the new one after the proc ends, and see the changes, if any.
 *
*/
/atom/proc/bitmask_smooth()
	var/new_junction = NONE
	var/new_conn_junction = NONE
	var/area/src_area = get_area(src) //Proc here and send out to optimize the rest of the calls.

	for(var/direction in GLOB.cardinals) //Cardinal case first.
		SET_ADJ_IN_DIR(src, src_area, new_junction, new_conn_junction, direction, direction)

	if(!(new_junction & (NORTH|SOUTH)) || !(new_junction & (EAST|WEST)))
		set_smoothed_icon_state(new_junction)
		if(smoothing_flags & SMOOTH_CONNECTORS)
			set_connector_overlay(new_conn_junction)
		return

	if(new_junction & NORTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SET_ADJ_IN_DIR(src, src_area, new_junction, new_conn_junction, NORTHWEST, NORTHWEST_JUNCTION)

		if(new_junction & EAST_JUNCTION)
			SET_ADJ_IN_DIR(src, src_area, new_junction, new_conn_junction, NORTHEAST, NORTHEAST_JUNCTION)

	if(new_junction & SOUTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SET_ADJ_IN_DIR(src, src_area, new_junction, new_conn_junction, SOUTHWEST, SOUTHWEST_JUNCTION)

		if(new_junction & EAST_JUNCTION)
			SET_ADJ_IN_DIR(src, src_area, new_junction, new_conn_junction, SOUTHEAST, SOUTHEAST_JUNCTION)

	set_smoothed_icon_state(new_junction)
	if(smoothing_flags & SMOOTH_CONNECTORS)
		if(new_conn_junction & NORTH_JUNCTION)
			new_conn_junction |= new_junction & (NORTHEAST_JUNCTION | NORTHWEST_JUNCTION)
		if(new_conn_junction & SOUTH_JUNCTION)
			new_conn_junction |= new_junction & (SOUTHEAST_JUNCTION | SOUTHWEST_JUNCTION)
		if(new_conn_junction & EAST_JUNCTION)
			new_conn_junction |= new_junction & (NORTHEAST_JUNCTION | SOUTHEAST_JUNCTION)
		if(new_conn_junction & WEST_JUNCTION)
			new_conn_junction |= new_junction & (NORTHWEST_JUNCTION | SOUTHWEST_JUNCTION)
		set_connector_overlay(new_conn_junction)

///Changes the icon state based on the new junction bitmask. Returns the old junction value.
/atom/proc/set_smoothed_icon_state(new_junction)
	. = smoothing_junction
	smoothing_junction = new_junction
	icon_state = "[base_icon_state]-[smoothing_junction]"

/atom/proc/set_connector_overlay(new_conn_junction)
	if(new_conn_junction == connector_junction)
		return
	cut_overlay(connector_overlay)

	connector_junction = new_conn_junction
	if(!connector_junction)
		connector_overlay = null
		return

	connector_overlay = iconstate2appearance(connector_icon, "[connector_icon_state]-[connector_junction]")
	add_overlay(connector_overlay)

/turf/closed/set_smoothed_icon_state(new_junction)
	. = ..()
	if(smoothing_flags & SMOOTH_DIAGONAL_CORNERS)
		switch(new_junction)
			if(
				NORTH_JUNCTION|WEST_JUNCTION,
				NORTH_JUNCTION|EAST_JUNCTION,
				SOUTH_JUNCTION|WEST_JUNCTION,
				SOUTH_JUNCTION|EAST_JUNCTION,
				NORTH_JUNCTION|WEST_JUNCTION|NORTHWEST_JUNCTION,
				NORTH_JUNCTION|EAST_JUNCTION|NORTHEAST_JUNCTION,
				SOUTH_JUNCTION|WEST_JUNCTION|SOUTHWEST_JUNCTION,
				SOUTH_JUNCTION|EAST_JUNCTION|SOUTHEAST_JUNCTION
				)
				icon_state = "[base_icon_state]-[smoothing_junction]-d"
				if(!fixed_underlay && new_junction != .) // Mutable underlays?
					var/junction_dir = reverse_ndir(smoothing_junction)
					var/turned_adjacency = REVERSE_DIR(junction_dir)
					var/turf/neighbor_turf = get_step(src, turned_adjacency & (NORTH|SOUTH))
					if(!neighbor_turf) //You can step out of map boundaries
						return
					var/mutable_appearance/underlay_appearance = mutable_appearance(layer = TURF_LAYER, plane = FLOOR_PLANE)
					if(!neighbor_turf.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
						neighbor_turf = get_step(src, turned_adjacency & (EAST|WEST))
						if(!neighbor_turf) //You can step out of map boundaries
							return
						if(!neighbor_turf.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
							neighbor_turf = get_step(src, turned_adjacency)
							if(!neighbor_turf.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
								if(!get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency)) //if all else fails, ask our own turf
									underlay_appearance.icon = DEFAULT_UNDERLAY_ICON
									underlay_appearance.icon_state = DEFAULT_UNDERLAY_ICON_STATE
					underlays = list(underlay_appearance)


/turf/open/floor/set_smoothed_icon_state(new_junction)
	if(broken || burnt)
		return
	return ..()


//Icon smoothing helpers
/proc/smooth_zlevel(zlevel, now = FALSE)
	var/list/away_turfs = block(locate(1, 1, zlevel), locate(world.maxx, world.maxy, zlevel))
	for(var/V in away_turfs)
		var/turf/T = V
		if(T.smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
			if(now)
				T.smooth_icon()
			else
				QUEUE_SMOOTH(T)
		for(var/R in T)
			var/atom/A = R
			if(A.smoothing_flags & (SMOOTH_CORNERS|SMOOTH_BITMASK))
				if(now)
					A.smooth_icon()
				else
					QUEUE_SMOOTH(A)


/atom/proc/clear_smooth_overlays()
	cut_overlay(top_left_corner)
	top_left_corner = null
	cut_overlay(top_right_corner)
	top_right_corner = null
	cut_overlay(bottom_right_corner)
	bottom_right_corner = null
	cut_overlay(bottom_left_corner)
	bottom_left_corner = null


/atom/proc/replace_smooth_overlays(nw, ne, sw, se)
	clear_smooth_overlays()
	var/list/O = list()
	top_left_corner = nw
	O += nw
	top_right_corner = ne
	O += ne
	bottom_left_corner = sw
	O += sw
	bottom_right_corner = se
	O += se
	add_overlay(O)


/proc/reverse_ndir(ndir)
	switch(ndir)
		if(NORTH_JUNCTION)
			return NORTH
		if(SOUTH_JUNCTION)
			return SOUTH
		if(WEST_JUNCTION)
			return WEST
		if(EAST_JUNCTION)
			return EAST
		if(NORTHWEST_JUNCTION)
			return NORTHWEST
		if(NORTHEAST_JUNCTION)
			return NORTHEAST
		if(SOUTHEAST_JUNCTION)
			return SOUTHEAST
		if(SOUTHWEST_JUNCTION)
			return SOUTHWEST
		if(NORTH_JUNCTION | WEST_JUNCTION)
			return NORTHWEST
		if(NORTH_JUNCTION | EAST_JUNCTION)
			return NORTHEAST
		if(SOUTH_JUNCTION | WEST_JUNCTION)
			return SOUTHWEST
		if(SOUTH_JUNCTION | EAST_JUNCTION)
			return SOUTHEAST
		if(NORTH_JUNCTION | WEST_JUNCTION | NORTHWEST_JUNCTION)
			return NORTHWEST
		if(NORTH_JUNCTION | EAST_JUNCTION | NORTHEAST_JUNCTION)
			return NORTHEAST
		if(SOUTH_JUNCTION | WEST_JUNCTION | SOUTHWEST_JUNCTION)
			return SOUTHWEST
		if(SOUTH_JUNCTION | EAST_JUNCTION | SOUTHEAST_JUNCTION)
			return SOUTHEAST
		else
			return NONE


//Example smooth wall
/turf/closed/wall/smooth
	name = "smooth wall"
	icon = 'icons/turf/smooth_wall.dmi'
	icon_state = "smooth"
	smoothing_flags = SMOOTH_CORNERS|SMOOTH_DIAGONAL_CORNERS|SMOOTH_BORDER
	smoothing_groups = null
	canSmoothWith = null

#undef NORTH_JUNCTION
#undef SOUTH_JUNCTION
#undef EAST_JUNCTION
#undef WEST_JUNCTION
#undef NORTHEAST_JUNCTION
#undef NORTHWEST_JUNCTION
#undef SOUTHEAST_JUNCTION
#undef SOUTHWEST_JUNCTION

#undef NO_ADJ_FOUND
#undef ADJ_FOUND
#undef NULLTURF_BORDER

#undef DEFAULT_UNDERLAY_ICON
#undef DEFAULT_UNDERLAY_ICON_STATE

#undef SET_ADJ_IN_DIR

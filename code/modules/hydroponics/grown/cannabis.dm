// Cannabis
/obj/item/seeds/cannabis
	name = "pack of cannabis seeds"
	desc = "Taxable."
	icon_state = "seed-cannabis"
	species = "cannabis"
	plantname = "Cannabis Plant"
	product = /obj/item/food/grown/cannabis
	maturation = 8
	potency = 20
	growthstages = 1
	growing_icon = 'icons/obj/hydroponics/growing.dmi'
	icon_grow = "cannabis-grow" // Uses one growth icons set for all the subtypes
	icon_dead = "cannabis-dead" // Same for the dead icon
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	mutatelist = list(/obj/item/seeds/cannabis/rainbow,
						/obj/item/seeds/cannabis/death,
						/obj/item/seeds/cannabis/white,
						/obj/item/seeds/cannabis/ultimate)
	reagents_add = list(/datum/reagent/drug/space_drugs = 0.15, /datum/reagent/toxin/lipolicide = 0.35) // gives u the munchies

/obj/item/seeds/cannabis/rainbow
	name = "pack of rainbow weed seeds"
	desc = "These seeds grow into rainbow weed. Groovy... and also highly addictive."
	icon_state = "seed-megacannabis"
	species = "megacannabis"
	plantname = "Rainbow Weed"
	product = /obj/item/food/grown/cannabis/rainbow
	mutatelist = list()
	reagents_add = list(/datum/reagent/colorful_reagent = 0.05, /datum/reagent/medicine/psicodine = 0.03, /datum/reagent/drug/happiness = 0.1, /datum/reagent/toxin/mindbreaker = 0.1, /datum/reagent/toxin/lipolicide = 0.15)
	rarity = 40
	research = PLANT_RESEARCH_TIER_2

/obj/item/seeds/cannabis/death
	name = "pack of deathweed seeds"
	desc = "These seeds grow into deathweed. Not groovy."
	icon_state = "seed-blackcannabis"
	species = "blackcannabis"
	plantname = "Deathweed"
	product = /obj/item/food/grown/cannabis/death
	mutatelist = list()
	reagents_add = list(/datum/reagent/toxin/cyanide = 0.35, /datum/reagent/drug/space_drugs = 0.15, /datum/reagent/toxin/lipolicide = 0.15)
	rarity = 40
	research = PLANT_RESEARCH_TIER_2

/obj/item/seeds/cannabis/white
	name = "pack of lifeweed seeds"
	desc = "I will give unto him that is munchies of the fountain of the cravings of life, freely."
	icon_state = "seed-whitecannabis"
	species = "whitecannabis"
	plantname = "Lifeweed"
	product = /obj/item/food/grown/cannabis/white
	mutatelist = list()
	reagents_add = list(/datum/reagent/medicine/omnizine = 0.35, /datum/reagent/drug/space_drugs = 0.15, /datum/reagent/toxin/lipolicide = 0.15)
	rarity = 40
	research = PLANT_RESEARCH_TIER_3

/obj/item/seeds/cannabis/ultimate
	name = "pack of omega weed seeds"
	desc = "These seeds grow into omega weed."
	icon_state = "seed-ocannabis"
	species = "ocannabis"
	plantname = "Omega Weed"
	product = /obj/item/food/grown/cannabis/ultimate
	genes = list(/datum/plant_gene/trait/repeated_harvest, /datum/plant_gene/trait/glow/green)
	mutatelist = list()
	reagents_add = list(/datum/reagent/drug/space_drugs = 0.3,
						/datum/reagent/toxin/mindbreaker = 0.3,
						/datum/reagent/mercury = 0.15,
						/datum/reagent/lithium = 0.15,
						/datum/reagent/medicine/atropine = 0.15,
						/datum/reagent/drug/methamphetamine = 0.15,
						/datum/reagent/drug/crank = 0.15,
						/datum/reagent/toxin/lipolicide = 0.15,
						/datum/reagent/drug/nicotine = 0.1)
	rarity = 69
	research = PLANT_RESEARCH_TIER_4

/obj/item/food/grown/cannabis
	seed = /obj/item/seeds/cannabis
	icon = 'icons/obj/hydroponics/harvest.dmi'
	name = "cannabis leaf"
	desc = "Recently legalized in most galaxies."
	icon_state = "cannabis"
	bite_consumption_mod = 4
	foodtypes = VEGETABLES //i dont really know what else weed could be to be honest
	tastes = list("cannabis" = 1)
	wine_power = 20

/obj/item/food/grown/cannabis/rainbow
	seed = /obj/item/seeds/cannabis/rainbow
	name = "rainbow cannabis leaf"
	desc = "Is it supposed to be glowing like that...?"
	icon_state = "megacannabis"
	wine_power = 60

/obj/item/food/grown/cannabis/death
	seed = /obj/item/seeds/cannabis/death
	name = "death cannabis leaf"
	desc = "Looks a bit dark. Oh well."
	icon_state = "blackcannabis"
	wine_power = 40

/obj/item/food/grown/cannabis/white
	seed = /obj/item/seeds/cannabis/white
	name = "white cannabis leaf"
	desc = "It feels smooth and nice to the touch."
	icon_state = "whitecannabis"
	wine_power = 40
	wine_flavor = "medicinal properties" //WS edit: new wine flavors

/obj/item/food/grown/cannabis/ultimate
	seed = /obj/item/seeds/cannabis/ultimate
	name = "omega cannabis leaf"
	desc = "You feel dizzy looking at it. What the fuck?"
	icon_state = "ocannabis"
	bite_consumption_mod = 2 // Ingesting like 40 units of drugs in 1 bite at 100 potency
	max_volume = 420
	wine_power = 120
	wine_flavor = "the highest highs and the lowest lows" //WS edit: new wine flavors

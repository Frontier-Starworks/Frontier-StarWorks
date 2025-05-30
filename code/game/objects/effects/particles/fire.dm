// Fire related particles.
/particles/bonfire
	icon = 'icons/effects/particles/bonfire.dmi'
	icon_state = "bonfire"
	width = 100
	height = 100
	count = 1000
	spawning = 4
	lifespan = 0.7 SECONDS
	fade = 1 SECONDS
	grow = -0.01
	velocity = list(0, 0)
	position = generator(GEN_CIRCLE, 0, 16, NORMAL_RAND)
	drift = generator(GEN_VECTOR, list(0, -0.2), list(0, 0.2))
	gravity = list(0, 0.95)
	scale = generator(GEN_VECTOR, list(0.3, 0.3), list(1,1), NORMAL_RAND)
	rotation = 30
	spin = generator(GEN_NUM, -20, 20)

/particles/embers
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("dot" = 4,"cross" = 1,"curl" = 1)
	width = 64
	height = 96
	count = 100
	spawning = 5
	lifespan = 3 SECONDS
	fade = 1 SECONDS
	color = 0
	color_change = 0.05
	gradient = list("#FBAF4D", "#FCE6B6", "#FD481C")
	position = generator(GEN_BOX, list(-12,-16,0), list(12,16,0), NORMAL_RAND)
	drift = generator(GEN_VECTOR, list(-0.1,0), list(0.1,0.025))
	spin = generator(GEN_NUM, list(-15,15), NORMAL_RAND)
	scale = generator(GEN_VECTOR, list(0.5,0.5), list(2,2), NORMAL_RAND)

/particles/embers/lava
	width = 700
	height = 700
	gradient = list(LIGHT_COLOR_FLARE, LIGHT_COLOR_FLARE, COLOR_ALMOST_BLACK)
	spawning = 1
	count = 10

/particles/lava
	width = 700
	height = 700
	count = 500
	spawning = 1
	lifespan = 4 SECONDS
	fade = 2 SECONDS
	position = generator(GEN_CIRCLE, 16, 24, NORMAL_RAND)
	drift = generator(GEN_VECTOR, list(-0.2, -0.2), list(0.6, 0.6))
	velocity = generator(GEN_CIRCLE, -6, 6, NORMAL_RAND)
	friction = 0.15
	gradient = list(0,LIGHT_COLOR_FLARE , 0.75, COLOR_ALMOST_BLACK)
	color_change = 0.125

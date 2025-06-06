/obj/machinery/plantgenes
	name = "plant DNA manipulator"
	desc = "An advanced device designed to manipulate the genetic makeup of a plant."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "dnamod"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/plantgenes
	pass_flags = PASSTABLE

	var/obj/item/seeds/seed
	var/obj/item/disk/plantgene/disk

	var/list/core_genes = list()
	var/list/reagent_genes = list()
	var/list/trait_genes = list()

	var/datum/plant_gene/target
	var/operation = ""
	// yogs start
	var/max_potency = 35 //See RefreshParts() for how these work
	var/max_yield = 10
	var/min_production = 1
	var/max_endurance = 40 //IMPT: ALSO AFFECTS LIFESPAN
	// yogs stop
	var/min_wchance = 67
	var/min_wrate = 10

/obj/machinery/plantgenes/RefreshParts() // Comments represent the max you can set per tier, respectively. seeds.dm [219] clamps these for us but we don't want to mislead the viewer.
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		if(M.rating > 3)
			max_potency = 100 // yogs
		else
			max_potency = initial(max_potency) + (M.rating* 15) // yogs - TG's old version: 53,59,77,95 	 Clamps at 100, Yog's superior version: 50, 65, 80, 100

		max_yield = initial(max_yield) // yogs - TG's old version: 4,6,8,10 	Clamps at 10, Yog's version: 10 at all levels

	for(var/obj/item/stock_parts/scanning_module/SM in component_parts)
		if(SM.rating > 3) //If you create t5 parts I'm a step ahead mwahahaha!
			min_production = 1
		else
			min_production = 1 // yogs - TG's old version: 9,6,3,1. Requires if to avoid going below clamp [1], Yog's superior version: 1. No point of leaving this in, but I left it anyway.

		max_endurance = initial(max_endurance) + (SM.rating * 15) // yogs - TG's old version: 35,60,85,100	Clamps at 10min 100max, Yog's version: 55, 70, 85, 100

	for(var/obj/item/stock_parts/micro_laser/ML in component_parts)
		var/wratemod = ML.rating * 2.5
		min_wrate = FLOOR(10-wratemod,1) // 7,5,2,0	Clamps at 0 and 10	You want this low
		min_wchance = 67-(ML.rating*16) // 48,35,19,3 	Clamps at 0 and 67	You want this low
	for(var/obj/item/circuitboard/machine/plantgenes/vaultcheck in component_parts)
		if(istype(vaultcheck, /obj/item/circuitboard/machine/plantgenes/vault)) // TRAIT_DUMB BOTANY TUTS
			max_potency = 100
			max_yield = 10
			min_production = 1
			max_endurance = 100
			min_wchance = 0
			min_wrate = 0

/obj/machinery/plantgenes/update_icon_state()
	. = ..()
	if((stat & (BROKEN|NOPOWER)))
		icon_state = "dnamod-off"
	else
		icon_state = "dnamod"

/obj/machinery/plantgenes/update_overlays()
	. = ..()
	if(seed)
		. += "dnamod-dna"
	if(disk)
		. += "dnamod-disk"
	if(panel_open)
		. += "dnamod-open"

/obj/machinery/plantgenes/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "dnamod", "dnamod", I))
		update_appearance(UPDATE_ICON)
		return
	if(default_deconstruction_crowbar(I))
		return
	if(iscyborg(user))
		return

	if(istype(I, /obj/item/seeds))
		if(seed)
			to_chat(user, span_warning("A sample is already loaded into the machine!"))
		else
			if(!user.temporarilyRemoveItemFromInventory(I))
				return
			insert_seed(I)
			to_chat(user, span_notice("You add [I] to the machine."))
			interact(user)
		return
	else if(istype(I, /obj/item/disk/plantgene))
		if (operation)
			to_chat(user, span_notice("Please complete current operation."))
			return
		eject_disk()
		if(!user.transferItemToLoc(I, src))
			return
		disk = I
		to_chat(user, span_notice("You add [I] to the machine."))
		interact(user)
	else
		..()

/obj/machinery/plantgenes/ui_interact(mob/user)
	. = ..()
	if(!user)
		return

	var/datum/browser/popup = new(user, "plantdna", "Plant DNA Manipulator", 450, 600)
	if(!(in_range(src, user) || issilicon(user)))
		popup.close()
		return

	var/dat = ""

	if(operation)
		if(!seed || (!target && operation != "insert"))
			operation = ""
			target = null
			interact(user)
			return
		if((operation == "replace" || operation == "insert") && (!disk || !disk.gene))
			operation = ""
			target = null
			interact(user)
			return

		dat += "<div class='line'><h3>Confirm Operation</h3></div>"
		dat += "<div class='statusDisplay'>Are you sure you want to [operation] "
		switch(operation)
			if("remove")
				dat += "[span_highlight("[target.get_name()]")] gene from \the [span_highlight("[seed]")]?<br>"
			if("extract")
				dat += "[span_highlight("[target.get_name()]")] gene from \the [span_highlight("[seed]")]?<br>"
				dat += span_bad("The sample will be destroyed in process!")
				if(istype(target, /datum/plant_gene/core))
					var/datum/plant_gene/core/gene = target
					if(istype(target, /datum/plant_gene/core/potency))
						if(gene.value > max_potency)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[max_potency]")] potency. "
							dat += "Target gene will be degraded to [span_highlight("[max_potency]")] potency on extraction."
					else if(istype(target, /datum/plant_gene/core/lifespan))
						if(gene.value > max_endurance)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[max_endurance]")] lifespan. "
							dat += "Target gene will be degraded to [span_highlight("[max_endurance]")] Lifespan on extraction."
					else if(istype(target, /datum/plant_gene/core/endurance))
						if(gene.value > max_endurance)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[max_endurance]")] endurance. "
							dat += "Target gene will be degraded to [span_highlight("[max_endurance]")] endurance on extraction."
					else if(istype(target, /datum/plant_gene/core/yield))
						if(gene.value > max_yield)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[max_yield]")] yield. "
							dat += "Target gene will be degraded to [span_highlight("[max_yield]")] yield on extraction."
					else if(istype(target, /datum/plant_gene/core/production))
						if(gene.value < min_production)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[min_production]")] production. "
							dat += "Target gene will be degraded to [span_highlight("[min_production]")] production on extraction."
					else if(istype(target, /datum/plant_gene/core/weed_rate))
						if(gene.value < min_wrate)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[min_wrate]")] weed rate. "
							dat += "Target gene will be degraded to [span_highlight("[min_wrate]")] weed rate on extraction."
					else if(istype(target, /datum/plant_gene/core/weed_chance))
						if(gene.value < min_wchance)
							dat += "<br><br>This device's extraction capabilities are currently limited to [span_highlight("[min_wchance]")] weed chance. "
							dat += "Target gene will be degraded to [span_highlight("[min_wchance]")] weed chance on extraction."

			if("replace")
				dat += "[span_highlight("[target.get_name()]")] gene with [span_highlight("[disk.gene.get_name()]")]?<br>"
			if("insert")
				dat += "[span_highlight("[disk.gene.get_name()]")] gene into \the [span_highlight("[seed]")]?<br>"
		dat += "</div><div class='line'><a href='byond://?src=[REF(src)];gene=[REF(target)];op=[operation]'>Confirm</a> "
		dat += "<a href='byond://?src=[REF(src)];abort=1'>Abort</a></div>"
		popup.set_content(dat)
		popup.open()
		return

	dat+= "<div class='statusDisplay'>"

	dat += "<div class='line'><div class='statusLabel'>Plant Sample:</div><div class='statusValue'><a href='byond://?src=[REF(src)];eject_seed=1'>"
	dat += seed ? seed.name : "None"
	dat += "</a></div></div>"

	dat += "<div class='line'><div class='statusLabel'>Data Disk:</div><div class='statusValue'><a href='byond://?src=[REF(src)];eject_disk=1'>"
	if(!disk)
		dat += "None"
	else if(!disk.gene)
		dat += "Empty Disk"
	else
		dat += disk.gene.get_name()
	if(disk && disk.read_only)
		dat += " (RO)"
	dat += "</a></div></div>"

	dat += "<br></div>"

	if(seed)
		var/can_insert = disk && disk.gene && disk.gene.can_add(seed)
		var/can_extract = disk && !disk.read_only

		dat += "<div class='line'><h3>Core Genes</h3></div><div class='statusDisplay'><table>"
		for(var/a in core_genes)
			var/datum/plant_gene/G = a
			if(!G)
				continue
			dat += "<tr><td width='260px'>[G.get_name()]</td><td>"
			if(can_extract)
				dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=extract'>Extract</a>"
			if(can_insert && istype(disk.gene, G.type))
				dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=replace'>Replace</a>"
			dat += "</td></tr>"
		dat += "</table></div>"

		if(seed.yield != -1)
			dat += "<div class='line'><h3>Content Genes</h3></div><div class='statusDisplay'>"
			if(reagent_genes.len)
				dat += "<table>"
				for(var/a in reagent_genes)
					var/datum/plant_gene/G = a
					dat += "<tr><td width='260px'>[G.get_name()]</td><td>"
					if(can_extract)
						dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=extract'>Extract</a>"
					dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=remove'>Remove</a>"
					dat += "</td></tr>"
				dat += "</table>"
			else
				dat += "No content-related genes detected in sample.<br>"
			dat += "</div>"
			if(can_insert && istype(disk.gene, /datum/plant_gene/reagent))
				dat += "<a href='byond://?src=[REF(src)];op=insert'>Insert: [disk.gene.get_name()]</a>"

			dat += "<div class='line'><h3>Trait Genes</h3></div><div class='statusDisplay'>"
			if(trait_genes.len)
				dat += "<table>"
				for(var/a in trait_genes)
					var/datum/plant_gene/G = a
					dat += "<tr><td width='260px'>[G.get_name()]</td><td>"
					if(can_extract)
						dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=extract'>Extract</a>"
					dat += "<a href='byond://?src=[REF(src)];gene=[REF(G)];op=remove'>Remove</a>"
					dat += "</td></tr>"
				dat += "</table>"
			else
				dat += "No trait-related genes detected in sample.<br>"
			if(can_insert && istype(disk.gene, /datum/plant_gene/trait))
				dat += "<a href='byond://?src=[REF(src)];op=insert'>Insert: [disk.gene.get_name()]</a>"
			dat += "</div>"
	else
		dat += "<br>No sample found.<br>[span_highlight("Please, insert a plant sample to use this device.")]"
	popup.set_content(dat)
	popup.open()


/obj/machinery/plantgenes/Topic(href, list/href_list)
	if(..())
		return

	var/mob/user = usr
	user.set_machine(src)

	if(href_list["eject_seed"] && !operation)
		if (seed)
			seed.forceMove(drop_location())
			seed.verb_pickup()
			seed = null
			update_genes()
			update_appearance(UPDATE_ICON)
		else
			var/obj/item/I = usr.get_active_held_item()
			if (istype(I, /obj/item/seeds))
				if(!usr.temporarilyRemoveItemFromInventory(I))
					return
				insert_seed(I)
				to_chat(usr, span_notice("You add [I] to the machine."))
		update_appearance(UPDATE_ICON)
	else if(href_list["eject_disk"] && !operation)
		var/obj/item/I = usr.get_active_held_item()
		eject_disk()
		if(istype(I, /obj/item/disk/plantgene))
			if(!usr.transferItemToLoc(I, src))
				return
			disk = I
			to_chat(usr, span_notice("You add [I] to the machine."))
			update_appearance(UPDATE_ICON)
	else if(href_list["op"] == "insert" && disk && disk.gene && seed)
		if(!operation) // Wait for confirmation
			operation = "insert"
		else
			if(!istype(disk.gene, /datum/plant_gene/core) && disk.gene.can_add(seed))
				seed.genes += disk.gene.Copy()
				if(istype(disk.gene, /datum/plant_gene/reagent))
					var/datum/plant_gene/reagent/G = disk.gene
					if(istype(G.reagent_id,/datum/reagent/water) || istype(G.reagent_id,/datum/reagent/potassium))
						var/opposing_reagent = istype(G.reagent_id,/datum/reagent/water) ? /datum/reagent/potassium : /datum/reagent/water
						for(var/datum/plant_gene/reagent/reagentgene in seed.genes)
							if(istype(reagentgene,opposing_reagent))
								message_admins("[key_name(usr)] has added [G.reagent_id] to a seed that contains [reagentgene.reagent_id].")
								log_admin("[key_name(usr)] has added [G.reagent_id] to a seed that contains [reagentgene.reagent_id].")
					seed.reagents_from_genes()
			update_genes()
			repaint_seed()
			operation = ""
			target = null

	else if(href_list["gene"] && seed)
		var/datum/plant_gene/G = seed.get_gene(href_list["gene"])
		if(!G || !href_list["op"] || !(href_list["op"] in list("remove", "extract", "replace")))
			interact(usr)
			return

		if(!operation || target != G) // Wait for confirmation
			target = G
			operation = href_list["op"]

		else if(operation == href_list["op"] && target == G)
			switch(href_list["op"])
				if("remove")
					if(!istype(G, /datum/plant_gene/core))
						seed.genes -= G
						if(istype(G, /datum/plant_gene/reagent))
							seed.reagents_from_genes()
					repaint_seed()
				if("extract")
					if(disk && !disk.read_only)
						disk.gene = G
						if(istype(G, /datum/plant_gene/core))
							var/datum/plant_gene/core/gene = G
							if(istype(G, /datum/plant_gene/core/potency))
								gene.value = min(gene.value, max_potency)
							else if(istype(G, /datum/plant_gene/core/lifespan))
								gene.value = min(gene.value, max_endurance) //INTENDED
							else if(istype(G, /datum/plant_gene/core/endurance))
								gene.value = min(gene.value, max_endurance)
							else if(istype(G, /datum/plant_gene/core/production))
								gene.value = max(gene.value, min_production)
							else if(istype(G, /datum/plant_gene/core/yield))
								gene.value = min(gene.value, max_yield)
							else if(istype(G, /datum/plant_gene/core/weed_rate))
								gene.value = max(gene.value, min_wrate)
							else if(istype(G, /datum/plant_gene/core/weed_chance))
								gene.value = max(gene.value, min_wchance)
						if(G.extract_value && user.add_exp(SKILL_SCIENCE, G.extract_value, G.type))
							user.playsound_local(get_turf(src), 'sound/machines/ping.ogg', 25, TRUE)
							balloon_alert(user, "new trait catalogued: [lowertext(G.name)]")
						disk.update_appearance()
						qdel(seed)
						seed = null
						update_appearance(UPDATE_ICON)
				if("replace")
					if(disk && disk.gene && istype(disk.gene, G.type) && istype(G, /datum/plant_gene/core))
						seed.genes -= G
						var/datum/plant_gene/core/C = disk.gene.Copy()
						seed.genes += C
						C.apply_stat(seed)
						repaint_seed()
				if("insert")
					if(disk && disk.gene && !istype(disk.gene, /datum/plant_gene/core) && disk.gene.can_add(seed))
						seed.genes += disk.gene.Copy()
						if(istype(disk.gene, /datum/plant_gene/reagent))
							seed.reagents_from_genes()
						disk.gene.apply_vars(seed)
						repaint_seed()


			update_genes()
			operation = ""
			target = null
	else if(href_list["abort"])
		operation = ""
		target = null

	interact(usr)

/obj/machinery/plantgenes/proc/insert_seed(obj/item/seeds/S)
	if(!istype(S) || seed)
		return
	S.forceMove(src)
	seed = S
	update_genes()
	update_appearance(UPDATE_ICON)

/obj/machinery/plantgenes/proc/eject_disk()
	if (disk && !operation)
		if(Adjacent(usr) && !issilicon(usr))
			if (!usr.put_in_hands(disk))
				disk.forceMove(drop_location())
		else
			disk.forceMove(drop_location())
		disk = null
		update_genes()
		update_appearance(UPDATE_ICON)

/obj/machinery/plantgenes/proc/update_genes()
	core_genes = list()
	reagent_genes = list()
	trait_genes = list()

	if(seed)
		var/gene_paths = list(
			/datum/plant_gene/core/potency,
			/datum/plant_gene/core/yield,
			/datum/plant_gene/core/production,
			/datum/plant_gene/core/endurance,
			/datum/plant_gene/core/lifespan,
			/datum/plant_gene/core/weed_rate,
			/datum/plant_gene/core/weed_chance
			)
		for(var/a in gene_paths)
			core_genes += seed.get_gene(a)

		for(var/datum/plant_gene/reagent/G in seed.genes)
			reagent_genes += G

		for(var/datum/plant_gene/trait/G in seed.genes)
			trait_genes += G

/obj/machinery/plantgenes/proc/repaint_seed()
	if(!seed)
		return
	if(copytext(seed.name, 1, 13) == "experimental")//13 == length("experimental") + 1
		return // Already modded name and icon
	seed.name = "experimental " + seed.name
	seed.icon_state = "seed-x"

// Gene modder for seed vault ship, built with high tech alien parts.
/obj/machinery/plantgenes/seedvault
	circuit = /obj/item/circuitboard/machine/plantgenes/vault

/*
 *  Plant DNA disk
 */

/obj/item/disk/plantgene
	name = "plant data disk"
	desc = "A disk for storing plant genetic data."
	icon_state = "datadisk_hydro"
	materials = list(/datum/material/iron=30, /datum/material/glass=10)
	var/datum/plant_gene/gene
	var/read_only = 0 //Well, it's still a floppy disk
	obj_flags = UNIQUE_RENAME | UNIQUE_REDESC

/obj/item/disk/plantgene/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_ICON)
	src.pixel_x = rand(-5, 5)
	src.pixel_y = rand(-5, 5)

/obj/item/disk/plantgene/update_overlays()
	. = ..()
	if(gene)
		. += "datadisk_gene"

/obj/item/disk/plantgene/update_name(updates=ALL)
	. = ..()
	if(gene)
		name = "[gene.get_name()] (plant data disk)"
	else
		name = "plant data disk"

/obj/item/disk/plantgene/attack_self(mob/user)
	read_only = !read_only
	to_chat(user, span_notice("You flip the write-protect tab to [src.read_only ? "protected" : "unprotected"]."))

/obj/item/disk/plantgene/examine(mob/user)
	. = ..()
	if(gene && (istype(gene, /datum/plant_gene/core/potency)))
		. += span_notice("Percent is relative to potency, not maximum volume of the plant.")
	. += "The write-protect tab is set to [src.read_only ? "protected" : "unprotected"]."

/obj/machinery/plantgenes/AltClick(mob/user)
	if(!user.canUseTopic(src, !issilicon(user)))
		return
	eject_disk()

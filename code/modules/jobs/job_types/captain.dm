/datum/job/captain
	title = "Captain"
	description = "Be responsible for the station, manage your Heads of Staff, \
		keep the crew alive, be prepared to do anything and everything or die \
		horribly trying."
	orbit_icon = "crown"
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY|DEADMIN_POSITION_CRITICAL
	department_head = list("CentCom")
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "Nanotrasen officers and Space law" //Changed to officer to separate from CentCom officials being their superior.
	req_admin_notify = 1
	space_law_notify = 1 //Yogs
	minimal_player_age = 14
	exp_requirements = 900 //15 hours
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_COMMAND
	alt_titles = list("Station Commander", "Facility Director", "Chief Executive Officer", "Big Boss")

	outfit = /datum/outfit/job/captain

	added_access = list() 			//See get_access()
	base_access = list() 	//See get_access()
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC

	department_for_prefs = /datum/job_department/captain
	departments_list = list(
		/datum/job_department/command,
	)

	base_skills = list(
		SKILL_PHYSIOLOGY = EXP_LOW,
		SKILL_MECHANICAL = EXP_LOW,
		SKILL_TECHNICAL = EXP_LOW,
		SKILL_SCIENCE = EXP_LOW,
		SKILL_FITNESS = EXP_MID,
	)
	skill_points = 2

	mind_traits = list(TRAIT_DISK_VERIFIER)

	mail_goodies = list(
		/obj/item/clothing/mask/cigarette/cigar/havana = 20,
		///obj/item/storage/fancy/cigarettes/cigars/havana = 15,
		/obj/item/reagent_containers/food/drinks/bottle/champagne = 10,
		/obj/item/fakeartefact = 5,
		/obj/item/skub = 1,
		/obj/item/greentext = 1
	)
	
	minimal_lightup_areas = list(
		/area/crew_quarters/heads/captain,
		/area/crew_quarters/heads/hop,
		/area/security
	)

	display_order = JOB_DISPLAY_ORDER_CAPTAIN
	minimal_character_age = 35 //Feasibly expected to know everything and potentially do anything. Leagues of experience, briefing, training, and trust required for this role

	smells_like = "unquestionable leadership"

/datum/job/captain/get_access()
	return get_all_accesses()

/datum/job/captain/announce(mob/living/carbon/human/H)
	..()
	SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(minor_announce), "Captain [H.real_name] on deck!"))

/datum/outfit/job/captain
	name = "Captain"
	jobtype = /datum/job/captain

	id_type = /obj/item/card/id/gold
	pda_type = /obj/item/modular_computer/tablet/phone/preset/advanced/command/cap

	glasses = /obj/item/clothing/glasses/hud/personnel
	ears = /obj/item/radio/headset/heads/captain/alt
	gloves = /obj/item/clothing/gloves/color/captain
	uniform =  /obj/item/clothing/under/rank/command/captain
	uniform_skirt = /obj/item/clothing/under/rank/command/captain/skirt
	suit = /obj/item/clothing/suit/armor/vest/capcarapace
	shoes = /obj/item/clothing/shoes/sneakers/brown
	digitigrade_shoes = /obj/item/clothing/shoes/xeno_wraps/command
	head = /obj/item/clothing/head/caphat
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/station_charter=1, /obj/item/gun/energy/e_gun=1) //yogs - adds egun/removes civ budget

	backpack = /obj/item/storage/backpack/captain
	satchel = /obj/item/storage/backpack/satchel/cap
	duffelbag = /obj/item/storage/backpack/duffelbag/captain

	implants = list(/obj/item/implant/mindshield)
	accessory = /obj/item/clothing/accessory/medal/gold/captain

	chameleon_extras = list(/obj/item/gun/energy/e_gun, /obj/item/stamp/captain)

	var/special_charter

/datum/outfit/job/captain/pre_equip(mob/living/carbon/human/H, visualsOnly)
	. = ..()
	special_charter = CHECK_MAP_JOB_CHANGE("Captain", "special_charter")
	if(!special_charter)
		return

	backpack_contents -= /obj/item/station_charter

	if(!l_hand)
		l_hand = /obj/item/station_charter/flag
	else if(!r_hand)
		r_hand = /obj/item/station_charter/flag

/datum/outfit/job/captain/post_equip(mob/living/carbon/human/equipped, visualsOnly)
	. = ..()
	if(visualsOnly || !special_charter)
		return

	var/obj/item/station_charter/flag/celestial_charter = locate() in equipped.held_items
	if(isnull(celestial_charter))
		// failed to give out the unique charter, plop on the ground
		celestial_charter = new(get_turf(equipped))


/datum/outfit/job/captain/hardsuit
	name = "Captain (Hardsuit)"

	mask = /obj/item/clothing/mask/gas/sechailer
	suit = /obj/item/clothing/suit/space/hardsuit/swat/captain
	suit_store = /obj/item/tank/internals/oxygen

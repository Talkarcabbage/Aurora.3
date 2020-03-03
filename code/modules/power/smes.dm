// the SMES
// stores power

#define SMESRATE (1 / ( 3600 / (MACHINERY_TICKRATE/10) )) // Watt hour capacity storage
#define SMESMAXCHARGELEVEL 250 KILOWATTS
#define SMESMAXOUTPUT 250 KILOWATTS

//Cache defines
#define SMES_CLEVEL_1		1
#define SMES_CLEVEL_2		2
#define SMES_CLEVEL_3		3
#define SMES_CLEVEL_4		4
#define SMES_CLEVEL_5		5
#define SMES_OUTPUTTING		6
#define SMES_OUTPUT_ATTEMPT 7
#define SMES_NOT_OUTPUTTING 8
#define SMES_INPUTTING		9
#define SMES_INPUT_ATTEMPT	10
#define SMES_INPUT_MAX		11

/obj/machinery/power/smes
	name = "power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit."
	icon_state = "smes"
	density = 1
	anchored = 1
	use_power = 0
	clicksound = "switch"

	var/capacity = 50 KILOWATTS // maximum charge
	var/charge = 10 KILOWATTS // actual charge

	var/input_attempt = 0 				// 1 = attempting to charge, 0 = not attempting to charge
	var/inputting = 0 					// 1 = actually inputting, 0 = not inputting
	var/input_level = 50 KILOWATTS		// amount of power the SMES attempts to charge by
	var/input_level_max = 200 KILOWATTS	// cap on input_level
	var/input_taken = 0 				// amount that we received from powernet last tick

	var/output_attempt = 0 					// 1 = attempting to output, 0 = not attempting to output
	var/outputting = 0 						// 2 = actually outputting, 1 or 0 = not outputting
	var/output_level = 50 KILOWATTS			// amount of power the SMES attempts to output
	var/output_level_max = 200 KILOWATTS	// cap on output_level
	var/output_used = 0						// amount of power actually outputted. may be less than output_level if the powernet returns excess power

	//Holders for powerout event.
	//var/last_output_attempt	= 0
	//var/last_input_attempt	= 0
	//var/last_charge			= 0

	//For icon overlay updates
	var/last_disp
	var/last_chrg
	var/last_onln

	var/input_cut = 0
	var/input_pulsed = 0
	var/output_cut = 0
	var/output_pulsed = 0
	var/is_critical = FALSE			// Use by gridcheck event, if set to true we do not disable it
	var/failure_timer = 0			// Set by gridcheck event, temporarily disables the SMES.
	var/target_load = 0
	var/open_hatch = 0
	var/name_tag = null
	var/building_terminal = 0 //Suggestions about how to avoid clickspam building several terminals accepted!
	var/obj/machinery/power/terminal/terminal = null
	var/should_be_mapped = 0 // If this is set to 0 it will send out warning on New()
	var/datum/effect_system/sparks/big_spark
	var/datum/effect_system/sparks/small_spark

	var/time = 0
	var/charge_mode = 0
	var/last_time = 1

/obj/machinery/power/smes/drain_power(var/drain_check, var/surge, var/amount = 0)

	if(drain_check)
		return 1

	var/smes_amt = min((amount * SMESRATE), charge)
	charge -= smes_amt
	return smes_amt / SMESRATE

/obj/machinery/power/smes/Destroy()
	QDEL_NULL(big_spark)
	QDEL_NULL(small_spark)
	SSpower.smes_units -= src
	QDEL_NULL(terminal)
	return ..()	// TODO: Properly clean up terminal.

/obj/machinery/power/smes/Initialize()
	. = ..()
	SSpower.smes_units += src
	big_spark = bind_spark(src, 5, alldirs)
	small_spark = bind_spark(src, 3)
	if(!powernet)
		connect_to_network()

	dir_loop:
		for(var/d in cardinal)
			var/turf/T = get_step(src, d)
			for(var/obj/machinery/power/terminal/term in T)
				if(term && term.dir == turn(d, 180))
					terminal = term
					break dir_loop
	if(!terminal)
		stat |= BROKEN
		return
	terminal.master = src
	if(!terminal.powernet)
		terminal.connect_to_network()
	update_icon()

	if(!should_be_mapped)
		warning("Non-buildable or Non-magical SMES at [src.x]X [src.y]Y [src.z]Z")

/obj/machinery/power/smes/add_avail(var/amount)
	if(..(amount))
		powernet.smes_newavail += amount
		return 1
	return 0


/obj/machinery/power/smes/disconnect_terminal()
	if(terminal)
		terminal.master = null
		terminal = null
		return 1
	return 0

/obj/machinery/power/smes/update_icon()
	cut_overlays()
	if(stat & BROKEN)
		return

	if(inputting == 2)
		add_overlay("smes-oc2")
	else if (inputting == 1)
		add_overlay("smes-oc1")
	else if (input_attempt)
		add_overlay("smes-oc0")

	var/clevel = chargedisplay()
	if(clevel)
		add_overlay("smes-og[clevel]")

	if(outputting == 2)
		add_overlay("smes-op2")
	else if (outputting == 1)
		add_overlay("smes-op1")
	else
		add_overlay("smes-op0")

/obj/machinery/power/smes/proc/chargedisplay()
	return round(5.5*charge/(capacity ? capacity : 5e6))

/obj/machinery/power/smes/proc/input_power(var/percentage)
	var/inputted_power = target_load * (percentage/100)
	inputted_power = between(0, inputted_power, target_load)
	if(terminal && terminal.powernet)
		inputted_power = terminal.powernet.draw_power(inputted_power)
		charge += inputted_power * SMESRATE
		input_taken = inputted_power
		if(percentage == 100)
			inputting = 2
		else if(percentage)
			inputting = 1
		// else inputting = 0, as set in process()

/obj/machinery/power/smes/proc/update_time()

	var/delta_power = input_taken - output_used
	delta_power *= SMESRATE

	var/goal = (delta_power < 0) ? (charge) : (capacity - charge)

	var/time_secs = (delta_power) ? ((goal / abs(delta_power)) * (MACHINERY_TICKRATE / 10)) : (0)
	// If it is negative - we are discharging
	if(delta_power < 0)
		charge_mode = 0
	else if(delta_power != 0)
		charge_mode = 1
	else
		charge_mode = 2
	last_time = world.time
	time = ((time_secs / 3600) > 1) ? ("[round(time_secs / 3600)] hours, [round((time_secs % 3600) / 60)] minutes") : ("[round(time_secs / 60)] minutes, [round(time_secs % 60)] seconds")

/obj/machinery/power/smes/machinery_process()
	if(stat & BROKEN)	return
	if(failure_timer)	// Disabled by gridcheck.
		failure_timer--
		return

	// only update icon if state changed
	if(last_disp != chargedisplay() || last_chrg != inputting || last_onln != outputting)
		update_icon()

	//store machine state to see if we need to update the icon overlays
	last_disp = chargedisplay()
	last_chrg = inputting
	last_onln = outputting

	update_time()

	//inputting
	if(input_attempt && (!input_pulsed && !input_cut))
		target_load = min((capacity-charge)/SMESRATE, input_level)	// Amount we will request from the powernet.
		if(terminal && terminal.powernet)
			terminal.powernet.smes_demand += target_load
			terminal.powernet.inputting.Add(src)
		else
			target_load = 0 // We won't input any power without powernet connection.
			input_taken=0
		inputting = 0
	else
		input_taken=0 // Power input isn't called if we aren't trying to input. Without this, the UI assumes we are still charging based on the last charge received.

	//outputting
	if(output_attempt && (!output_pulsed && !output_cut) && powernet && charge)
		output_used = min( charge/SMESRATE, output_level)		//limit output to that stored
		charge -= output_used*SMESRATE		// reduce the storage (may be recovered in /restore() if excessive)
		add_avail(output_used)				// add output to powernet (smes side)
		outputting = 2
	else if((!powernet || !charge) && output_attempt)
		outputting = 1
		output_used=0 // Like input_taken, UI doesn't update used-value to 0 if no charge present or output is broken.
	else
		outputting = 0
		output_used=0

// called after all power processes are finished
// restores charge level to smes if there was excess this ptick
/obj/machinery/power/smes/proc/restore(var/percent_load)
	if(stat & BROKEN)
		return

	if(!outputting)
		output_used = 0
		return

	var/total_restore = output_used * (percent_load / 100) // First calculate amount of power used from our output
	total_restore = between(0, total_restore, output_used) // Now clamp the value between 0 and actual output, just for clarity.
	total_restore = output_used - total_restore			   // And, at last, subtract used power from outputted power, to get amount of power we will give back to the SMES.

	// now recharge this amount

	var/clev = chargedisplay()

	charge += total_restore * SMESRATE		// restore unused power
	powernet.netexcess -= total_restore		// remove the excess from the powernet, so later SMESes don't try to use it

	output_used -= total_restore

	if(clev != chargedisplay() ) //if needed updates the icons overlay
		update_icon()
	return

//Will return 1 on failure
/obj/machinery/power/smes/proc/make_terminal(const/mob/user)
	if (user.loc == loc)
		to_chat(user, "<span class='warning'>You must not be on the same tile as the [src].</span>")
		return 1

	//Direction the terminal will face to
	var/tempDir = get_dir(user, src)
	switch(tempDir)
		if (NORTHEAST, SOUTHEAST)
			tempDir = EAST
		if (NORTHWEST, SOUTHWEST)
			tempDir = WEST
	var/turf/tempLoc = get_step(src, reverse_direction(tempDir))
	if (istype(tempLoc, /turf/space))
		to_chat(user, "<span class='warning'>You can't build a terminal on space.</span>")
		return 1
	else if (istype(tempLoc))
		if(!tempLoc.is_plating())
			to_chat(user, "<span class='warning'>You must remove the floor plating first.</span>")
			return 1
	to_chat(user, "<span class='notice'>You start adding cable to the [src].</span>")
	if(do_after(user, 50))
		terminal = new /obj/machinery/power/terminal(tempLoc)
		terminal.set_dir(tempDir)
		terminal.master = src
		return 0
	return 1


/obj/machinery/power/smes/draw_power(var/amount)
	if(terminal && terminal.powernet)
		return terminal.powernet.draw_power(amount)
	return 0


/obj/machinery/power/smes/attack_ai(mob/user)
	add_hiddenprint(user)
	ui_interact(user)

/obj/machinery/power/smes/attack_hand(mob/user)
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/power/smes/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if(W.isscrewdriver())
		if(!open_hatch)
			open_hatch = 1
			to_chat(user, "<span class='notice'>You open the maintenance hatch of [src].</span>")
			return 0
		else
			open_hatch = 0
			to_chat(user, "<span class='notice'>You close the maintenance hatch of [src].</span>")
			return 0

	if (!open_hatch)
		to_chat(user, "<span class='warning'>You need to open access hatch on [src] first!</span>")
		return 0

	if(W.iscoil() && !terminal && !building_terminal)
		building_terminal = 1
		var/obj/item/stack/cable_coil/CC = W
		if (CC.get_amount() <= 10)
			to_chat(user, "<span class='warning'>You need more cables.</span>")
			building_terminal = 0
			return 0
		if (make_terminal(user))
			building_terminal = 0
			return 0
		building_terminal = 0
		CC.use(10)
		user.visible_message(\
				"<span class='notice'>[user.name] has added cables to the [src].</span>",\
				"<span class='notice'>You added cables to the [src].</span>")
		terminal.connect_to_network()
		stat = 0
		return 0

	else if(W.iswirecutter() && terminal && !building_terminal)
		building_terminal = 1
		var/turf/tempTDir = terminal.loc
		if (istype(tempTDir))
			if(!tempTDir.is_plating())
				to_chat(user, "<span class='warning'>You must remove the floor plating first.</span>")
			else
				to_chat(user, "<span class='notice'>You begin to cut the cables...</span>")
				playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
				if(do_after(user, 50/W.toolspeed))
					if (prob(50) && electrocute_mob(usr, terminal.powernet, terminal))
						big_spark.queue()
						building_terminal = 0
						if(usr.stunned)
							return 0
					new /obj/item/stack/cable_coil(loc,10)
					user.visible_message(\
						"<span class='notice'>[user.name] cut the cables and dismantled the power terminal.</span>",\
						"<span class='notice'>You cut the cables and dismantle the power terminal.</span>")
					qdel(terminal)
		building_terminal = 0
		return 0
	return 1	
	
/obj/machinery/power/smes/vueui_data_change(var/list/data, var/mob/user, var/datum/vueui/ui)
	if(!data)
		. = data = list()
	var/output_accuracy = 0.1
	var/input_accuracy = 0.1
	if (input_taken < 100000)
		input_accuracy = 0.01
	if (output_used < 100000)
		output_accuracy = 0.01
	VUEUI_SET_CHECK(data["name_tag"], name_tag, ., data)
	if (capacity)
		VUEUI_SET_CHECK(data["percentage_stored"], Percentage(), ., data)
	VUEUI_SET_CHECK(data["is_inputting"], inputting, ., data)
	VUEUI_SET_CHECK(data["input_attempt"], input_attempt, ., data)
	VUEUI_SET_CHECK(data["input_level"], input_level/1000, ., data) //kW
	VUEUI_SET_CHECK(data["input_level_max"], input_level_max/1000, ., data) //kW
	VUEUI_SET_CHECK(data["input_taken"], round(input_taken/1000, input_accuracy), ., data)
	VUEUI_SET_CHECK(data["is_outputting"], outputting, ., data)
	VUEUI_SET_CHECK(data["output_attempt"], output_attempt, ., data)
	VUEUI_SET_CHECK(data["output_level"], output_level/1000, ., data)
	VUEUI_SET_CHECK(data["output_level_max"], output_level_max/1000, ., data)
	VUEUI_SET_CHECK(data["output_used"], round(output_used/1000, output_accuracy), ., data)
	VUEUI_SET_CHECK(data["time"], time, ., data)
	VUEUI_SET_CHECK(data["charge_load_ratio"], charge_mode, ., data) // I believe this is 0=negative gain, 1=positive gain, 2=equal gain/discharge?
	VUEUI_SET_CHECK(data["capacity"], round(capacity/1000, 0.1), ., data) //kWh based on baystation.
	VUEUI_SET_CHECK(data["capacity_stored"], round(charge/1000, 0.1), ., data)
	VUEUI_SET_CHECK(data["failure_timer"], failure_timer * 2, ., data)

/obj/machinery/power/smes/ui_interact(mob/user)
	if(stat & BROKEN)
		return
		//VUE WOOOOOOOO
	var/datum/vueui/ui = SSvueui.get_open_ui(user, src)
	if (!ui)
		ui = new(user, src, "misc-smes", 540, 420, (name_tag ? name_tag : "SMES"))
	ui.data=vueui_data_change(list(), user, ui)
	ui.open()

/obj/machinery/power/smes/proc/Percentage()
	return round(100.0*charge/capacity, 0.1)

/obj/machinery/power/smes/Topic(href, href_list)
	if(..())
		return 1

	if( href_list["c_attempt"] )
		if (href_list["c_attempt"]=="auto")
			inputting(1)
		if (href_list["c_attempt"]=="off")
			inputting(0)
		update_icon()

	else if( href_list["o_attempt"] )
		if (href_list["o_attempt"]=="on")
			outputting(1)
		if (href_list["o_attempt"]=="off")
			outputting(0)
		update_icon()
	else if( href_list["reboot"] )
		failure_timer = 0
		update_icon()
	else if( href_list["input"] )
		switch( href_list["input"] )
			if("min")
				input_level = 0
			if ("-100")
				input_level = input_level-100000
			if ("-10")
				input_level = input_level-10000
			if("set")
				input_level = (input(usr, "Enter new input level in kW (0-[input_level_max/1000])", "SMES Input Power Control", input_level/1000) as num)*1000
			if ("+10")
				input_level = input_level+10000
			if ("+100")
				input_level = input_level+100000
			if("max")
				input_level = input_level_max
		input_level = max(0, min(input_level_max, input_level))	// clamp to range

	else if( href_list["output"] )
		switch( href_list["output"] )
			if("min")
				output_level = 0
			if ("-100")
				output_level = output_level-100000
			if ("-10")
				output_level = output_level-10000
			if("set")
				output_level = (input(usr, "Enter new output level in kW (0-[output_level_max/1000])", "SMES Output Power Control", output_level/1000) as num)*1000
			if ("+10")
				output_level = output_level+10000
			if ("+100")
				output_level = output_level+100000
			if("max")
				output_level = output_level_max
		output_level = max(0, min(output_level_max, output_level))	// clamp to range
	else if(href_list["set_input"])
		if (isnum(href_list["set_input"]["value"]))
			input_level = Clamp(href_list["set_input"]["value"], 0, input_level_max/1000)*1000

	investigate_log("input/output; <font color='[input_level>output_level?"green":"red"][input_level]/[output_level]</font> | Output-mode: [output_attempt?"<font color='green'>on</font>":"<font color='red'>off</font>"] | Input-mode: [input_attempt?"<font color='green'>auto</font>":"<font color='red'>off</font>"] by [usr.key]","singulo")

	SSvueui.check_uis_for_change(src)
	return 1

/obj/machinery/power/smes/proc/energy_fail(var/duration)
	failure_timer = max(failure_timer, duration)

/obj/machinery/power/smes/proc/ion_act()
	if(isStationLevel(src.z))
		if(prob(1)) //explosion
			for(var/mob/M in viewers(src))
				M.show_message("<span class='warning'>The [src.name] is making strange noises!</span>", 3, "<span class='warning'>You hear sizzling electronics.</span>", 2)
			sleep(10*pick(4,5,6,7,10,14))
			var/datum/effect/effect/system/smoke_spread/smoke = new /datum/effect/effect/system/smoke_spread()
			smoke.set_up(3, 0, src.loc)
			smoke.attach(src)
			smoke.start()
			explosion(src.loc, -1, 0, 1, 3, 1, 0)
			qdel(src)
			return
		else if(prob(15)) //Power drain
			small_spark.queue()
			if(prob(50))
				emp_act(1)
			else
				emp_act(2)
		else if(prob(5)) //smoke only
			var/datum/effect/effect/system/smoke_spread/smoke = new /datum/effect/effect/system/smoke_spread()
			smoke.set_up(3, 0, src.loc)
			smoke.attach(src)
			smoke.start()
		else
			energy_fail(rand(0, 30))

/obj/machinery/power/smes/proc/inputting(var/do_input)
	input_attempt = do_input
	if(!input_attempt)
		inputting = 0

/obj/machinery/power/smes/proc/outputting(var/do_output)
	output_attempt = do_output
	if(!output_attempt)
		outputting = 0

/obj/machinery/power/smes/emp_act(severity)
	if(prob(50))
		inputting(rand(0,1))
		outputting(rand(0,1))
	if(prob(50))
		output_level = rand(0, output_level_max)
		input_level = rand(0, input_level_max)
	if(prob(50))
		charge -= 1e6/severity
		if (charge < 0)
			charge = 0
	if(prob(50))
		energy_fail(rand(0 + (severity * 30),30 + (severity * 30)))
	update_icon()
	..()


/obj/machinery/power/smes/magical
	name = "quantum power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit. Gains energy from quantum entanglement link."
	capacity = 5000000
	output_level = 250000
	should_be_mapped = 1

/obj/machinery/power/smes/magical/machinery_process()
	charge = 5000000
	..()

#undef SMES_CLEVEL_1
#undef SMES_CLEVEL_2
#undef SMES_CLEVEL_3
#undef SMES_CLEVEL_4
#undef SMES_CLEVEL_5
#undef SMES_OUTPUTTING
#undef SMES_OUTPUT_ATTEMPT
#undef SMES_NOT_OUTPUTTING
#undef SMES_INPUTTING
#undef SMES_INPUT_ATTEMPT
#undef SMES_INPUT_MAX

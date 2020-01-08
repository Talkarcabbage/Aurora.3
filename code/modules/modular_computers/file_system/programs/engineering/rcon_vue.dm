/datum/computer_file/program/rcon_vue
	filename = "rcon-vue"
	filedesc = "RCON Remote Control"
	program_icon_state = "generic"
	extended_desc = "This program allows remote control of power distribution systems around the station. This program can not be run on tablet computers."
	required_access_run = access_engine
	required_access_download = access_ce
	requires_ntnet = 1
	network_destination = "RCON remote control system"
	requires_ntnet_feature = NTNET_SYSTEMCONTROL
	usage_flags = PROGRAM_ALL
	size = 19
	color = LIGHT_COLOR_GREEN

/datum/computer_file/program/rcon_vue/New()
	. = ..()
	

/datum/computer_file/program/rcon_vue/ui_interact(mob/user as mob)
	var/datum/vueui/ui = SSvueui.get_open_ui(user, src)
	if (!ui)
		ui = new /datum/vueui/modularcomputer(user, src, "mcomputer-rcon-vue", 570, 520, filedesc)
	ui.data=vueui_data_change()
	ui.auto_update_content=TRUE
	ui.open()

/datum/computer_file/program/rcon_vue/vueui_data_change(list/data, mob/user, datum/vueui/ui)
	if (!data)
		. = data = list()
	var/headerdata = get_header_data(data["_PC"])
	if(headerdata)
		data["_PC"] = headerdata
		. = data
	// SMES DATA (simplified view)
	var/list/smeslist[0]
	var/load_acc = 0.1
	for(var/obj/machinery/power/smes/buildable/SMES in SSpower.rcon_smes_units)
		if (SMES.output_used < 100000)
			load_acc=0.01
		else
			load_acc=0.1
		smeslist.Add(list(list(
		"charge_percentage" = round(SMES.Percentage()),
		"charge" = round(SMES.charge/100000, 0.1), //kWh
		"capacity" = SMES.capacity/100000,
		"input_set" = SMES.input_attempt,
		"input_val" = SMES.input_level/1000, //kW
		"output_set" = SMES.output_attempt,
		"output_val" = SMES.output_level/1000,
		"output_load" = round(SMES.output_used/1000, load_acc),
		"RCON_tag" = SMES.RCon_tag,
		"uuid" = "\ref[SMES]"
		)))

	VUEUI_SET_CHECK(data["smeslist"], smeslist, ., data)
	data["smes_info"] = smeslist
	// BREAKER DATA (simplified view)
	var/list/breakerlist[0]
	for(var/obj/machinery/power/breakerbox/BR in SSpower.rcon_breaker_units)
		breakerlist.Add(list(list(
		"RCON_tag" = BR.RCon_tag,
		"enabled" = BR.on
		)))
	VUEUI_SET_CHECK(data["breakerlist"], breakerlist, ., data)


/datum/computer_file/program/rcon_vue/vueui_transfer(oldobj)
	var/ui_name = "mcomputer-rcon-vue"
	SSvueui.transfer_uis(oldobj, src, ui_name, 570, 520, filedesc)
	return TRUE

/datum/computer_file/program/rcon_vue/Topic(href, href_list)
	if(..())
		return

	if(href_list["smes_in_toggle"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_toggle"])
		if(SMES)
			SMES.toggle_input()
	if(href_list["smes_out_toggle"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_toggle"])
		if(SMES)
			SMES.toggle_output()

	if(href_list["smes_in_double_minus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_double_minus"])
		if(SMES)
			SMES.set_input(SMES.input_level-100000)
	if(href_list["smes_in_minus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_minus"])
		if(SMES)
			SMES.set_input(SMES.input_level-10000)
	if(href_list["smes_in_set"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_set"])
		if(SMES)
			var/inputset = input(usr, "Enter new input level in kW (0-[SMES.input_level_max/1000])", "SMES Input Power Control", SMES.input_level/1000) as num
			SMES.set_input(inputset*1000)
	if(href_list["smes_in_plus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_plus"])
		if(SMES)
			SMES.set_input(SMES.input_level+10000)
	if(href_list["smes_in_double_plus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_in_double_plus"])
		if(SMES)
			SMES.set_input(SMES.input_level+100000)

	if(href_list["smes_out_double_minus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_double_minus"])
		if(SMES)
			SMES.set_output(SMES.output_level-100000)
	if(href_list["smes_out_minus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_minus"])
		if(SMES)
			SMES.set_output(SMES.output_level-10000)
	if(href_list["smes_out_set"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_set"])
		if(SMES)
			var/outputset = input(usr, "Enter new output level in kW (0-[SMES.output_level_max/1000])", "SMES Input Power Control", SMES.output_level/1000) as num
			SMES.set_output(outputset*1000)
	if(href_list["smes_out_plus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_plus"])
		if(SMES)
			SMES.set_output(SMES.output_level+10000)
	if(href_list["smes_out_double_plus"])
		var/obj/machinery/power/smes/buildable/SMES = GetSMESByTag(href_list["smes_out_double_plus"])
		if(SMES)
			SMES.set_output(SMES.output_level+100000)


	if(href_list["toggle_breaker"])
		var/obj/machinery/power/breakerbox/toggle = SSpower.rcon_breaker_units_by_tag[href_list["toggle_breaker"]]
		if(toggle)
			if(toggle.update_locked)
				to_chat(usr, "The breaker box was recently toggled. Please wait before toggling it again.")
			else
				toggle.auto_toggle()
	SSvueui.check_uis_for_change(src)

// Proc: GetSMESByTag()
// Parameters: 1 (tag - RCON tag of SMES we want to look up)
// Description: Looks up and returns SMES which has matching RCON tag
/datum/computer_file/program/rcon_vue/proc/GetSMESByTag(var/tag)
	if(!tag)
		return

	return SSpower.rcon_smes_units_by_tag[tag]

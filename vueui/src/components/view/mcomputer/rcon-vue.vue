<template>
	<div>
		<vui-input-search threshold="0.4" :input="state.smeslist" v-model="filteredSMES" :keys="['RCON_tag']"></vui-input-search>
		<h1>SMES Units</h1>
		<vui-group>
		<div v-for="smes in filteredSMES" :key="smes.uuid">
			<vui-fw-group-item width="180px" :label="smes.RCON_tag">
				<vui-progress min="0" :class="capacityLoadClass(smes.charge, smes.capacity)" :value="smes.charge" :max="smes.capacity">{{smes.charge}} / {{smes.capacity}} kWh - {{smes.charge_percentage}}%</vui-progress>
				<span class="iolabel">Input:</span>
				<vui-button :class="ioButtonColorClass(smes.input_set)" :params="{smes_in_toggle: smes.RCON_tag}">{{smes.input_set==1?'Auto':'Off'}}</vui-button>
				<span class=setButtonArea>
					<vui-button class="minmaxbutton" :params="{smes_in_double_minus: smes.RCON_tag}">--</vui-button>
					<vui-button class="adjustbutton" :params="{smes_in_minus: smes.RCON_tag}">-</vui-button>
					<vui-button class="setbutton" :params="{smes_in_set: smes.RCON_tag}">{{smes.input_val}} kW</vui-button>
					<vui-button class="adjustbutton" :params="{smes_in_plus: smes.RCON_tag}">+</vui-button>
					<vui-button class="minmaxbutton" :params="{smes_in_double_plus: smes.RCON_tag}">++</vui-button>
				</span><br>
				<span class="iolabel">Output:</span>
				<vui-button :class="ioButtonColorClass(smes.output_set)" :params="{smes_out_toggle: smes.RCON_tag}">{{smes.output_set==1?'On':'Off'}}</vui-button>
				<span class=setButtonArea>
					<vui-button class="minmaxbutton" :params="{smes_out_double_minus: smes.RCON_tag}">--</vui-button>
					<vui-button class="adjustbutton" :params="{smes_out_minus: smes.RCON_tag}">-</vui-button>
					<vui-button class="setbutton" :params="{smes_out_set: smes.RCON_tag}">{{smes.output_val}} kW</vui-button>
					<vui-button class="adjustbutton" :params="{smes_out_plus: smes.RCON_tag}">+</vui-button>
					<vui-button class="minmaxbutton" :params="{smes_out_double_plus: smes.RCON_tag}">++</vui-button>
				</span><br>
				Output Load: {{smes.output_load}} kW
			</vui-fw-group-item>
			<span style="padding: 0; display: inline-block; line-height: 0; height: 4px; margin: 0;"></span>
		</div>
		</vui-group>
		<h1>Breakers</h1>
		<vui-group>
			<div v-for="breaker in state.breakerlist">
				<vui-fw-group-item class="lessItemPadding" width="165px" :label="breaker.RCON_tag">
					<vui-button :params="{toggle_breaker: breaker.RCON_tag}" :class="breakerColorClass(breaker.enabled)">{{breaker.enabled?"Enabled":"Disabled"}}</vui-button>
				</vui-fw-group-item>
			</div>
		</vui-group>
	</div>
</template>

<script>
export default {
	data() {
		return {
			state: this.$root.$data.state,
			filteredSMES: []
		}
	},
	methods: {
		capacityLoadClass(charge, capacity) {
			if (charge*4<capacity) {
				return "bad";
			} else if (charge<(capacity*0.98)) {
				return "average";
			} else if (charge>=(capacity*0.98)) {
				return "good";
			} else {
				return "#40618A";
			}
		},
		ioButtonColorClass(status) {
			return status ? "iobutton ioGreen" : "iobutton ioRed";
		},
		breakerColorClass(status) {
			return status ? "breakerButton ioGreen" : "breakerButton ioRed";
		},

	}
};
</script>

<style lang="scss" scoped>
.lessItemPadding /deep/ .itemLabel {
	padding-right: 1px;
}
.displayBar {
	width: 317px;
	height: 20px;
}
.iolabel {
	display: inline-block;
	width: 55px;
}
.iobutton {
	margin-top: 1px;
	width: 32px;
	margin-right: 15px;
}
.adjustbutton{
	width: 10px;
}
.setbutton {
	width: 80px;
}
.minmaxbutton {
	width: 20px;
}
.setButtonArea {
	margin-top: 1px;
	display: inline-block;
	text-align: right;
}
.outputLoadLabel {
	margin-bottom: 10px;
}
.ioRed {
	background: #ff0000;
	&:hover {
		background-color: #ff6666;
	}
}
.ioGreen {
	background: #2f943c;
	&:hover {
		background: #5fc96d;
	}
}
.breakerButton {
	margin-top: 4px;
	width: 70px;
	border-color: black;
	font-weight: bold;
}
</style>
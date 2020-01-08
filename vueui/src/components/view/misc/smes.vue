<template>
  <div>
	<div class="notice" v-if="failure_timer">
		<b><h3 class="whiteText">SYSTEM FAILURE</h3></b>
		I/O regulators malfunction detected! Waiting for system reboot... 
		<br>
		Automatic reboot in {{failure_timer}} seconds...<br>
		<vui-button icon="trash" class="whiteText" :params="{ reboot: 'reboot' }">Reboot Now</vui-button>
		<br> 
	</div>
	<div v-else>
		<!-- CHARGE STATUS -->
		<vui-group>
			<vui-fw-group-item label="Stored Capacity:">
				<vui-progress :class="capacityLoadClass" :value="percentage_stored">{{capacity_stored}} / {{capacity}} kWh - {{percentage_stored}}% </vui-progress>
			</vui-fw-group-item>
			<vui-fw-group-item label="Charge Status:">
				<span>{{chargeTypeString}}</span>
			</vui-fw-group-item>
		</vui-group>

		<!-- INPUT MANAGEMENT -->
		<h3>Input Management</h3>
		<vui-group>
			<vui-fw-group-item label="Charge Mode:">
				<vui-button :params="{ c_attempt: 'auto' }" :class="input_attempt ? 'selected' : '' " :disabled="input_attempt==1">Auto</vui-button>
				<vui-button :params="{ c_attempt: 'off' }" :class="input_attempt ? '' : 'selected' " :disabled="input_attempt==0">Off</vui-button>
				[<span class="bad" v-if="chargeQualityValue==0">Not charging</span>
				<span class="good" v-else-if="chargeQualityValue==2">Charging</span>
				<span class="average" v-else>Partially charging</span>]
			</vui-fw-group-item>
			<vui-fw-group-item label="Input Level:">
				<vui-progress :min=0 :value="input_level" :max="input_level_max"><span>{{input_level}} / {{input_level_max}} kW</span></vui-progress>
			</vui-fw-group-item>
		</vui-group>
		<vui-group>
			<vui-fw-group-item>
				<vui-button class="setButton" :disabled="input_level==0" :params="{ input: 'min' }">MIN</vui-button>
				<vui-button class="setButton" :disabled="input_level==0" :params="{ input: '-100' }">-100</vui-button>
				<vui-button class="setButton" :disabled="input_level==0" :params="{ input: '-10' }">-10</vui-button>
				<vui-button class="setButton" :params="{ input: 'set' }">SET</vui-button>
				<vui-button class="setButton" :disabled="input_level==input_level_max" :params="{ input: '+10' }">+10</vui-button>
				<vui-button class="setButton" :disabled="input_level==input_level_max" :params="{ input: '+100' }">+100</vui-button>
				<vui-button class="setButton" :disabled="input_level==input_level_max" :params="{ input: 'max' }">MAX</vui-button>
			</vui-fw-group-item>
			<vui-fw-group-item label="Input Load:">
				<vui-progress :class="inputLoadClass" :min=0 :value="input_taken" :max="input_level_max"><span>{{input_taken}} kW</span></vui-progress>
			</vui-fw-group-item>
		</vui-group>

		<!-- OUTPUT MANAGEMENT -->
		<h3>Output Management</h3>
		<vui-group>
			<vui-fw-group-item label="Output Mode:">
				<vui-button :params="{ o_attempt: 'on' }" v-bind:class="output_attempt ? 'selected' : '' " v-bind:disabled="output_attempt==1">On</vui-button>
				<vui-button :params="{ o_attempt: 'off' }" v-bind:class="output_attempt ? '' : 'selected' " v-bind:disabled="output_attempt==0">Off</vui-button>
				[<span v-if="is_outputting==2" class="good">Outputting</span>
				<span v-else-if="is_outputting==1" class="average">Disconnected or No Charge</span>
				<span v-else class="bad">Not outputting</span>]
			</vui-fw-group-item>
			<vui-fw-group-item label="Output Level:">
				<vui-progress :min=0 :value="output_level" :max="output_level_max"><span>{{output_level}} / {{output_level_max}} kW</span></vui-progress>
			</vui-fw-group-item>
		</vui-group>
		<vui-group>
			<vui-fw-group-item>
				<vui-button class="setButton" v-bind:disabled="output_level==0" :params="{ output: 'min' }">MIN</vui-button>
				<vui-button class="setButton" v-bind:disabled="output_level==0" :params="{ output: '-100' }">-100</vui-button>
				<vui-button class="setButton" v-bind:disabled="output_level==0" :params="{ output: '-10' }">-10</vui-button>
				<vui-button class="setButton" :params="{ output: 'set' }">SET</vui-button>
				<vui-button class="setButton" v-bind:disabled="output_level==output_level_max" :params="{ output: '+10' }">+10</vui-button>
				<vui-button class="setButton" v-bind:disabled="output_level==output_level_max" :params="{ output: '+100' }">+100</vui-button>
				<vui-button class="setButton" v-bind:disabled="output_level==output_level_max" :params="{ output: 'max' }">MAX</vui-button>
			</vui-fw-group-item>
			<vui-fw-group-item label="Output Load:">
				<vui-progress :class="outputLoadClass" :min=0 :value="output_used" :max="output_level_max"><span>{{output_used}} kW</span></vui-progress>
			</vui-fw-group-item>
		</vui-group>
	</div>
  </div>
</template>

<script>
export default {
  data() {
    return this.$root.$data.state; // Make data more easily accessible
  },
  computed: {
		chargeTypeString() {
			switch (this.$root.$data.state.charge_load_ratio) {
				case 0:
					return "SMES will run out of charge in " + this.$root.$data.state.time
					break;
				case 1: 
					return "SMES will be fully charged in " + this.$root.$data.state.time
					break;
				case 2:
					return "SMES input and output are equal"
					break;
				default:
					return "Charge status error!"
					break;
			}
		},
		chargeQualityValue() {
			let inc = this.$root.$data.state.input_taken
			let setting = this.$root.$data.state.input_level
			if (inc==0 || setting==0) return 0;
			if (inc>=setting) return 2;
			if (inc>0) return 1;
			return 0;
		},
		capacityLoadClass() {
			let stored = this.$root.$data.state.capacity_stored;
			let cap = this.$root.$data.state.capacity
			if (stored*4<cap) return "bad";
			if (stored<cap*0.98) return "average";
			return "good";
		},
		inputLoadClass() {
			let inc = this.$root.$data.state.input_taken
			let setting = this.$root.$data.state.input_level
			if (inc<setting*0.25) return "bad";
			if (inc<setting*0.8) return "average";
			return "good";
		},		
		outputLoadClass() {
			let used = this.$root.$data.state.output_used;
			let setting = this.$root.$data.state.output_level; 
			if (used<setting*0.8) return "good";
			return "average";
		}
	},
  }; 
</script>

<style lang="scss" scoped>
.setButton {
  display: inline-block;
  width: 31px;
}
.displayBar {
	width: 297px;
}
.whiteText {
	color: white;
}
.button {
	&.on, &.selected {
		background: #5e9653;
		border: 1px solid #161616;
		&:hover {
			background: #5e9653;
		}
	}
}
</style>
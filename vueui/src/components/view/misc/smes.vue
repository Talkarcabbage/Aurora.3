<template>
  <div>
    <div class="notice" v-if="state.failure_timer">
      <b><h3 class="whiteText">SYSTEM FAILURE</h3></b>
      I/O regulators malfunction detected! Waiting for system reboot... 
      <br>
      Automatic reboot in {{state.failure_timer}} seconds...<br>
      <vui-button icon="trash" class="whiteText" :params="{ reboot: 'reboot' }">Reboot Now</vui-button>
      <br> 
    </div>
    <div v-else>
      <!-- CHARGE STATUS -->
      <vui-group>
        <vui-fw-group-item label="Stored Capacity:">
          <vui-progress :class="capacityLoadClass" :value="state.percentage_stored">{{state.capacity_stored}} / {{state.capacity}} kWh - {{state.percentage_stored}}% </vui-progress>
        </vui-fw-group-item>
        <vui-fw-group-item label="Charge Status:">
          <span>{{state.chargeTypeString}}</span>
        </vui-fw-group-item>
      </vui-group>

      <!-- INPUT MANAGEMENT -->
      <h3>Input Management</h3>
      <vui-group>
        <vui-fw-group-item label="Charge Mode:">
          <vui-button :params="{ c_attempt: 'auto' }" :class="state.input_attempt ? 'selected' : '' " :disabled="state.input_attempt==1">Auto</vui-button>
          <vui-button :params="{ c_attempt: 'off' }" :class="state.input_attempt ? '' : 'selected' " :disabled="state.input_attempt==0">Off</vui-button>
          [<span class="bad" v-if="state.chargeQualityValue==0">Not charging</span>
          <span class="good" v-else-if="state.chargeQualityValue==2">Charging</span>
          <span class="average" v-else>Partially charging</span>]
        </vui-fw-group-item>
        <vui-fw-group-item label="Input Level:">
          <vui-progress :min="0" :value="state.input_level" :max="state.input_level_max"><span>{{state.input_level}} / {{state.input_level_max}} kW</span></vui-progress>
        </vui-fw-group-item>
      </vui-group>
      <vui-group>
        <vui-fw-group-item v-if="false">
          <vui-button class="setButton" :disabled="state.input_level==0" :params="{ input: 'min' }">MIN</vui-button>
          <vui-button class="setButton" :disabled="state.input_level==0" :params="{ input: '-100' }">-100</vui-button>
          <vui-button class="setButton" :disabled="state.input_level==0" :params="{ input: '-10' }">-10</vui-button>
          <vui-button class="setButton" :params="{ input: 'set' }">SET</vui-button>
          <vui-button class="setButton" :disabled="state.input_level==state.input_level_max" :params="{ input: '+10' }">+10</vui-button>
          <vui-button class="setButton" :disabled="state.input_level==state.input_level_max" :params="{ input: '+100' }">+100</vui-button>
          <vui-button class="setButton" :disabled="state.input_level==state.input_level_max" :params="{ input: 'max' }">MAX</vui-button>
        </vui-fw-group-item>
        <vui-fw-group-item>
          <vui-input-numeric-client :show-min-max="true" width="5em" :min="0" :max="state.input_level_max" v-model="valueToSet" v-on:enter-pressed="onSubmit( { set_input: {value: valueToSet} })" />
          <vui-button :params="{set_input: {value: valueToSet} }" style="margin-left: 0.9em">Apply</vui-button>
        </vui-fw-group-item>
        <vui-fw-group-item label="Input Load:">
          <vui-progress :class="inputLoadClass" :min="Number(0)" :value="state.input_taken" :max="state.input_level_max"><span>{{state.input_taken}} kW</span></vui-progress>
        </vui-fw-group-item>
      </vui-group>

      <!-- OUTPUT MANAGEMENT -->
      <h3>Output Management</h3>
      <vui-group>
        <vui-fw-group-item label="Output Mode:">
          <vui-button :params="{ o_attempt: 'on' }" v-bind:class="state.output_attempt ? 'selected' : '' " v-bind:disabled="state.output_attempt==1">On</vui-button>
          <vui-button :params="{ o_attempt: 'off' }" v-bind:class="state.output_attempt ? '' : 'selected' " v-bind:disabled="state.output_attempt==0">Off</vui-button>
          [<span v-if="state.is_outputting==2" class="good">Outputting</span>
          <span v-else-if="state.is_outputting==1" class="average">Disconnected or No Charge</span>
          <span v-else class="bad">Not outputting</span>]
        </vui-fw-group-item>
        <vui-fw-group-item label="Output Level:">
          <vui-progress :min="0" :value="state.output_level" :max="state.output_level_max"><span>{{state.output_level}} / {{state.output_level_max}} kW</span></vui-progress>
        </vui-fw-group-item>
      </vui-group>
      <vui-group>
        <vui-fw-group-item>
          <vui-button class="setButton" v-bind:disabled="state.output_level==0" :params="{ output: 'min' }">MIN</vui-button>
          <vui-button class="setButton" v-bind:disabled="state.output_level==0" :params="{ output: '-100' }">-100</vui-button>
          <vui-button class="setButton" v-bind:disabled="state.output_level==0" :params="{ output: '-10' }">-10</vui-button>
          <vui-button class="setButton" :params="{ output: 'set' }">SET</vui-button>
          <vui-button class="setButton" v-bind:disabled="state.output_level==state.output_level_max" :params="{ output: '+10' }">+10</vui-button>
          <vui-button class="setButton" v-bind:disabled="state.output_level==state.output_level_max" :params="{ output: '+100' }">+100</vui-button>
          <vui-button class="setButton" v-bind:disabled="state.output_level==state.output_level_max" :params="{ output: 'max' }">MAX</vui-button>
        </vui-fw-group-item>
        <vui-fw-group-item label="Output Load:">
          <vui-progress :class="outputLoadClass" :min="0" :value="state.output_used" :max="state.output_level_max"><span>{{state.output_used}} kW</span></vui-progress>
        </vui-fw-group-item>
      </vui-group>
    </div>
  </div>
</template>

<script>
import Utils from '../../../utils.js'
export default {
  data() {
    return {
      state: this.$root.$data.state,
      valueToSet: this.$root.$data.state.input_level
    }// Make data more easily accessible
  },
  computed: {
		chargeTypeString() {
			switch (this.$root.$data.state.charge_load_ratio) {
				case 0:
					return "SMES will run out of charge in " + this.$root.$data.state.time
				case 1: 
					return "SMES will be fully charged in " + this.$root.$data.state.time
				case 2:
					return "SMES input and output are equal"
				default:
					return "Charge status error!"
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
  methods: {
    onSubmit(params) {
      Utils.sendToTopic(params)
    }
  }
 }; 
</script>

<style lang="scss" scoped>
.setButton {
  display: inline-block;
  width: 2.6em;
}
.displayBar {
	width: 24.8em;
}
.whiteText {
	color: white;
}
.button {
	&.on, &.selected {
		background: #5e9653;
		border: 0.083em solid #161616;
		&:hover {
			background: #5e9653;
		}
	}
}
</style>
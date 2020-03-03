<template>
  <span>
    <vui-button v-if="showMinMax" :disabled="val<=min" @click="onMinMaxButton(min)">Min</vui-button>
    <vui-button v-for="bv in subButtons" :key="'-' + bv" :disabled="val<=min" @click="onAdjustButton(bv)">-</vui-button>
    <input ref="input" :style="{width: width}" v-model="fieldValue" @input="onValueUpdate" @keyup.enter="onEnterPressed">
    <vui-button v-for="bv in addButtons" :key="'+' + bv" :disabled="val>=max" @click="onAdjustButton(bv)">+</vui-button>
    <vui-button v-if="showMinMax" :disabled="val>=max" @click="onMinMaxButton(max)">Max</vui-button>
  </span>
</template>

<script>
export default {
    data() {
        return {
            val: this.value
        }
    },
    props: {
        value: {
            type: Number,
            default: 0
        },
        showMinMax: { // Whether to show a Min and Max button alongside the +/- buttons
            type: Boolean,
            default: false
        },
        min: {
            type: Number,
            default: 0
        },
        max: {
            type: Number,
            default: 100
        },
        buttonCount: {
            type: Number,
            default: 2
        },
        width: {
            type: String,
            default: "10em"
        }
    },
    computed: {
        fieldValue: {
            get(){
                return this.val
            },
            set(newVal) {
                newVal = Number(newVal)
                if (!isNaN(newVal)) {
                    this.val = this.checkBounds(newVal)
                } 
            }
        },
        subButtons() {
            if(!this.buttonCount) return [];
            let buttons = []
            for (let i = this.buttonCount - 1; i >= 0; i--) {
                buttons.push(-1*(10 ** i))
            }
            return buttons
        },
        addButtons() {
            if(!this.buttonCount) return [];
            let buttons = []
            for (let i = 0; i < this.buttonCount; i++) {
                buttons.push(10 ** i)
            }
            return buttons
        }
    },
    methods: {
        checkBounds(attemptedValue) {
            if (isNaN(attemptedValue)) attemptedValue = this.val
            if (attemptedValue<this.min) return this.min
            if (attemptedValue>this.max) return this.max
            return attemptedValue
        },
        onAdjustButton(increment) {
            let incNum = Number(increment)
            if (isNaN(incNum)) {
                incNum = 0
            }
            this.val = this.checkBounds(this.value + incNum)
            this.$emit('input', this.val)
        },
        onMinMaxButton(value) {
            let incNum = Number(value)
            if (isNaN(incNum)) {
                incNum = this.val
            }
            this.val = this.checkBounds(incNum)
            this.$emit('input', this.val)
        },
        onValueUpdate() {
            if (!(this.$refs.input.value=="" || this.$refs.input.value=="-" || this.$refs.input.value.endsWith("."))) {
                this.$refs.input.value = this.val
            }
            this.$emit('input', this.val)
        },
        onEnterPressed() { //When enter is pressed in the typing area
            this.onValueUpdate()
            this.$emit('enter-pressed', this.val)
        }
    },
    watch: {
        value() {

            this.val = this.value
        }
    }
};
</script>

<style lang="scss" scoped>

</style>
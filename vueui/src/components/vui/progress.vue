<template>
  <div class="displayBar">
    <div class="displayBarFill" :style="{ width: percentage + '%'}"/>
    <span class="contentSpan"><slot/></span>
  </div>
</template>

<script>
export default {
  props: {
    value: {
      type: Number,
      default: 50
    },
    max: {
      type: Number,
      default: 100
    },
    min: {
      type: Number,
      default: 0
    }
  },
  computed: {
    percentage() {
      return (Math.min(this.max, Math.max(this.value, this.min)) - this.min) / (this.max - this.min) * 100;
    }
  }
}
</script>

<style lang="scss" scoped>
  .displayBarFill {
    line-height: 1em;
    white-space: nowrap;
    overflow: visible;
    position: absolute;
    height: 100%;
    top: 0;
    left: 0;
    float: left;
  }
  .contentSpan {
    margin-top: auto;
    margin-bottom: auto;
    position: relative;
    line-height: 1em;
    width: 100%;
    font-weight: normal;
  }
  .displayBar {
    height: 1.5em;
    position: relative;
    display: flex;
    overflow: hidden;
    text-align: center;
    justify-content: center;
    align-items: center;
  }
</style>

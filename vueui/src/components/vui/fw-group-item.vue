<!-- This is a similar alternative to vui-group-item that allows 
specifying a fixed width for all entries in the table to use. 
Only the first group item in a group needs to specify a width. 
This was kept separate to preserve the default behavior for other
programs that use group-item.-->
<template>
  <div class="item">
    <div class="itemLabel" v-bind:style="style">{{ label }}</div>
    <div class="itemContent"><slot/></div>
  </div>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: ""
    },
    width: {
      type: String,
      default: "150px"
    }
  },
  computed: {
    style() {
      return "width: " + this.width + "; max-width: " + this.width;
    }
  }
}
</script>

<style lang="scss" scoped>
div.item {
  display: table-row;
}

.itemLabel, .itemContent {
  display: table-cell;
  table-layout: fixed;
  vertical-align: top;
}

.itemLabel {
  padding-right: 8px;
}
</style>

<script setup lang="ts">
import { useTemplateRef } from "vue";

import Hero from "./components/Hero.vue";

const hero1 = useTemplateRef("hero1");
const hero2 = useTemplateRef("hero2");

function nextTurn() {
	hero1.value?.applyTurn();
	hero2.value?.applyTurn();
}
</script>

<template>
	<div class="app">
		<Hero ref="hero1" />
		<Hero ref="hero2" />
		<div>
			<button @click="nextTurn">{{ $t("action.nextTurn") }}</button>
		</div>
	</div>
</template>

<style scoped>
.app {
	display: grid;
	grid-template-columns: 1fr 1fr 1fr;
	gap: 1rem;
}
</style>

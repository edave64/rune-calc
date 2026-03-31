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
		<Hero class="hero" ref="hero1" :title="$t('heroes.hero1')" />
		<Hero class="hero" ref="hero2" :title="$t('heroes.hero2')" />
		<div id="controls">
			<button @click="nextTurn">{{ $t("action.nextTurn") }}</button>
		</div>
	</div>
</template>

<style scoped>
.app {
	display: flex;
	flex-direction: row;
	gap: 2rem;
}

.app > * {
	width: calc((100vw - 128px) / 2);
	max-width: 360px;
}

@media (max-width: 1008px) {
	.app {
		flex-direction: column;
	}
	.app > * {
		width: calc(100vw - 64px);
	}
}

#controls {
	width: 128px;
}
</style>

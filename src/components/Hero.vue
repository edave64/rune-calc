<script setup lang="ts">
import { computed, reactive, useTemplateRef } from "vue";

const otherDialog = useTemplateRef<HTMLDialogElement>("otherDialog");
const damageDialog = useTemplateRef<HTMLDialogElement>("damageDialog");

function openDamageMenu() {
	damageDialog.value?.showModal();
}

function openOther() {
	otherDialog.value?.showModal();
}

const totalHealthDelta = computed(() => {
	return markers.life - markers.damage;
});

const totalAttackDelta = computed(() => {
	if (markers.confusion > 0) {
		return "N/A";
	}
	return markers.strength + markers.blessing - markers.curse + markers.rush;
});

function reset() {
	for (const marker of markerNames) {
		markers[marker] = 0;
	}
}

const markerNames = [
	"damage",
	"life",
	"strength",
	"counter",
	"sleep",
	"poison",
	"healing",
	"blessing",
	"curse",
	"protection",
	"bleeding",
	"decay",
	"rush",
	"confusion",
] as const;

type Markers = (typeof markerNames)[number];

const markers = reactive(emptyMarkers());

function addMarker(marker: Markers, value: number) {
	damageDialog.value?.close();
	otherDialog.value?.close();
	switch (marker) {
		case "damage":
			markers.sleep = 0;
			if (value < 0 && markers.rush > 0) {
				return;
			}
			break;
		case "rush":
			markers.sleep = 0;
			break;
		case "curse":
			if (markers.blessing > 0) return;
			break;
		case "blessing":
			if (markers.curse > 0) return;
			break;
		case "poison":
			if (markers.healing > 0) {
				const remaining = value - markers.healing;
				markers.healing = Math.max(0, markers.healing - value);
				if (remaining <= 0) return;
				value = remaining;
			}
			break;
		case "healing":
			if (markers.poison > 0) {
				const remaining = value - markers.poison;
				markers.poison = Math.max(0, markers.poison - value);
				if (remaining <= 0) return;
				value = remaining;
			}
			break;
		case "bleeding":
			if (markers.protection > 0) {
				// 10 points of protection prevent 20 bleeding damage
				const remaining = value - markers.protection * 2;
				markers.protection = Math.max(0, markers.protection - value / 2);
				if (remaining <= 0) return;
				value = remaining;
			}
			break;
		case "sleep":
			if (markers.rush > 0) return;
			break;
	}
	markers[marker] = Math.max(0, markers[marker] + value);
}

function canAddMarker(marker: Markers) {
	switch (marker) {
		case "sleep":
			return markers.rush === 0;
		case "poison":
			return markers.poison < 20;
		case "healing":
			return markers.healing < 20;
		case "blessing":
			return markers.curse === 0 && markers.blessing < 20;
		case "curse":
			return markers.blessing === 0;
		default:
			return true;
	}
}

function emptyMarkers(): Record<Markers, number> {
	const ret = {} as Record<Markers, number>;
	for (const marker of markerNames) {
		ret[marker] = 0;
	}
	return ret;
}

const autoReducingMarkers = ["counter", "sleep", "confusion"] as const;

function applyTurn() {
	for (const marker of autoReducingMarkers) {
		if (markers[marker] > 0) {
			markers[marker]--;
		}
	}

	if (markers.bleeding) {
		addMarker("damage", markers.bleeding);
	}
	if (markers.decay) {
		addMarker("damage", markers.decay);
	}
}

defineExpose({
	addMarker,
	canAddMarker,
	applyTurn,
});
</script>

<template>
	<div class="hero">
		<ul>
			<li>
				{{ $t("strings.totalHealthChange") }}: {{ totalHealthDelta }}
				<ul>
					<li v-if="markers.life">{{ $t("markers.lifeMarkers") }} {{ markers.life }}</li>
					<li v-if="markers.damage">{{ $t("markers.damageMarkers") }} {{ markers.damage }}</li>
				</ul>
			</li>
			<li>
				{{ $t("strings.totalAttackChange") }}: {{ totalAttackDelta }}
				<ul>
					<li v-if="markers.confusion">
						{{ $t("markers.confusionMarkers") }} {{ markers.confusion }}
					</li>
					<li v-if="markers.strength">
						{{ $t("markers.strengthMarkers") }} {{ markers.strength }}
					</li>
					<li v-if="markers.blessing">
						{{ $t("markers.blessingMarkers") }} {{ markers.blessing }}
					</li>
					<li v-if="markers.curse">{{ $t("markers.curseMarkers") }} {{ markers.curse }}</li>
					<li v-if="markers.rush">{{ $t("markers.rushMarkers") }} {{ markers.rush }}</li>
				</ul>
			</li>
			<li v-if="markers.counter">{{ $t("markers.counterMarkers") }}: {{ markers.counter }}</li>
			<li v-if="markers.sleep">{{ $t("markers.sleepMarkers") }}: {{ markers.sleep }}</li>
			<li v-if="markers.poison">{{ $t("markers.poisonMarkers") }}: {{ markers.poison }}</li>
			<li v-if="markers.healing">{{ $t("markers.healingMarkers") }}: {{ markers.healing }}</li>
			<li v-if="markers.protection">
				{{ $t("markers.protectionMarkers") }}: {{ markers.protection }}
			</li>
			<li v-if="markers.bleeding">{{ $t("markers.bleedingMarkers") }}: {{ markers.bleeding }}</li>
			<li v-if="markers.decay">{{ $t("markers.decayMarkers") }}: {{ markers.decay }}</li>
		</ul>
		<p>
			<button @click="openDamageMenu">{{ $t("action.addDamage") }}</button>
			<button @click="openOther">{{ $t("action.addMarker") }}</button>
			<!-- TODO: Make it so the user has to push the button longer to prevent accidental clicks -->
			<button @click="reset">{{ $t("action.reset") }}</button>
		</p>
	</div>
	<dialog closedby="any" ref="damageDialog">
		<h2>{{ $t("markers.damageMarkers") }}</h2>
		<div class="btn-group">
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('damage', val)">
				+{{ val }}
			</button>
		</div>

		<template v-if="markers.damage && !markers.rush">
			<h2>{{ $t("strings.healDamage") }}</h2>
			<div class="btn-group">
				<template v-for="val in [10, 20, 30, 40, 50]">
					<button @click="addMarker('damage', -val)" v-if="markers.damage >= val">
						-{{ val }}
					</button>
				</template>
			</div>
		</template>
		<button @click="damageDialog?.close()">Close</button>
	</dialog>
	<dialog closedby="any" ref="otherDialog">
		<button @click="addMarker('poison', 10)" v-if="canAddMarker('poison')">
			+10 {{ $t("markers.poisonMarkers") }}
		</button>
		<button @click="addMarker('healing', 10)" v-if="canAddMarker('healing')">
			+10 {{ $t("markers.healingMarkers") }}
		</button>
		<button @click="addMarker('rush', 20)" v-if="canAddMarker('rush')">
			+20 {{ $t("markers.rushMarkers") }}
		</button>
		<button @click="addMarker('decay', 10)" v-if="canAddMarker('decay')">
			+10 {{ $t("markers.decayMarkers") }}
		</button>
		<button @click="addMarker('protection', 10)" v-if="canAddMarker('protection')">
			+10 {{ $t("markers.protectionMarkers") }}
		</button>
		<button @click="addMarker('bleeding', 20)" v-if="canAddMarker('bleeding')">
			+20 {{ $t("markers.bleedingMarkers") }}
		</button>
		<button @click="addMarker('confusion', 1)" v-if="canAddMarker('confusion')">
			+1 {{ $t("markers.confusionMarkers") }}
		</button>
		<button @click="addMarker('blessing', 10)" v-if="canAddMarker('blessing')">
			+10 {{ $t("markers.blessingMarkers") }}
		</button>
		<button @click="addMarker('curse', 10)" v-if="canAddMarker('curse')">
			+10 {{ $t("markers.curseMarkers") }}
		</button>

		<h2>{{ $t("markers.lifeMarkers") }}</h2>
		<div class="btn-group">
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('life', val)">
				{{ val }}
			</button>
		</div>

		<h2>{{ $t("markers.strengthMarkers") }}</h2>
		<div class="btn-group">
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('strength', val)">
				{{ val }}
			</button>
		</div>

		<template v-if="canAddMarker('sleep')">
			<h2>{{ $t("markers.sleepMarkers") }}</h2>
			<div class="btn-group">
				<button v-for="val in [1, 2, 3, 4, 5]" @click="addMarker('sleep', val)">
					{{ val }}
				</button>
			</div>
		</template>

		<template v-if="canAddMarker('counter')">
			<h2>{{ $t("markers.counterMarkers") }}</h2>
			<div class="btn-group">
				<button v-for="val in [1, 2, 3, 4, 5]" @click="addMarker('counter', val)">
					{{ val }}
				</button>
			</div>
		</template>

		<button @click="otherDialog?.close()">{{ $t("action.close") }}</button>
	</dialog>
</template>

<style scoped>
.hero {
	text-align: left;
}

button {
	display: block;
}

.btn-group {
	display: flex;
	flex-direction: row;

	& button {
		flex-grow: 1;
		flex-shrink: 1;
		border-radius: 0;

		&:first-child {
			border-top-left-radius: 8px;
			border-bottom-left-radius: 8px;
		}
		&:last-child {
			border-top-right-radius: 8px;
			border-bottom-right-radius: 8px;
		}
	}
}
</style>

<style>
dialog::backdrop {
	background-color: rgba(0, 0, 0, 0.5);
}

dialog {
	max-height: 90vh;
}
</style>

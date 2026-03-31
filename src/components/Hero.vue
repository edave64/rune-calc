<script setup lang="ts">
import { computed, reactive, useTemplateRef } from "vue";
import { useI18n } from "vue-i18n";

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

const markerImages: Record<Markers, { base: string; denominations: number[] }> = {
	damage: {
		base: "dmg",
		denominations: [10, 20, 30, 40, 50],
	},
	life: {
		base: "lif",
		denominations: [10, 20, 30, 40, 50],
	},
	strength: {
		base: "atk",
		denominations: [10, 20, 30, 40, 50],
	},
	counter: {
		base: "cnt",
		denominations: [1, 2, 3, 4, 5],
	},
	sleep: {
		base: "slp",
		denominations: [1, 2, 3, 4, 5],
	},
	poison: {
		base: "psn",
		denominations: [10, 20],
	},
	healing: {
		base: "hea",
		denominations: [10, 20],
	},
	blessing: {
		base: "bls",
		denominations: [10, 20],
	},
	curse: {
		base: "crs",
		denominations: [10],
	},
	protection: {
		base: "shl",
		denominations: [10],
	},
	bleeding: {
		base: "bld",
		denominations: [20],
	},
	decay: {
		base: "dcy",
		denominations: [10],
	},
	rush: {
		base: "rsh",
		denominations: [20],
	},
	confusion: {
		base: "cfs",
		denominations: [1],
	}
};

const { t } = useI18n();

function renderMarkers(marker: Markers): string {
	const { base, denominations } = markerImages[marker];
	const max_denomination = Math.max(...denominations);

	const max_vals = Math.floor(markers[marker] / max_denomination);
	const remainder = markers[marker] % max_denomination;
	const tStr = t('markers.' + marker + "Markers");

	let ret = "";

	for (let i = 0; i < max_vals; i++) {
		addImage(max_denomination);
	}

	if (remainder === 0) return ret;

	addImage(remainder);

	return ret;

	function addImage(value: number) {
		ret += `<img class="marker" src="./markers/${base}${value}.svg" alt="${value} ${tStr}" title="${value} ${tStr}">`;
	}
}

function renderMarker(marker: Markers, value: number) {
	const { base } = markerImages[marker];
	const tStr = t('markers.' + marker + "Markers");

	return `<img class="marker" src="./markers/${base}${value}.svg" alt="${value} ${tStr}" title="${value} ${tStr}">`;
}

defineProps({
	title: {
		type: String,
		required: true,
	},
});

defineExpose({
	addMarker,
	canAddMarker,
	applyTurn,
});
</script>

<template>
	<div class="hero">
		<h2>{{ title }}</h2>
		<ul>
			<li>
				{{ $t("strings.totalHealthChange") }}: {{ totalHealthDelta }}
				<div class="marker-list" v-html="renderMarkers('damage') + renderMarkers('life')" />
			</li>
			<li>
				{{ $t("strings.totalAttackChange") }}: {{ totalAttackDelta }}
				<div class="marker-list"
					v-html="renderMarkers('confusion') + renderMarkers('strength') + renderMarkers('blessing') + renderMarkers('curse') + renderMarkers('rush')" />
			</li>
			<li
				v-if="markers.counter + markers.sleep + markers.poison + markers.healing + markers.protection + markers.bleeding + markers.decay">
				{{ $t("strings.otherMarkers") }}
				<div class="marker-list"
					v-html="renderMarkers('counter') + renderMarkers('sleep') + renderMarkers('poison') + renderMarkers('healing') + renderMarkers('protection') + renderMarkers('bleeding') + renderMarkers('decay')" />
			</li>
		</ul>
		<p>
			<button @click="openDamageMenu">{{ $t("action.addDamage") }}</button>
			<button @click="openOther">{{ $t("action.addMarker") }}</button>
			<!-- TODO: Make it so the user has to push the button longer to prevent accidental clicks -->
			<button @click="reset">{{ $t("action.reset") }}</button>
		</p>
	</div>
	<dialog closedby="any" ref="damageDialog">
		<div class="btn-group">
			<h2>{{ $t("markers.damageMarkers") }}</h2>
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('damage', val)"
				v-html="renderMarker('damage', val)"></button>
		</div>

		<template v-if="markers.damage && !markers.rush">
			<hr />
			<div class="btn-group">
				<h2>{{ $t("strings.healDamage") }}</h2>
				<template v-for="val in [10, 20, 30, 40, 50]">
					<button v-if="markers.damage >= val" @click="addMarker('damage', -val)"
						v-html="renderMarker('damage', val)"></button>
				</template>
			</div>
		</template>
		<button @click="damageDialog?.close()">Close</button>
	</dialog>
	<dialog closedby="any" ref="otherDialog">
		<div class="button-list">
		<button @click="addMarker('poison', 10)" v-if="canAddMarker('poison')">
			{{ $t("markers.poisonMarkers") }} <span v-html="renderMarker('poison', 10)"></span>
		</button>
		<button @click="addMarker('healing', 10)" v-if="canAddMarker('healing')">
			{{ $t("markers.healingMarkers") }} <span v-html="renderMarker('healing', 10)"></span>
		</button>
		<button @click="addMarker('rush', 20)" v-if="canAddMarker('rush')">
			{{ $t("markers.rushMarkers") }} <span v-html="renderMarker('rush', 20)"></span>
		</button>
		<button @click="addMarker('decay', 10)" v-if="canAddMarker('decay')">
			{{ $t("markers.decayMarkers") }} <span v-html="renderMarker('decay', 10)"></span>
		</button>
		<button @click="addMarker('protection', 10)" v-if="canAddMarker('protection')">
			{{ $t("markers.protectionMarkers") }} <span v-html="renderMarker('protection', 10)"></span>
		</button>
		<button @click="addMarker('bleeding', 20)" v-if="canAddMarker('bleeding')">
			{{ $t("markers.bleedingMarkers") }} <span v-html="renderMarker('bleeding', 20)"></span>
		</button>
		<button @click="addMarker('confusion', 1)" v-if="canAddMarker('confusion')">
			{{ $t("markers.confusionMarkers") }} <span v-html="renderMarker('confusion', 1)"></span>
		</button>
		<button @click="addMarker('blessing', 10)" v-if="canAddMarker('blessing')">
			{{ $t("markers.blessingMarkers") }} <span v-html="renderMarker('blessing', 10)"></span>
		</button>
		<button @click="addMarker('curse', 10)" v-if="canAddMarker('curse')">
			{{ $t("markers.curseMarkers") }} <span v-html="renderMarker('curse', 10)"></span>
		</button>
		</div>

		<div class="btn-group">
			<h2>{{ $t("markers.lifeMarkers") }}</h2>
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('life', val)" v-html="renderMarker('life', val)"></button>
		</div>

		<div class="btn-group">
		<h2>{{ $t("markers.strengthMarkers") }}</h2>
			<button v-for="val in [10, 20, 30, 40, 50]" @click="addMarker('strength', val)" v-html="renderMarker('strength', val)"></button>
		</div>

		<template v-if="canAddMarker('sleep')">
			<div class="btn-group">
				<h2>{{ $t("markers.sleepMarkers") }}</h2>
				<button v-for="val in [1, 2, 3, 4, 5]" @click="addMarker('sleep', val)"  v-html="renderMarker('sleep', val)"></button>
			</div>
		</template>

		<template v-if="canAddMarker('counter')">
			<div class="btn-group">
				<h2>{{ $t("markers.counterMarkers") }}</h2>
				<button v-for="val in [1, 2, 3, 4, 5]" @click="addMarker('counter', val)" v-html="renderMarker('counter', val)"></button>
			</div>
		</template>

		<button @click="otherDialog?.close()">{{ $t("action.close") }}</button>
	</dialog>
</template>

<style scoped>
.hero {
	box-sizing: border-box;
	text-align: left;
	padding: 16px;
	background: #1a1a1a;
	border-radius: 8px;
}

button {
	display: block;
}

.marker-list {
	display: flex;
	flex-direction: row;
	flex-wrap: wrap;
}

.button-list {
	display: flex;
	flex-direction: row;
	flex-wrap: wrap;

	::v-deep(.marker) {
		vertical-align: middle;
	}
}

::v-deep(.marker) {
	width: 1.5em;
}

.btn-group {
	display: flex;
	flex-direction: row;

	& h2 {
		margin: 0;
		flex-grow: 2;
		text-align: right;
	}

	& button {
		flex-grow: 0;
		flex-shrink: 0;
		border-radius: 0;
		padding: 4px;

		&:first-of-type {
			border-top-left-radius: 8px;
			border-bottom-left-radius: 8px;
		}

		&:last-of-type {
			border-top-right-radius: 8px;
			border-bottom-right-radius: 8px;
		}
	}
}

ul {
	list-style: none;
	padding: 0;
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

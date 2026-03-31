import { createI18n } from "vue-i18n";

import de from "./i18n/de.json";
import en from "./i18n/en.json";

const i18n = createI18n({
	legacy: false,
	locale: "en",
	fallbackLocale: "de",
	messages: {
		en,
		de,
	},
});

export default i18n;

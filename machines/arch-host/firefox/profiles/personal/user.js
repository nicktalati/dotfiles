// Enable userChrome.css and userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Dark mode: tell websites to use dark color scheme
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// Set Dark Space as active theme (installed via policies.json)
user_pref("extensions.activeThemeID", "{22b0eca1-8c02-4c0d-a5d7-6604ddd9836e}");

// Disable about:config warning page
user_pref("browser.aboutConfig.showWarning", false);

// Disable default browser check
user_pref("browser.shell.checkDefaultBrowser", false);

// Disable sponsored content on new tab page
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Disable built-in password/autofill management (use Bitwarden instead)
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// Disable form history suggestions
user_pref("browser.formfill.enable", false);

// New tab page: disable search bar
user_pref("browser.newtabpage.activity-stream.showSearch", false);

// Disable Pocket (also disabled via policies.json, belt and suspenders)
user_pref("extensions.pocket.enabled", false);

// Disable the new sidebar
user_pref("sidebar.revamp", false);

// Hide bookmarks toolbar
user_pref("browser.toolbars.bookmarks.visibility", "never");

// Homepage
user_pref("browser.startup.homepage", "https://www.reuters.com");

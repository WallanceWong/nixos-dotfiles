// whisper — let Firefox load chrome/userChrome.css and chrome/userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// speed: GPU video decoding (VA-API, intel-media-driver) and the GPU renderer
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("gfx.webrender.all", true);
// save the open-tabs session every minute instead of every 15 s (less disk churn)
user_pref("browser.sessionstore.interval", 60000);

// ── whisper look ──
// dark everywhere: the window, Firefox's own pages, sites that have a dark mode
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("devtools.theme", "dark");
user_pref("pdfjs.viewerCssTheme", 2);
// rounded popups (menus, panels) need transparent popup windows
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
// new tab: the painting, your shortcuts and the search box — no stories or ads
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.newtabWallpapers.enabled", false);
// smooth, weighted scrolling (like the shell's animations)
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.msdPhysics.enabled", true);
// no "proceed with caution" page in about:config
user_pref("browser.aboutConfig.showWarning", false);

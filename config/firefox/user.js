// whisper — let Firefox load chrome/userChrome.css and chrome/userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// speed: GPU video decoding (VA-API, intel-media-driver) and the GPU renderer
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("gfx.webrender.all", true);
// save the open-tabs session every minute instead of every 15 s (less disk churn)
user_pref("browser.sessionstore.interval", 60000);

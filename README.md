# R8Q VoLTE module (Lunaris) — build via GitHub Actions

Updated after reading the actual logcat (`another4.log`) attached to the
XDA thread — that log is from a **working** run of this setup, so it let
me verify (rather than guess) the real moving parts:

- Confirmed running: `me.phh.ims` started as a system-UID service
  (`me.phh.ims/me.phh.ims.PhhImsService`), plus a companion overlay
  package `me.phh.ims.overlay`. That overlay is bundled directly inside
  the `krazey/ims` repo itself (`overlay/` folder) — I dropped my earlier
  hand-written overlay and now build that real one instead.
- Confirmed **not needed**: a framework-level overlay for
  `config_wlan_data_service_package` / `config_qualified_networks_service_package`.
  The log shows `com.google.android.iwlan` and `com.android.telephony.qns`
  already installed and started under those exact package names on your
  Lunaris build — the AOSP defaults already match, no overlay required.
- The real overlay uses `android:isStatic="true"` with `android:priority="100"`,
  which auto-enables at boot — no `cmd overlay enable` boot script needed.

So the module is now simpler than my first draft: `PhhIms.apk` +
`me.phh.ims.overlay.apk` + the permissions XML + the three `persist.dbg.*`
props. Nothing else.

## The known iwlan bug (confirmed in your log, not something to "fix" here)

The log has a real crash:
```
java.lang.IllegalArgumentException: Unsupported integrity algorithm 5
  at android.net.ipsec.ike.SaProposal$Builder.validateAndAddIntegrityAlgo
  at com.google.android.iwlan.epdg.EpdgChildSaProposal.buildProposal
```
This is Google's own `com.google.android.iwlan` module crashing while
building the IPsec tunnel for WiFi calling (ePDG) — a carrier-config
integrity-algorithm value it doesn't recognize. It only affects VoWiFi
(WiFi calling), not VoLTE over LTE, and matches exactly what the XDA
thread means by "bug related to iwlan." Expect the iwlan process to
crash/restart if you try to force WiFi calling; VoLTE over mobile data
should be unaffected. If you want, once basic VoLTE is confirmed working
I can dig into whether a targeted CarrierConfig override (dropping that
integrity algorithm from the allowed list) fixes WFC too — that's a
separate, smaller task from getting VoLTE up.

## Build it (no PC needed)

1. Create a new GitHub repo via the GitHub app or mobile browser.
2. In Termux:
   ```
   pkg install git unzip
   git clone https://github.com/<you>/<your-new-repo>.git
   cd <your-new-repo>
   ```
3. Unzip this bundle's contents into that folder, preserving structure
   (`.github/workflows/`, `system/`, `keys/`, `module.prop`,
   `post-fs-data.sh`).
4. ```
   git add -A
   git commit -m "add volte module build"
   git push
   ```
5. Pushing to `main` triggers the Action automatically. Watch it in the
   repo's **Actions** tab.
6. On success, download the `r8q_volte_phhims` artifact — that contains
   the flashable `r8q_volte_phhims.zip`.
7. On failure, paste me the failing step's log and I'll fix the workflow.

## Flashing & verifying

1. Install the zip via Magisk (or KernelSU) app → reboot.
2. Confirm the pieces loaded:
   ```
   pm list packages | grep phh.ims
   cmd overlay list | grep phh.ims
   ```
   You should see `me.phh.ims`, `me.phh.ims.overlay`, and the overlay
   listed as `[x]` (enabled).
3. Try a call on mobile data with WiFi off, and watch for the VoLTE
   indicator / check `dumpsys telephony.registry` for IMS registration
   state.

## If PhhIms doesn't start / crashes

Grab a fresh logcat right after a failed attempt and send it over —
that's exactly how we nailed down the real requirements this time. Watch
in particular for:
- SELinux denials: `logcat | grep -i avc`
- `me.phh.ims` process death/crash right after boot
- Whether `me.phh.ims.overlay` shows as enabled in `cmd overlay list`

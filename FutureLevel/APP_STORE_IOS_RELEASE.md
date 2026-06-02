# App Store iOS Release

This project now has an `iOS Release` export preset in `export_presets.cfg`.

Before exporting, replace the placeholder Apple Team ID:

```ini
application/app_store_team_id="TEAMIDHERE"
```

Use the 10-character Team ID from your Apple Developer account. The bundle identifier is currently set to:

```ini
application/bundle_identifier="com.osccct.neverfear"
```

Adjust it only if the App Store Connect app record uses a different bundle ID.

## Export

Run the export from macOS with Xcode installed and the matching Godot export templates available.

```sh
cd FutureLevel
mkdir -p builds/ios
godot --headless --path . --export-release "iOS Release" ./builds/ios/NeverFear.zip
```

The preset uses `application/export_project_only=true`, so Godot creates the Xcode project package first. Open the generated Xcode project, select the correct signing team/profile, then archive and upload through Xcode Organizer or Transporter.

## Release Checks

- Replace `TEAMIDHERE` before exporting.
- Confirm the version fields before each App Store upload:
  - `application/short_version`
  - `application/version`
- The iOS release preset is intentionally ad-free. Keep the AdMob iOS export plugins disabled until the real iOS AdMob app ID, ATT copy, privacy manifest, and consent flow are ready.
- The native AdMob iOS plugin files are intentionally absent from `ios/plugins/` for App Store builds. Reinstall them through the AdMob plugin only when iOS ads are deliberately being added.
- AdMob demo/sample scenes are intentionally absent from the project and excluded by the iOS preset so Google sample ad unit IDs do not ship in production builds.
- If iOS leaderboards or achievements are needed, add Game Center support before enabling related entitlements.

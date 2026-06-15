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

The iOS preset enables Game Center through the GodotApplePlugins GameCenter addon. Because that addon requires Apple's modern GameKit runtime, the iOS deployment target is:

```ini
application/min_ios_version="17.0"
entitlements/game_center=true
```

`Singletons/PlayGames.gd` starts Game Center authentication automatically when the game boots on iOS.

## Game Center IDs

Create matching records in App Store Connect before testing achievements or leaderboards on device. The app maps existing Google Play Games IDs to these Game Center achievement IDs in `Singletons/PlayGames.gd`:

| Google Play cohort | Game Center reference name | Game Center ID |
| --- | --- | --- |
| `sharp_shooter` | `first_kill` | `001` |
| `complete_legacy_stage_1` | `Legacy Completion` | `002` |
| `no_deaths` | `No Deaths` | `003` |
| `cat_lover` | `9 lives` | `004` |
| `pretty_quick_fella` | `1-3 min finish` | `005` |
| `whoa_fast_guy` | `Finish in 2.5 min` | `006` |
| `zzooomm` | `2 min or less` | `007` |
| `eliminations_25` | `25elims` | `008` |
| `hypercore_undertaker` | `300 Elims` | `009` |
| `my_strength_is_growing` | `Rank 3` | `010` |
| `further_beyond` | `Rank 4` | `011` |

No Game Center IDs have been provided yet for the Google Play `jump`, `double_jump_ii`, or `stacks_on_stacks` achievements, so they are intentionally left unmapped on iOS.

If App Store Connect already has different IDs, update `IOS_ACHIEVEMENT_IDS` and `IOS_LEADERBOARD_IDS` in `Singletons/PlayGames.gd`.

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
- Confirm the AdMob iOS export plugin is enabled and `GADApplicationIdentifier` is set to the NeverFear iOS AdMob app ID.
- `Singletons/Ads.gd` uses Google's iOS test interstitial unit in debug builds and the NeverFear iOS interstitial unit in release builds.
- The AdMob iOS plugin includes Google Mobile Ads and User Messaging Platform dependencies. Review consent/privacy requirements for each distribution country before release.
- AdMob demo/sample scenes are intentionally absent from the project and excluded by the iOS preset so Google sample scenes do not ship in production builds.
- Confirm the Game Center capability is enabled for `com.osccct.neverfear` in Apple Developer/App Store Connect.

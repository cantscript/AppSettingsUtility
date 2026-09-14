# App Settings Utility

<p align="center">
	<img width="1024" alt="AppSettingsUtiliy" src="https://github.com/cantscript/JNUC2026/blob/main/Images/T%26THeader-PLACEHOLDER.png">
</p>

App Settings Utility is an interactive macOS shell script for finding the app and binary identifiers used when building Apple's [`com.apple.configuration.app.settings` declaration](https://developer.apple.com/documentation/devicemanagement/appsettings).

It removes the need to remember App Store API endpoints or the exact `codesign` commands needed to inspect a Mac application. Results can be reviewed in Terminal, collected during a session, and exported to CSV for later use or sharing with another administrator.

## What it does

- Searches Apple's App Store catalogue for Bundle IDs and app metadata.
- Searches across iPhone/iOS, iPad, and Mac App Store results.
- Filters downloaded results by developer and displays them five at a time.
- Provides an embedded reference list of Apple apps and Bundle IDs through the `applepreinstalled` search.
- Finds locally installed Mac applications and inspects their main executable.
- Reports details including CDHash, TeamID, SigningID, suggested PathPrefix, signing state, and architecture.
- Exports selected App Store or local application results to CSV.

The utility gathers reference information. It does not create, install, or enforce an App Settings declaration, and it does not decide which identifiers are appropriate for your policy.

## Requirements

- macOS
- Bash 3.2 or later
- `curl`
- `jq`

Local binary inspection also uses the macOS-provided `codesign`, `lipo`, and `PlistBuddy` tools.

## Quick start

Clone the repository and run the script:

```bash
git clone https://github.com/cantscript/AppSettingsUtility.git
cd AppSettingsUtility
./appSettingsUtility.sh
```

If the executable permission was not retained, run:

```bash
chmod +x appSettingsUtility.sh
```

The default CSV output directory is your Desktop. You can change it from either lookup menu.

## Documentation

The full [User and Admin Guide](docs/README.md) explains installation, navigation, session behaviour, and the two lookup workflows.

- [Bundle ID Finder and App Store lookup](docs/bundle-id-finder.md)
- [Binary Lookup for local Mac applications](docs/binary-lookup.md)

Help is also built into the script. Press `h` in an interactive menu, or use:

```bash
./appSettingsUtility.sh --help
./appSettingsUtility.sh --manual
```

## Licence

App Settings Utility is available under the [MIT License](LICENSE).

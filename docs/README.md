# App Settings Utility: User and Admin Guide

App Settings Utility helps administrators collect the identifiers they may need for Apple's `com.apple.configuration.app.settings` declaration.

There are two separate workflows:

| Workflow | Use it to find | Typical App Settings use |
| --- | --- | --- |
| [Bundle ID Finder](bundle-id-finder.md) | App Store metadata and Bundle IDs | `AllowedApps` and `DeniedApps` |
| [Binary Lookup](binary-lookup.md) | Signing and architecture details from a local Mac application | `AllowedBinaries` and `DeniedBinaries` |

The utility provides discovery data rather than policy advice. Review Apple's current declaration requirements and decide which identifiers are appropriate for the rule you are creating.

## Requirements

The script is designed for macOS and remains compatible with the Bash 3.2 version supplied by macOS. It requires:

- `curl` for App Store requests
- `jq` for processing and exporting data
- `codesign`, `lipo`, and `PlistBuddy` for local binary inspection

The final three tools are included with macOS. The script checks that `curl` and `jq` are available when it starts.

You can check them before running the utility:

```bash
command -v curl
command -v jq
```

## Install and run

Clone the repository:

```bash
git clone https://github.com/cantscript/AppSettingsUtility.git
cd AppSettingsUtility
```

Run the interactive utility:

```bash
./appSettingsUtility.sh
```

If macOS reports that the file is not executable:

```bash
chmod +x appSettingsUtility.sh
./appSettingsUtility.sh
```

You can also invoke it explicitly with Bash:

```bash
/bin/bash appSettingsUtility.sh
```

## Main menu

The opening menu offers:

1. **App Store Apps** — find App Store metadata and Bundle IDs.
2. **Local Mac Apps** — inspect the main executable of an installed Mac application.
3. **Help** — open the built-in guide.
4. **Exit** — close the utility. If there are unexported selections, the utility asks before discarding them.

The two lookup modes keep independent selected-app lists. Moving back through the menus does not discard those lists, but both are temporary and are removed when the script exits.

## Common navigation

Menu options are shown in square brackets. The most common controls are:

| Key | Action |
| --- | --- |
| `b` | Go back one level without clearing selections |
| `s` | Start another search |
| `n` | Show the next results page |
| `p` | Show the previous results page |
| `h` | Open help |
| `q` | Exit from the opening menu |

Enter the displayed number to select a menu option or search result. On search screens, you can normally type an application name directly. If the name itself is a reserved menu value such as `b`, `h`, or a number, choose **Search** first and enter the name at the dedicated prompt.

## CSV output and sessions

The default output directory is `~/Desktop`. Both workflows can change it, and the chosen directory is shared for the remainder of the current session. If a directory does not exist, the utility can create it after confirmation.

Selecting a result only opens its detail screen. Choose **Add to CSV** to place it in the temporary selection. The file is written only when you choose **Finish and create CSV**.

After a successful export, the selection for that workflow is cleared. The other workflow's selection is not affected.

## Data and privacy behaviour

- App Store searches send the search term, selected storefront, and platform request to Apple's App Store services.
- Additional App Store details are requested only when you choose **Show more detail** or add a result to the CSV selection.
- Binary Lookup scans the documented local application folders and reads metadata from the selected app. It does not launch the application.
- Temporary selection files are created with `mktemp` and removed when the script exits normally.
- The generated CSV files may contain application paths and signing information. Review them before sharing outside your organisation.

## Built-in help

Press `h` within the interactive menus, or print help directly:

```bash
./appSettingsUtility.sh --help
./appSettingsUtility.sh --manual
```

The embedded help remains available without a network connection. These documentation pages provide more context and step-by-step detail.

## Continue with a workflow

- [Bundle ID Finder and App Store lookup](bundle-id-finder.md)
- [Binary Lookup for local Mac applications](binary-lookup.md)

Return to the [project README](../README.md).

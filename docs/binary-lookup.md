# Binary Lookup for Local Mac Applications

The **Local Mac Apps** workflow inspects an installed application's main executable and reports signing and architecture information. These details can help when preparing `AllowedBinaries` and `DeniedBinaries` entries for an App Settings declaration.

The utility reports what it can verify. It does not decide how broad or narrow a rule should be, and it does not confirm that an application is safe or appropriate for your organisation.

## Open the lookup

From the main menu, choose **Local Mac Apps**. The menu shows:

- the folders included in the scan
- the number of selected applications
- the current CSV output directory

You can search, browse everything found, review or remove selected applications, export a CSV, or change the output directory.

## Search scope

Binary Lookup scans:

```text
/Applications
/System/Applications
/System/Cryptexes/App/System/Applications
```

Organisational subfolders within these locations are included. The scan stops at each `.app` bundle, so embedded helpers and other executables inside an app are not returned as separate results. Applications in other locations, including `~/Applications`, are outside the current search scope.

The selected application's main executable is inspected without launching the application.

## Search or browse applications

Choose **Search** and enter part or all of an application name. Matching is case-insensitive and partial, so `outlook` can find `Microsoft Outlook`.

Choose **Browse all local apps** to display the complete scanned catalogue. This can take longer on a Mac with many installed applications.

If you type text directly at the Local Mac Apps menu, the utility treats it as a search term unless it matches a menu option. Choose **Search** first for an application whose name conflicts with a menu command.

## Navigate results

Results show five applications per page with their paths.

Use:

- `n` for the next page
- `p` for the previous page
- `s` to return and search again
- `b` to return to the Local Mac Apps menu
- `h` to open help

Enter the displayed result number to inspect an application.

Unlike App Store results, the local workflow does not include a developer filter or a platform selector. Narrow the list by entering a more specific local application name.

## Inspect a selected application

After you select an application, the utility reads its bundle information, main executable, architectures, and code signature. The normal view prefers an Apple Silicon `arm64` or `arm64e` slice. If there is no Apple Silicon slice, it shows the available architecture.

Choose **Show ARM and Intel details** to display all discovered architectures for a universal application. Different architecture slices can have different CDHashes.

The selected-app screen can show:

- application and executable paths
- Bundle ID and version
- signature verification result
- suggested PathPrefix
- architecture
- CDHash
- TeamID
- SigningID
- SigningState

The scan describes the main executable only. An application may contain embedded helpers or tools with different signatures, which the utility does not inspect separately.

## Understand the signing fields

### CDHash

A CDHash identifies signed code for a particular architecture. An application update can change it, and architecture slices in a universal app can have different values.

### TeamID

The TeamID identifies the signing team. For verified Apple-signed code without a TeamID, the utility uses the literal `*APPLE*` token. A `com.apple.*` identifier by itself is not treated as proof of Apple signing.

### SigningID

The SigningID is the identifier recorded in the code signature. The utility does not assume that it is identical to the application's Bundle ID.

### PathPrefix

The suggested PathPrefix is the application folder with a trailing slash. It is a possible additional path restriction, not a value taken from the code signature.

### SigningState

SigningState describes a signing category rather than the validity of the signature. App Settings supports categories including Apple, App Store, Developer ID, TestFlight, Enterprise, and All.

The utility identifies **Apple**, **AppStore**, and **DeveloperID** when verification supports the result. Other or unconfirmed cases are displayed as **Unknown**. `Unknown` is a diagnostic result from this utility, not a declaration value.

### Signature verification

The script separately reports whether `codesign --verify --strict --all-architectures` succeeds. A valid signature does not by itself establish that an application is safe, notarized, approved, or appropriate for a policy.

## Add, review, and remove selected applications

Choose **Add to CSV** from the selected application's screen. All inspected architecture rows are added, so a universal application can contribute both Apple Silicon and Intel rows.

Back on the Local Mac Apps menu:

- **View selected apps** shows one entry per selected application path.
- **Remove selected app** removes the app and all of its architecture rows.
- **Finish and create CSV** writes the current selection.

Ordinary local selections can be added more than once. Review the selection before exporting if you revisited the same application.

## Change the CSV directory

Choose **Change CSV Output Directory** and enter an existing writable directory. If it does not exist, the utility offers to create it.

The default is `~/Desktop`. A change is also used by the App Store workflow for the remainder of the current session.

## Export the Binary Lookup CSV

Choose **Finish and create CSV**. The utility creates a timestamped file similar to:

```text
Local-Mac-Apps_2026-09-14_17-30-00_ABCD12.csv
```

The export contains one row per architecture and includes:

- App Name
- App Path
- Executable Path
- Bundle ID
- Version
- Architecture
- CDHash
- TeamID
- SigningID
- suggested PathPrefix
- SigningState
- Signature Verification

After a successful export, the local selection is cleared. Treat the CSV as reference data: review the current App Settings schema and decide which supported combination of identifiers should form the intended rule.

## Troubleshooting

If an application is missing:

1. Check that it is installed in one of the scanned folders.
2. Try a shorter partial name.
3. Use **Browse all local apps**.
4. Remember that embedded helpers and apps under `~/Applications` are not listed.

If TeamID is unavailable or SigningState is unknown, the application may be unsigned, verification may have failed, its signing category may not match one detected by the script, or the current environment may not trust the certificate chain. Do not replace missing data with guessed identifiers.

If CSV export fails, choose an existing writable directory. The local selection is retained after an unsuccessful export attempt.

Return to the [User and Admin Guide](README.md) or read the [Bundle ID Finder guide](bundle-id-finder.md).

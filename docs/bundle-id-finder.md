# Bundle ID Finder and App Store Lookup

The **App Store Apps** workflow searches Apple's catalogue for app metadata and Bundle IDs. These are commonly used when preparing `AllowedApps` and `DeniedApps` entries for an App Settings declaration.

## Open the lookup

From the main menu, choose **App Store Apps**. The menu shows the current:

- App Store storefront
- Default search platform
- CSV output directory

Choose **Start Search** to begin, or change the settings first.

## Change the App Store

The default storefront is the United Kingdom (`gb`). The utility includes shortcuts for:

- United Kingdom
- United States
- Canada
- Australia
- Germany
- France

Choose **Other** to enter a different two-letter country code. App availability and the order of search results can vary by storefront.

The chosen storefront is also used when the utility requests the additional details for a selected app.

## Change the platform

The default platform is **All**. You can change the default before starting a search, or change the platform for only the current search session.

Available choices are:

- **All**
- **iPhone / iOS**
- **iPad**
- **Mac**

**All** runs the relevant catalogue searches and combines their results. Records with the same App Store ID are merged, and the displayed platform labels show which searches returned the app. A platform label is useful for narrowing results, but it is not a complete hardware or OS compatibility assessment.

## Change the CSV directory

Choose **Change CSV Output Directory** from the App Store Apps menu. Enter an existing writable directory, using either a full path or a path beginning with `~`.

If the directory does not exist, the utility offers to create it. The new location is shared with Binary Lookup for the remainder of the session.

## Search for an app

Choose **Start Search**, then either:

- type an app name directly at the menu prompt; or
- choose **Search** and enter the name at the separate search prompt.

The second method is useful when the app name is also a menu command or number.

The utility sends the search to the selected storefront using the current platform. Apple controls the returned matches and ranking, so try a more specific name, a different platform, or another storefront if the expected app is missing.

## Read and narrow search results

Results show the app name, developer, platform, Bundle ID, and App Store ID. Five results are displayed per page.

Use:

- `n` for the next page
- `p` for the previous page
- `f` to filter by developer
- `c` to clear the developer filter
- `s` to search again
- `b` to return to the search menu

The developer filter is a case-insensitive partial match. For example, `micro` can match `Microsoft Corporation`. Filtering is performed locally against the results already downloaded; it does not send another App Store request. Applying or clearing a filter returns you to page one.

The numbers displayed beside results remain the numbers to enter when selecting an app, including on later pages.

## Select an app and show more detail

Enter a result number to open its selected-app screen. This does not add the app to the CSV selection.

From this screen you can:

- **Add to CSV**
- **Show more detail**
- return to the results
- start another search
- open help

**Show more detail** requests additional catalogue information using the selected App Store ID and storefront. Depending on what Apple returns, the detail view can include:

- seller and developer
- Bundle ID and App Store ID
- version and external version ID
- platforms and device families
- minimum OS and required capabilities
- price and age rating
- device-based VPP licensing availability
- download size and release dates
- App Store URL

The result is cached for the current result list. If Apple does not provide a value, the utility displays it as unavailable rather than inventing one.

The App Store ID, external version ID, and CDHash are different identifiers. An external version ID describes a catalogue version; it is not a binary CDHash.

## Add, review, and remove selected apps

Choose **Add to CSV** from an app's selected-app screen. If the extended details have not already been loaded, the utility tries to fetch them so the export can include an external version ID. A failure does not prevent the app from being added; unavailable values remain blank.

Back on the App Store Search menu:

- **View selected apps** displays the current temporary selection.
- **Remove selected app** lets you remove an individual row.
- **Finish and create CSV** exports the list.

Ordinary App Store searches can add the same app more than once, so review the selection before exporting.

## Use `applepreinstalled`

Some Apple apps supplied with iPhone or iPad are not useful to search for as ordinary App Store records. To access the utility's embedded Bundle ID reference, enter:

```text
applepreinstalled
```

The command is not case-sensitive. It opens a shorter, 53-entry built-in/preinstalled selection by default. Press `a` to switch between that selection and the complete 75-entry Apple reference list.

Important behaviour:

- The list is embedded in the script and works offline.
- It is independent of the selected App Store and platform.
- Each view has its own numbering, so select using the number currently displayed.
- Entering a number adds that app directly to the App Store CSV selection.
- The list remains open, allowing several apps to be selected in sequence.
- Duplicate Bundle IDs already in the selection are skipped.
- Version, App Store ID, and external version ID are blank because the reference supplies names and Bundle IDs without making additional catalogue requests.

The built-in selection is a reference, not an inventory of what is installed on a particular device. Availability varies by device, OS version, configuration, and region. The embedded snapshot records its source and verification date in the script output and does not update itself automatically.

## Export the App Store CSV

Choose **Finish and create CSV**. The utility creates a timestamped file similar to:

```text
BundleID-Lookup_2026-09-14_17-30-00.csv
```

The export contains:

- App Name
- Platform
- Bundle ID
- App Store ID
- Developer
- Version
- Minimum OS
- App Store URL
- External Version ID

After a successful export, the App Store selection is cleared. Open the CSV and confirm that you selected the intended application, storefront result, and platform before using its identifiers in a management configuration.

## Troubleshooting

If the expected app is not listed:

1. Clear any developer filter.
2. Check the selected platform and storefront.
3. Try the exact App Store name or a more specific search.
4. Try **All** to compare iPhone/iOS, iPad, and Mac records.
5. Confirm that the Mac has internet access and can reach Apple's service.

If CSV export fails, select an existing writable output directory. Your selection is retained after an unsuccessful export attempt.

Return to the [User and Admin Guide](README.md) or continue to [Binary Lookup](binary-lookup.md).

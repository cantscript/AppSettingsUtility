#!/bin/bash

###############################################################################
# App Settings Utility
# Version: 1.0.1
#
# Interactive app identifier and signing information lookup utility.
#
# Contributor: Anthony Darlow (CantScript)
# License: MIT
#
# This software is provided "as is", without warranty of any kind.
# Use of this utility and its output is entirely at your own risk.
###############################################################################

SCRIPT_VERSION="1.0.1"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

DEFAULT_STORE_CODE="gb"
DEFAULT_STORE_NAME="United Kingdom"

STORE_CODE="$DEFAULT_STORE_CODE"
STORE_NAME="$DEFAULT_STORE_NAME"

DEFAULT_PLATFORM="all"

OUTPUT_DIRECTORY="$HOME/Desktop"

RESULTS_PER_REQUEST=50
RESULTS_PER_PAGE=5

SELECTED_APPS_FILE=$(mktemp)

LOCAL_SELECTED_FILE=$(mktemp)
trap 'rm -f "$SELECTED_APPS_FILE" "$LOCAL_SELECTED_FILE"' EXIT


# -----------------------------------------------------------------------------
# Colours
# -----------------------------------------------------------------------------

if [[ -t 1 ]]; then
    RESET="\033[0m"
    BOLD="\033[1m"
    DIM="\033[2m"

    BLUE="\033[34m"
    CYAN="\033[36m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    WHITE="\033[97m"
else
    RESET=""
    BOLD=""
    DIM=""

    BLUE=""
    CYAN=""
    GREEN=""
    YELLOW=""
    RED=""
    WHITE=""
fi


# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

# Reset MENU_ROW before each menu so visible options alternate consistently.
print_menu_option() {
    local colour="$RESET"
    if (( MENU_ROW % 2 )); then
        colour="$CYAN"
    fi
    printf '%b%s%b\n' "$colour" "$1" "$RESET"
    MENU_ROW=$((MENU_ROW + 1))
}

print_screen_divider() {
    printf '\n%b%b%s%b\n\n' "$YELLOW" "$BOLD" \
        '============================================================' "$RESET"
}

clear_screen() {
    clear
    print_screen_divider
}


pause() {
    echo
    read -r -p "Press Return to continue..." _
}


print_settings_title() {
    printf '\n%b%b' "$CYAN" "$BOLD"
    cat <<'EOF'
 █████╗ ██████╗ ██████╗    ███████╗███████╗████████╗████████╗██╗███╗   ██╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗   ██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██║████╗  ██║██╔════╝ ██╔════╝
███████║██████╔╝██████╔╝   ███████╗█████╗     ██║      ██║   ██║██╔██╗ ██║██║  ███╗███████╗
██╔══██║██╔═══╝ ██╔═══╝    ╚════██║██╔══╝     ██║      ██║   ██║██║╚██╗██║██║   ██║╚════██║
██║  ██║██║     ██║        ███████║███████╗   ██║      ██║   ██║██║ ╚████║╚██████╔╝███████║
╚═╝  ╚═╝╚═╝     ╚═╝        ╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
EOF
    printf '%b\n%b%b%s%b\n' "$RESET" "$YELLOW" "$BOLD" \
        '========================== com.apple.configuration.app.settings ===========================' "$RESET"
    printf '%*s%s\n' 16 '' 'A utility to find the details you need for this declaration'
    printf '%*sVersion %s\n' 39 '' "$SCRIPT_VERSION"
    printf '\n'
}

print_binary_title() {
    printf '\n%b%b' "$CYAN" "$BOLD"
    cat <<'EOF'
██████╗ ██╗███╗   ██╗ █████╗ ██████╗ ██╗   ██╗
██╔══██╗██║████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║██╔██╗ ██║███████║██████╔╝ ╚████╔╝ 
██╔══██╗██║██║╚██╗██║██╔══██║██╔══██╗  ╚██╔╝  
██████╔╝██║██║ ╚████║██║  ██║██║  ██║   ██║   
╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
EOF
    printf '%b\n%b%b%s%b\n' "$RESET" "$YELLOW" "$BOLD" \
        '=================== LOOKUP ===================' "$RESET"
    printf '\n'
}

print_title() {

    echo -e "${CYAN}${BOLD}"

    cat <<'EOF'

██████╗ ██╗   ██╗███╗   ██╗██████╗ ██╗     ███████╗██╗██████╗
██╔══██╗██║   ██║████╗  ██║██╔══██╗██║     ██╔════╝██║██╔══██╗
██████╔╝██║   ██║██╔██╗ ██║██║  ██║██║     █████╗  ██║██║  ██║
██╔══██╗██║   ██║██║╚██╗██║██║  ██║██║     ██╔══╝  ██║██║  ██║
██████╔╝╚██████╔╝██║ ╚████║██████╔╝███████╗███████╗██║██████╔╝
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚══════╝╚═╝╚═════╝

EOF
    printf '%b%b%b%s%b\n' "$RESET" "$YELLOW" "$BOLD" \
        '========================== LOOKUP ===========================' "$RESET"

    echo -e "${RESET}"
}


selected_count() {

    if [[ ! -s "$SELECTED_APPS_FILE" ]]; then
        echo "0"
    else
        wc -l < "$SELECTED_APPS_FILE" | tr -d ' '
    fi
}


url_encode() {
    printf '%s' "$1" | jq -sRr @uri
}


validate_dependencies() {

    local missing=0

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Error: curl is required but was not found.${RESET}"
        missing=1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}Error: jq is required but was not found.${RESET}"
        missing=1
    fi

    if [[ "$missing" -eq 1 ]]; then
        exit 1
    fi
}


# -----------------------------------------------------------------------------
# Platform handling
# -----------------------------------------------------------------------------

platform_display_name() {

    case "$1" in
        all)
            echo "All"
            ;;
        ios)
            echo "iPhone / iOS"
            ;;
        ipad)
            echo "iPad"
            ;;
        mac)
            echo "Mac"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}


platform_entity() {

    case "$1" in
        ios)
            echo "software"
            ;;
        ipad)
            echo "iPadSoftware"
            ;;
        mac)
            echo "macSoftware"
            ;;
        *)
            echo ""
            ;;
    esac
}


choose_platform() {

    local current_platform="$1"
    local choice

    while true; do

        echo
        print_screen_divider
        echo -e "${CYAN}${BOLD}Platform${RESET}"
        echo
        MENU_ROW=0
        print_menu_option "  [1] All"
        print_menu_option "  [2] iPhone / iOS"
        print_menu_option "  [3] iPad"
        print_menu_option "  [4] Mac"
        print_menu_option "  [b] Back"
        echo
        echo "Current: $(platform_display_name "$current_platform")"
        echo

        read -r -p "Choose platform [Return = keep current]: " choice

        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

        case "$choice" in

            ""|[Bb])
                CHOSEN_PLATFORM="$current_platform"
                return
                ;;

            1|all|a)
                CHOSEN_PLATFORM="all"
                return
                ;;

            2|ios|iphone|iphone/ios)
                CHOSEN_PLATFORM="ios"
                return
                ;;

            3|ipad|ipados)
                CHOSEN_PLATFORM="ipad"
                return
                ;;

            4|mac|macos)
                CHOSEN_PLATFORM="mac"
                return
                ;;

            *)
                echo
                echo -e "${YELLOW}Please choose All, iPhone/iOS, iPad, or Mac.${RESET}"
                ;;

        esac

    done
}


# -----------------------------------------------------------------------------
# Store handling
# -----------------------------------------------------------------------------

change_store() {

    while true; do

        clear_screen

        echo -e "${CYAN}${BOLD}Change App Store${RESET}"
        echo
        echo "Current store: ${STORE_NAME} (${STORE_CODE})"
        echo
        MENU_ROW=0
        print_menu_option "  [1] United Kingdom"
        print_menu_option "  [2] United States"
        print_menu_option "  [3] Canada"
        print_menu_option "  [4] Australia"
        print_menu_option "  [5] Germany"
        print_menu_option "  [6] France"
        print_menu_option "  [7] Other"
        print_menu_option "  [b] Back"
        echo

        read -r -p "Choose a store: " choice

        case "$choice" in

            1)
                STORE_CODE="gb"
                STORE_NAME="United Kingdom"
                return
                ;;

            2)
                STORE_CODE="us"
                STORE_NAME="United States"
                return
                ;;

            3)
                STORE_CODE="ca"
                STORE_NAME="Canada"
                return
                ;;

            4)
                STORE_CODE="au"
                STORE_NAME="Australia"
                return
                ;;

            5)
                STORE_CODE="de"
                STORE_NAME="Germany"
                return
                ;;

            6)
                STORE_CODE="fr"
                STORE_NAME="France"
                return
                ;;

            7)

                echo
                read -r -p "Enter two-letter country code: " custom_code

                custom_code=$(echo "$custom_code" | tr '[:upper:]' '[:lower:]')

                if [[ "$custom_code" =~ ^[a-z]{2}$ ]]; then

                    STORE_CODE="$custom_code"
                    STORE_NAME="Custom Store"

                    return

                else

                    echo
                    echo -e "${RED}Country code must be two letters.${RESET}"
                    pause

                fi
                ;;

            [Bb])
                return
                ;;

            *)
                echo
                echo -e "${YELLOW}Invalid selection.${RESET}"
                pause
                ;;

        esac

    done
}


# -----------------------------------------------------------------------------
# Output directory
# -----------------------------------------------------------------------------

change_output_directory() {

    clear_screen

    echo -e "${CYAN}${BOLD}CSV Output Directory${RESET}"
    echo
    echo "Current directory:"
    echo -e "${WHITE}${OUTPUT_DIRECTORY}${RESET}"
    echo

    read -r -p "Enter new directory [Return = cancel]: " new_directory

    [[ -z "$new_directory" ]] && return

    new_directory="${new_directory/#\~/$HOME}"

    if [[ -d "$new_directory" ]]; then

        if [[ -w "$new_directory" ]]; then

            OUTPUT_DIRECTORY="$new_directory"

            echo
            echo -e "${GREEN}Output directory updated.${RESET}"

        else

            echo
            echo -e "${RED}That directory is not writable.${RESET}"

        fi

    else

        echo
        echo -e "${YELLOW}Directory does not exist.${RESET}"
        echo

        read -r -p "Create it? [y/N]: " create_choice

        if [[ "$create_choice" =~ ^[Yy]$ ]]; then

            if mkdir -p "$new_directory"; then

                OUTPUT_DIRECTORY="$new_directory"

                echo
                echo -e "${GREEN}Directory created and selected.${RESET}"

            else

                echo
                echo -e "${RED}Unable to create directory.${RESET}"

            fi

        fi

    fi

    pause
}


# -----------------------------------------------------------------------------
# Search API
# -----------------------------------------------------------------------------

search_entity() {

    local search_term="$1"
    local platform="$2"

    local encoded_term
    local entity

    encoded_term=$(url_encode "$search_term")
    entity=$(platform_entity "$platform")

    curl -sS \
        --fail \
        --connect-timeout 10 \
        --max-time 20 \
        "https://itunes.apple.com/search?term=${encoded_term}&entity=${entity}&country=${STORE_CODE}&limit=${RESULTS_PER_REQUEST}" \
        2>/dev/null
}


# -----------------------------------------------------------------------------
# Combine / normalise results
# -----------------------------------------------------------------------------

normalise_results() {

    local response="$1"
    local platform_label="$2"

    echo "$response" | jq \
        --arg platform "$platform_label" '

        [
            .results[] |

            {
                name: .trackName,
                bundleId: .bundleId,
                appStoreId: .trackId,
                developer: .artistName,
                version: .version,
                minimumOS: .minimumOsVersion,
                appStoreURL: .trackViewUrl,
                platforms: [$platform],
                seller: .sellerName,
                formattedPrice: .formattedPrice,
                ageRating: .trackContentRating,
                vppDeviceLicensing: .isVppDeviceBasedLicensingEnabled,
                fileSizeBytes: .fileSizeBytes,
                releaseDate: .releaseDate,
                currentVersionReleaseDate: .currentVersionReleaseDate,
                languages: .languageCodesISO2A,
                description: .description,
                releaseNotes: .releaseNotes
            }
        ]

    '
}


merge_results() {

    jq -s '

        add |

        group_by(.appStoreId) |

        map(

            .[0] +

            {
                platforms:
                    (
                        map(.platforms[])
                        | unique
                    )
            }

        )

    '
}


# -----------------------------------------------------------------------------
# Perform actual search
# -----------------------------------------------------------------------------

run_search() {

    local search_term="$1"
    local platform="$2"

    if [[ "$platform" != "all" ]]; then

        local response

        response=$(search_entity "$search_term" "$platform")

        if [[ $? -ne 0 || -z "$response" ]]; then
            return 1
        fi

        normalise_results \
            "$response" \
            "$(platform_display_name "$platform")"

        return 0

    fi


    # -------------------------------------------------------------------------
    # "All" means we query all three Apple software entities
    # -------------------------------------------------------------------------

    local ios_response
    local ipad_response
    local mac_response

    ios_response=$(search_entity "$search_term" "ios")

    if [[ $? -ne 0 || -z "$ios_response" ]]; then
        return 1
    fi


    ipad_response=$(search_entity "$search_term" "ipad")

    if [[ $? -ne 0 || -z "$ipad_response" ]]; then
        return 1
    fi


    mac_response=$(search_entity "$search_term" "mac")

    if [[ $? -ne 0 || -z "$mac_response" ]]; then
        return 1
    fi


    local ios_normalised
    local ipad_normalised
    local mac_normalised

    ios_normalised=$(
        normalise_results \
            "$ios_response" \
            "iPhone / iOS"
    )

    ipad_normalised=$(
        normalise_results \
            "$ipad_response" \
            "iPad"
    )

    mac_normalised=$(
        normalise_results \
            "$mac_response" \
            "Mac"
    )


    printf '%s\n%s\n%s\n' \
        "$ios_normalised" \
        "$ipad_normalised" \
        "$mac_normalised" |
        merge_results
}


# -----------------------------------------------------------------------------
# Selected app management
# -----------------------------------------------------------------------------

view_selected_apps() {

    clear_screen

    echo -e "${CYAN}${BOLD}Selected Apps${RESET}"
    echo

    local count
    count=$(selected_count)

    if [[ "$count" -eq 0 ]]; then

        echo -e "${DIM}No apps selected.${RESET}"

        pause
        return

    fi

    jq -s -r '

        to_entries[] |

        "\(.key + 1). \(.value.name)
   Developer: \(.value.developer)
   Platform:  \(.value.platforms | join(", "))
   Bundle ID: \(.value.bundleId)
   App ID:    \(.value.appStoreId)
"

    ' "$SELECTED_APPS_FILE"

    echo -e "${GREEN}${count} app(s) selected.${RESET}"

    pause
}


remove_selected_app() {

    while true; do

        clear_screen

        echo -e "${CYAN}${BOLD}Remove Selected App${RESET}"
        echo

        local count
        count=$(selected_count)

        if [[ "$count" -eq 0 ]]; then

            echo -e "${DIM}No apps selected.${RESET}"

            pause
            return

        fi

        jq -s -r '

            to_entries[] |

            "\(.key + 1). \(.value.name)
   Platform: \(.value.platforms | join(", "))
   Bundle ID: \(.value.bundleId)
"

        ' "$SELECTED_APPS_FILE"

        echo
        MENU_ROW=0
        print_menu_option "  [b] Back"
        echo

        read -r -p "Select app to remove: " choice

        [[ "$choice" =~ ^[Bb]$ ]] && return

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           (( choice >= 1 && choice <= count )); then

            local index=$((choice - 1))
            local temp_file

            temp_file=$(mktemp)

            jq -s -c \
                --argjson index "$index" '

                del(.[$index])[]

            ' "$SELECTED_APPS_FILE" > "$temp_file"

            mv "$temp_file" "$SELECTED_APPS_FILE"

            echo
            echo -e "${GREEN}App removed.${RESET}"

            pause

        else

            echo
            echo -e "${YELLOW}Invalid selection.${RESET}"

            pause

        fi

    done
}


# -----------------------------------------------------------------------------
# Search result display
# -----------------------------------------------------------------------------

display_search_page() {

    local response="$1"
    local page="$2"
    local page_size="$3"

    local result_count
    result_count=$(echo "$response" | jq 'length')

    local start=$((page * page_size))
    local end=$((start + page_size))

    if (( end > result_count )); then
        end="$result_count"
    fi

    echo "$response" | jq -r \
        --arg cyan "$(printf '%b' "$CYAN")" \
        --arg bold "$(printf '%b' "$BOLD")" \
        --arg reset "$(printf '%b' "$RESET")" \
        --argjson start "$start" \
        --argjson end "$end" '

        .[$start:$end] |

        to_entries[] |

        "\(.key + $start + 1). \($cyan)\($bold)\(.value.name)\($reset)
   \($bold)Developer:\($reset) \(.value.developer // "Unknown")
   \($bold)Platform:\($reset)  \(.value.platforms | join(", "))
   \($bold)Bundle ID:\($reset) \(.value.bundleId // "Unknown")
   \($bold)App ID:\($reset)    \(.value.appStoreId // "Unknown")
   \($bold)Version:\($reset)   \(.value.version // "Unknown")
"

    '
}


# -----------------------------------------------------------------------------
# Search result selection
# -----------------------------------------------------------------------------

# Fetch details only when requested. The caller owns the per-search cache.
load_app_details() {
    local app="$1"
    local id key cached response detail
    id=$(printf '%s' "$app" | jq -r '.appStoreId')
    key="${STORE_CODE}:${id}"
    ENRICHED_APP="$app"
    cached=$(printf '%s' "$details_cache" | jq -c --arg key "$key" '.[$key] // empty')
    if [[ -z "$cached" ]]; then
        echo "Loading app details..."
        if ! response=$(curl -sS --fail --connect-timeout 10 --max-time 20 \
            "https://uclient-api.itunes.apple.com/WebObjects/MZStorePlatform.woa/wa/lookup?version=2&id=${id}&p=mdm-lockup&caller=MDM&cc=${STORE_CODE}" 2>/dev/null); then
            return 1
        fi
        if ! detail=$(printf '%s' "$response" | jq -ce --arg id "$id" \
            '.results[$id] | select(type == "object" and .bundleId != null)'); then
            return 1
        fi
        cached="$detail"
        details_cache=$(printf '%s' "$details_cache" | jq -c --arg key "$key" \
            --argjson detail "$detail" '. + {($key): $detail}')
    fi
    ENRICHED_APP=$(printf '%s' "$app" | jq -c --argjson detail "$cached" '
        ([$detail.offers[]? | select(.version.display != null and .version.externalId != null)][0]) as $offer |
        . + {details: $detail, externalVersionId: ($offer.version.externalId // null),
             version: ($offer.version.display // .version)}
    ')
}

# Alternate attribute rows while keeping only labels bold.
format_app_attributes() {
    local line label value colour row=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *": "* ]]; then
            label="${line%%: *}:"
            value="${line#*: }"
            colour="$RESET"
            if (( row % 2 )); then
                colour="$CYAN"
            fi
            printf '%b%b%-28s%b%b%s%b\n' \
                "$colour" "$BOLD" "$label" "$RESET" "$colour" "$value" "$RESET"
            row=$((row + 1))
        elif [[ -z "$line" ]]; then
            printf '\n'
        else
            printf '%b%s%b\n' "$BOLD" "$line" "$RESET"
        fi
    done
}

show_app_details() {
    print_app_name "$1"
    printf '%s' "$1" | jq -r '
        def value: if . == null or . == "" then "Unavailable" else tostring end;
        def list: if type == "array" and length > 0 then join(", ") else "Unavailable" end;
        . as $app | (.details // {}) as $d |
        "Developer: \(.developer | value)\nSeller: \(($d.softwareInfo.seller // .seller) | value)
Bundle ID: \(.bundleId)\nApp Store ID: \(.appStoreId)
Version: \(.version | value)\nExternal version ID: \(.externalVersionId | value)
Platforms: \(.platforms | list)\nDevice families: \($d.deviceFamilies | list)
Minimum OS: \(($d.minimumOSVersion // .minimumOS) | value)
Required capabilities: \($d.requiredCapabilities | value)
Price: \((.formattedPrice // $d.offers[0].priceFormatted) | value)
Age rating: \(($d.contentRatingsBySystem.appsApple.name // .ageRating) | value)
Device-based VPP licensing: \(if $d.isVppDeviceBasedLicensingEnabled != null then $d.isVppDeviceBasedLicensingEnabled elif .vppDeviceLicensing != null then .vppDeviceLicensing else null end | value)
Download size (bytes): \(($d.offers[0].assets[0].size // .fileSizeBytes) | value)
Released: \((.releaseDate // $d.releaseDate) | value)
Latest release: \((.currentVersionReleaseDate // $d.latestVersionReleaseDate) | value)
App Store: \(($d.url // .appStoreURL) | value)"
    ' | format_app_attributes
}

print_app_name() {
    local name
    name=$(printf '%s' "$1" | jq -r '.name')
    printf '%b%b%s%b\n' "$CYAN" "$BOLD" "$name" "$RESET"
}

show_selected_app() {
    print_app_name "$1"
    printf '%s' "$1" | jq -r \
        --arg bold "$(printf '%b' "$BOLD")" \
        --arg reset "$(printf '%b' "$RESET")" '
        "   \($bold)Developer:\($reset) \(.developer // "Unknown")
   \($bold)Platform:\($reset)  \(.platforms | join(", "))
   \($bold)Bundle ID:\($reset) \(.bundleId // "Unknown")
   \($bold)App ID:\($reset)    \(.appStoreId // "Unknown")
   \($bold)Version:\($reset)   \(.version // "Unknown")"
    '
}

selected_app_menu() {
    local app="$1"
    local choice detail_view=0 details_loaded=0 lookup_warning=""
    while true; do
        clear_screen
        echo
        printf "%bYou've selected%b\n\n" "$BOLD" "$RESET"
        if (( detail_view )); then
            show_app_details "$app"
        else
            show_selected_app "$app"
        fi
        [[ -n "$lookup_warning" ]] && printf '\n%s\n' "$lookup_warning"
        echo
        printf "%bWhat would you like to do with this app?%b\n\n" "$BOLD" "$RESET"
        MENU_ROW=0
        print_menu_option "  [1] Add to CSV"
        if (( ! detail_view )); then
            print_menu_option "  [2] Show more detail"
        fi
        print_menu_option "  [s] Search again"
        if (( detail_view )); then
            print_menu_option "  [b] Back to selected app"
        else
            print_menu_option "  [b] Back to results"
        fi
        print_menu_option "  [h] Help"
        echo
        read -r -p "Choice: " choice || return 1
        case "$choice" in
            [Hh]) help_menu; continue ;;
            1)
                if (( ! details_loaded )); then
                    if load_app_details "$app"; then
                        app="$ENRICHED_APP"
                    else
                        echo "Additional details could not be loaded. Adding with external version ID unavailable."
                    fi
                fi
                printf '%s\n' "$app" >> "$SELECTED_APPS_FILE"
                echo "App added to CSV selection. Selected apps: $(selected_count)"
                pause
                return 0
                ;;
            2)
                if (( detail_view )); then
                    echo "Use [b] to return to the selected app."
                else
                    if (( ! details_loaded )); then
                        if load_app_details "$app"; then
                            app="$ENRICHED_APP"
                            details_loaded=1
                            lookup_warning=""
                            if [[ $(printf '%s' "$app" | jq -r '.externalVersionId') == null ]]; then
                                lookup_warning="Apple did not return an external version ID for this app."
                            fi
                        else
                            lookup_warning="Additional details could not be loaded. Showing search details; external version ID unavailable. Choose Show more detail again to retry."
                        fi
                    fi
                    detail_view=1
                fi
                ;;
            [Ss]) return 2 ;;
            [Bb]) if (( detail_view )); then detail_view=0; else return 1; fi ;;
            *) echo "Invalid selection."; pause ;;
        esac
    done
}

print_result_summary() {
    local result_count="$1" original_count="$2" developer_filter="$3" page="$4" total_pages="$5"
        if [[ -n "$developer_filter" ]]; then
            printf 'Showing %b%s%b of %b%s%b results\n' \
                "${YELLOW}${BOLD}" "$result_count" "$RESET" \
                "${YELLOW}${BOLD}" "$original_count" "$RESET"
        else
            printf 'Found %b%s%b result(s)\n' "${YELLOW}${BOLD}" "$result_count" "$RESET"
        fi
        if (( result_count > 0 )); then
            printf 'Page %b%s%b of %b%s%b\n' \
                "${YELLOW}${BOLD}" "$((page + 1))" "$RESET" \
                "${YELLOW}${BOLD}" "$total_pages" "$RESET"
        else
            echo "No results match. Use [f] to change the filter or [c] to clear it."
        fi
}

select_search_result() {

    local response="$1"
    local platform="$2"

    # Keep the fetched results intact so filters can be replaced or cleared locally.
    local all_response="$response"
    local developer_filter=""
    local details_cache='{}'
    local ENRICHED_APP
    local choice
    local original_count
    original_count=$(printf '%s' "$all_response" | jq 'length')

    local result_count
    result_count=$(echo "$response" | jq 'length')

    local page=0
    local total_pages=$(( (result_count + RESULTS_PER_PAGE - 1) / RESULTS_PER_PAGE ))

    while true; do

        result_count=$(printf '%s' "$response" | jq 'length')
        total_pages=$(( (result_count + RESULTS_PER_PAGE - 1) / RESULTS_PER_PAGE ))

        clear_screen

        echo -e "${CYAN}${BOLD}Search Results${RESET}"
        echo
        printf '%bStore:%b    %s (%s)\n' "$BOLD" "$RESET" "$STORE_NAME" "$STORE_CODE"
        printf '%bSearch:%b   %s\n' "$BOLD" "$RESET" "$(platform_display_name "$platform")"
        echo
        if [[ -n "$developer_filter" ]]; then
            printf '%bDeveloper Filter:%b %s\n' "$BOLD" "$RESET" "$developer_filter"
        fi
        print_result_summary "$result_count" "$original_count" "$developer_filter" "$page" "$total_pages"
        echo

        display_search_page \
            "$response" \
            "$page" \
            "$RESULTS_PER_PAGE"

        print_result_summary "$result_count" "$original_count" "$developer_filter" "$page" "$total_pages"
        echo
        echo -e "${CYAN}${BOLD}Commands${RESET}"
        echo

        MENU_ROW=0
        if (( result_count > 0 )); then
            printf '  %bEnter result number to select%b\n' "$BOLD" "$RESET"
        fi

        if (( page > 0 )); then
            print_menu_option "  [p] Previous page"
        fi

        if (( page < total_pages - 1 )); then
            print_menu_option "  [n] Next page"
        fi

        print_menu_option "  [f] Filter by developer"
        print_menu_option "  [c] Clear developer filter"
        print_menu_option "  [s] Search again"
        print_menu_option "  [b] Back to search menu"
        print_menu_option "  [h] Help"
        echo

        read -r -p "Choice: " choice || return 1

        case "$choice" in
            [Hh]) help_menu; continue ;;

            [Nn])

                if (( page < total_pages - 1 )); then
                    ((page++))
                fi
                ;;

            [Pp])

                if (( page > 0 )); then
                    ((page--))
                fi
                ;;

            [Ff])
                echo
                IFS= read -r -p "Developer contains [Return = clear filter]: " developer_filter || return 1
                response=$(printf '%s' "$all_response" | jq \
                    --arg developer "$developer_filter" '
                    ($developer | ascii_downcase) as $needle |
                    map(select((.developer // "" | ascii_downcase) | contains($needle)))
                ')
                page=0
                ;;

            [Cc])
                developer_filter=""
                response="$all_response"
                page=0
                ;;

            [Ss])
                return 2
                ;;

            [Bb])
                return 1
                ;;

            *)

                if [[ "$choice" =~ ^[0-9]+$ ]] &&
                   (( choice >= 1 && choice <= result_count )); then

                    local index=$((choice - 1))
                    local selected

                    selected=$(echo "$response" | jq -c \
                        --argjson index "$index" '

                        .[$index]

                    ')

                    selected_app_menu "$selected"
                    local app_action=$?
                    case "$app_action" in
                        0) return 0 ;;
                        2) return 2 ;;
                    esac

                else

                    echo
                    echo -e "${YELLOW}Invalid selection.${RESET}"

                    pause

                fi
                ;;

        esac

    done
}


# -----------------------------------------------------------------------------
# Main search session
# -----------------------------------------------------------------------------

perform_search() {

    local platform="$DEFAULT_PLATFORM"
    local direct_search=0
    local search_term choice

    while true; do

        clear_screen

        echo -e "${CYAN}${BOLD}App Store Search${RESET}"
        echo
        printf '%bStore:%b          %s (%s)\n' "$BOLD" "$RESET" "$STORE_NAME" "$STORE_CODE"
        printf '%bPlatform:%b       %s\n' "$BOLD" "$RESET" "$(platform_display_name "$platform")"
        printf '%bSelected apps:%b  %s\n' "$BOLD" "$RESET" "$(selected_count)"
        echo

        MENU_ROW=0
        print_menu_option "  [1] Search"
        print_menu_option "  [2] Change platform for this search"
        print_menu_option "  [3] View selected apps"
        print_menu_option "  [4] Remove selected app"
        print_menu_option "  [5] Finish and create CSV"
        print_menu_option "  [b] Back to App Store menu"
        print_menu_option "  [h] Help"
        echo

        direct_search=0
        IFS= read -r -p "Enter an app name or choose an option: " choice || return
        case "$choice" in
            [Hh]) help_menu; continue ;;
            "") continue ;;
            [Bb]) return ;;
            [1-5]) ;;
            *) search_term="$choice"; direct_search=1; choice=1 ;;
        esac

        case "$choice" in

            1)

                echo
                if (( ! direct_search )); then
                    IFS= read -r -p "Search for an app: " search_term || return
                fi

                [[ -z "$search_term" ]] && continue
                if [[ $(printf '%s' "$search_term" | tr '[:upper:]' '[:lower:]') == applepreinstalled ]]; then
                    apple_preinstalled_menu
                    continue
                fi

                echo
                echo -e "${CYAN}Searching ${STORE_NAME} App Store...${RESET}"
                echo -e "${DIM}Search platform: $(platform_display_name "$platform")${RESET}"

                local response

                response=$(run_search "$search_term" "$platform")

                if [[ $? -ne 0 || -z "$response" ]]; then

                    echo
                    echo -e "${RED}Unable to contact the App Store search service.${RESET}"

                    pause
                    continue

                fi

                if ! echo "$response" | jq -e 'type == "array"' >/dev/null 2>&1; then

                    echo
                    echo -e "${RED}Unexpected response from Apple.${RESET}"

                    pause
                    continue

                fi

                local result_count
                result_count=$(echo "$response" | jq 'length')

                if [[ "$result_count" -eq 0 ]]; then

                    echo
                    echo -e "${YELLOW}No results found for \"${search_term}\".${RESET}"

                    pause
                    continue

                fi

                select_search_result "$response" "$platform"

                local result_action=$?

                if [[ "$result_action" -eq 2 ]]; then
                    continue
                fi
                ;;

            2)

                choose_platform "$platform"

                platform="$CHOSEN_PLATFORM"
                ;;

            3)

                view_selected_apps
                ;;

            4)

                remove_selected_app
                ;;

            5)

                create_csv

                if [[ $? -eq 0 ]]; then

                    > "$SELECTED_APPS_FILE"

                    return

                fi
                ;;

            *)

                echo
                echo -e "${YELLOW}Invalid selection.${RESET}"

                pause
                ;;

        esac

    done
}


# -----------------------------------------------------------------------------
# CSV creation
# -----------------------------------------------------------------------------

create_csv() {

    local count
    count=$(selected_count)

    if [[ "$count" -eq 0 ]]; then

        echo
        echo -e "${YELLOW}No apps have been selected.${RESET}"

        pause

        return 1

    fi

    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    local output_file
    output_file="${OUTPUT_DIRECTORY}/BundleID-Lookup_${timestamp}.csv"

    jq -s -r '

        (
            [
                "App Name",
                "Platform",
                "Bundle ID",
                "App Store ID",
                "Developer",
                "Version",
                "Minimum OS",
                "App Store URL",
                "External Version ID"
            ]
            | @csv
        ),

        (
            .[] |

            [
                .name,
                (.platforms | join(", ")),
                .bundleId,
                .appStoreId,
                .developer,
                .version,
                .minimumOS,
                .appStoreURL,
                (.externalVersionId // "")
            ]

            | @csv
        )

    ' "$SELECTED_APPS_FILE" > "$output_file"

    if [[ $? -ne 0 ]]; then

        echo
        echo -e "${RED}Unable to create CSV.${RESET}"

        pause

        return 1

    fi

    clear_screen

    echo -e "${GREEN}${BOLD}CSV Created Successfully${RESET}"
    echo
    echo -e "${WHITE}${output_file}${RESET}"
    echo
    echo "${count} app(s) exported."

    pause

    return 0
}


# -----------------------------------------------------------------------------
# Change default platform
# -----------------------------------------------------------------------------

change_default_platform() {

    choose_platform "$DEFAULT_PLATFORM"

    DEFAULT_PLATFORM="$CHOSEN_PLATFORM"
}


# -----------------------------------------------------------------------------
# Main menu
# -----------------------------------------------------------------------------

app_store_menu() {

    while true; do

        clear
        print_title

        echo -e "${CYAN}${BOLD}App Store Apps${RESET}"
        echo

        printf "  %bStore:%b              %s (%s)\n" \
            "$BOLD" "$RESET" \
            "$STORE_NAME" \
            "$STORE_CODE"

        printf "  %bDefault Platform:%b   %s\n" \
            "$BOLD" "$RESET" \
            "$(platform_display_name "$DEFAULT_PLATFORM")"

        printf "  %bCSV Directory:%b      %s\n" \
            "$BOLD" "$RESET" \
            "$OUTPUT_DIRECTORY"

        echo
        MENU_ROW=0
        print_menu_option "  [1] Start Search"
        print_menu_option "  [2] Change Store"
        print_menu_option "  [3] Change Default Platform"
        print_menu_option "  [4] Change CSV Output Directory"
        print_menu_option "  [b] Back to main menu"
        print_menu_option "  [h] Help"
        echo

        read -r -p "Choose an option: " choice

        case "$choice" in
            [Hh]) help_menu; continue ;;

            1)
                perform_search
                ;;

            2)
                change_store
                ;;

            3)
                change_default_platform
                ;;

            4)
                change_output_directory
                ;;

            [Bb]) return ;;

            *)

                echo
                echo -e "${YELLOW}Invalid selection.${RESET}"

                pause
                ;;

        esac

    done
}


# -----------------------------------------------------------------------------
# Start
# -----------------------------------------------------------------------------

# Search the three application locations without descending into app bundles.
print_local_search_locations() {
    printf '%bSearch folders:%b\n' "$BOLD" "$RESET"
    printf '  %s\n' /Applications /System/Applications /System/Cryptexes/App/System/Applications
    echo
}

scan_local_apps() {
    local app name root
    for root in /Applications /System/Applications /System/Cryptexes/App/System/Applications; do
        [[ -d "$root" ]] || continue
        /usr/bin/find -P "$root" -type d -name '*.app' -prune -print0
    done |
    while IFS= read -r -d '' app; do
        name="${app##*/}"
        name="${name%.app}"
        jq -cn --arg name "$name" --arg path "$app" '{name:$name,path:$path}'
    done | jq -s 'unique_by(.path) | sort_by(.name | ascii_downcase)'
}

signature_field() {
    printf '%s\n' "$1" | /usr/bin/sed -n "s/^$2=//p" | /usr/bin/head -n 1
}

inspect_local_app() {
    local app="$1" name executable raw arch arches slice hash team signing state verified version bundle designated_requirement rows='[]'
    name="${app##*/}"; name="${name%.app}"
    # -r- asks codesign to display the app's internal designated requirement
    # alongside the signature fields already collected by this command.
    raw=$(/usr/bin/codesign -dvvv -r- "$app" 2>&1)
    executable=$(signature_field "$raw" Executable)
    designated_requirement=$(printf '%s\n' "$raw" | /usr/bin/sed -n \
        's/^designated => //p' | /usr/bin/head -n 1)
    if [[ -z "$executable" ]]; then
        local executable_name
        executable_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist" 2>/dev/null)
        if [[ -n "$executable_name" && -f "$app/Contents/MacOS/$executable_name" ]]; then
            executable="$app/Contents/MacOS/$executable_name"
        fi
    fi
    version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null)
    bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null)
    verified="Unverified"
    if /usr/bin/codesign --verify --strict --all-architectures "$app" >/dev/null 2>&1; then
        verified="Valid"
    fi
    arches=""
    if [[ -n "$executable" && -f "$executable" ]]; then
        arches=$(/usr/bin/lipo -archs "$executable" 2>/dev/null)
    fi
    [[ -z "$arches" ]] && arches="Unknown"
    for arch in $arches; do
        if [[ "$arch" == Unknown ]]; then
            slice="$raw"
        else
            slice=$(/usr/bin/codesign -dvvv --arch "$arch" "$app" 2>&1)
        fi
        hash=$(signature_field "$slice" CDHash)
        team=$(signature_field "$slice" TeamIdentifier)
        signing=$(signature_field "$slice" Identifier)
        [[ "$team" == 'not set' ]] && team=""
        state="Unknown"
        # Missing team identifiers alone never imply Apple signing.
        if [[ "$verified" == Valid && "$arch" != Unknown ]]; then
            if /usr/bin/codesign --verify --arch "$arch" -R '=anchor apple' "$app" >/dev/null 2>&1; then
                state="Apple"
                [[ -z "$team" ]] && team='*APPLE*'
            elif /usr/bin/codesign --verify --arch "$arch" -R '=anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists' "$app" >/dev/null 2>&1; then
                state="DeveloperID"
            elif /usr/bin/codesign --verify --arch "$arch" -R '=anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.9] exists' "$app" >/dev/null 2>&1; then
                state="AppStore"
            fi
        fi
        rows=$(printf '%s' "$rows" | jq -c \
            --arg name "$name" --arg path "$app" --arg executable "$executable" \
            --arg bundle "$bundle" --arg version "$version" --arg arch "$arch" \
            --arg hash "$hash" --arg team "$team" --arg signing "$signing" \
            --arg designated_requirement "$designated_requirement" \
            --arg state "$state" --arg verified "$verified" \
            '. + [{name:$name,path:$path,executable:$executable,bundleId:$bundle,version:$version,
                architecture:$arch,CDHash:$hash,TeamID:$team,SigningID:$signing,
                DesignatedRequirement:$designated_requirement,PathPrefix:($path + "/"),
                SigningState:$state,verification:$verified}]')
    done
    LOCAL_INSPECTION="$rows"
}

show_local_details() {
    local visible_inspection
    if [[ "$1" == all ]]; then
        visible_inspection="$LOCAL_INSPECTION"
    else
        visible_inspection=$(printf '%s' "$LOCAL_INSPECTION" | jq -c '
        [.[] | select(.architecture | startswith("arm"))] as $arm |
        if ($arm | length) > 0 then $arm else . end')
    fi
    printf '%s' "$visible_inspection" | jq -r '.[0].name' | while IFS= read -r name; do
        printf '%b%b%s%b\n' "$CYAN" "$BOLD" "$name" "$RESET"
    done
    printf '%s' "$visible_inspection" | jq -r '
        def value: if . == "" then "Unavailable" else . end;
        .[0] | "App path: \(.path)\nExecutable: \(.executable | value)
Bundle ID: \(.bundleId | value)\nVersion: \(.version | value)
Signature verification: \(.verification)\nPathPrefix (suggested): \(.PathPrefix)
Designated Requirement: \(.DesignatedRequirement | value)"
    ' | format_app_attributes
    printf '\n'
    printf '%s' "$visible_inspection" | jq -r '
        def value: if . == "" then "Unavailable" else . end;
        .[] | "Architecture: \(.architecture)\nCDHash: \(.CDHash | value)
TeamID: \(.TeamID | value)\nSigningID: \(.SigningID | value)\nSigningState: \(.SigningState)\n"
    ' | format_app_attributes
    if [[ "$visible_inspection" != "$(printf '%s' "$LOCAL_INSPECTION" | jq -c .)" ]]; then
        echo "Intel details are available in Show ARM and Intel details and CSV exports."
    elif ! printf '%s' "$visible_inspection" | jq -e 'any(.[]; .architecture | startswith("arm"))' >/dev/null; then
        echo "No Apple Silicon slice found; showing the available architecture details."
    fi
    echo "PathPrefix is a suggested app-folder restriction, not a signature field."
    echo "Details describe the main executable; embedded helpers are not inspected."
    if printf '%s' "$visible_inspection" | jq -e 'any(.[]; .SigningState == "Unknown")' >/dev/null; then
        echo "SigningState could not be established. Unknown is not a declaration value."
    fi
}

local_app_menu() {
    local app="$1" choice detail_view=0
    echo "Reading signing information..."
    inspect_local_app "$app"
    while true; do
        clear_screen
        printf "%bYou've selected%b\n\n" "$BOLD" "$RESET"
        if (( detail_view )); then show_local_details all; else show_local_details; fi
        printf '\n%bWhat would you like to do with this app?%b\n\n' "$BOLD" "$RESET"
        MENU_ROW=0
        print_menu_option "  [1] Add to CSV"
        if (( ! detail_view )); then print_menu_option "  [2] Show ARM and Intel details"; fi
        print_menu_option "  [s] Search again"
        if (( detail_view )); then print_menu_option "  [b] Back to selected app"; else print_menu_option "  [b] Back to results"; fi
        print_menu_option "  [h] Help"
        echo
        read -r -p "Choice: " choice || return 1
        case "$choice" in
            [Hh]) help_menu; continue ;;
            1)
                printf '%s' "$LOCAL_INSPECTION" | jq -c '.[]' >> "$LOCAL_SELECTED_FILE"
                echo "App added to CSV selection (one row per architecture)."
                pause
                return 0 ;;
            2) detail_view=1 ;;
            [Ss]) return 2 ;;
            [Bb]) if (( detail_view )); then detail_view=0; else return 1; fi ;;
            *) echo "Invalid selection."; pause ;;
        esac
    done
}

local_search_results() {
    local response="$1" count page=0 pages choice index action
    count=$(printf '%s' "$response" | jq length)
    pages=$(( (count + RESULTS_PER_PAGE - 1) / RESULTS_PER_PAGE ))
    while true; do
        clear_screen
        printf '%b%bLocal Mac Apps — Search Results%b\n\n' "$CYAN" "$BOLD" "$RESET"
        print_local_search_locations
        print_result_summary "$count" "$count" "" "$page" "$pages"
        echo
        printf '%s' "$response" | jq -r --argjson start "$((page * RESULTS_PER_PAGE))" \
            --argjson size "$RESULTS_PER_PAGE" --arg cyan "$(printf '%b' "$CYAN")" \
            --arg bold "$(printf '%b' "$BOLD")" --arg reset "$(printf '%b' "$RESET")" '
            .[$start:$start+$size] | to_entries[] |
            "\(.key+$start+1). \($cyan)\($bold)\(.value.name)\($reset)\n   \($bold)Path:\($reset) \(.value.path)\n"'
        print_result_summary "$count" "$count" "" "$page" "$pages"
        printf '\n%bEnter result number to select%b\n' "$BOLD" "$RESET"
        MENU_ROW=0
        (( page > 0 )) && print_menu_option "  [p] Previous page"
        (( page < pages - 1 )) && print_menu_option "  [n] Next page"
        print_menu_option "  [s] Search again"
        print_menu_option "  [b] Back to local menu"
        print_menu_option "  [h] Help"
        read -r -p "Choice: " choice || return
        case "$choice" in
            [Hh]) help_menu; continue ;;
            [Nn]) (( page < pages - 1 )) && page=$((page + 1)) ;;
            [Pp]) (( page > 0 )) && page=$((page - 1)) ;;
            [SsBb]) return ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ && ${#choice} -le 8 ]] && (( 10#$choice >= 1 && 10#$choice <= count )); then
                    index=$((10#$choice - 1))
                    local_app_menu "$(printf '%s' "$response" | jq -r --argjson i "$index" '.[$i].path')"
                    action=$?
                    [[ "$action" -ne 1 ]] && return
                else
                    echo "Invalid selection."; pause
                fi ;;
        esac
    done
}

export_local_csv() {
    local output_file
    if [[ ! -s "$LOCAL_SELECTED_FILE" ]]; then
        echo "No local apps selected."; pause; return
    fi
    output_file=$(mktemp "${OUTPUT_DIRECTORY}/Local-Mac-Apps_$(date +%Y-%m-%d_%H-%M-%S)_XXXXXX") || return
    if jq -sr '
        ["App Name","App Path","Executable Path","Bundle ID","Version","Architecture","CDHash","TeamID","SigningID","Designated Requirement","PathPrefix (suggested)","SigningState","Signature Verification"],
        (.[] | [.name,.path,.executable,.bundleId,.version,.architecture,.CDHash,.TeamID,.SigningID,.DesignatedRequirement,.PathPrefix,.SigningState,.verification]) | @csv
        ' "$LOCAL_SELECTED_FILE" > "$output_file" && mv "$output_file" "$output_file.csv"; then
        : > "$LOCAL_SELECTED_FILE"
        clear_screen
        printf '%b%bCSV Created Successfully%b\n\n%s\n' "$GREEN" "$BOLD" "$RESET" "$output_file.csv"
    else
        echo "Unable to create CSV. Your selection has been kept."
        rm -f "$output_file"
    fi
    pause
}

local_apps_menu() {
    local choice term response catalogue count
    while true; do
        clear
        print_binary_title
        printf '%b%bLocal Mac Apps%b\n\n' "$CYAN" "$BOLD" "$RESET"
        count=$(jq -sr 'map(.path) | unique | length' "$LOCAL_SELECTED_FILE")
        print_local_search_locations
        printf '%bSelected apps:%b %s\n%bCSV Directory:%b %s\n\n' \
            "$BOLD" "$RESET" "$count" "$BOLD" "$RESET" "$OUTPUT_DIRECTORY"
        MENU_ROW=0
        print_menu_option "  [1] Search"
        print_menu_option "  [2] Browse all local apps"
        print_menu_option "  [3] View selected apps"
        print_menu_option "  [4] Remove selected app"
        print_menu_option "  [5] Finish and create CSV"
        print_menu_option "  [6] Change CSV Output Directory"
        print_menu_option "  [b] Back to main menu"
        print_menu_option "  [h] Help"
        IFS= read -r -p "Enter an app name or choose an option: " choice || return
        case "$choice" in
            [Hh]) help_menu; continue ;;
            '') continue ;;
            1) IFS= read -r -p "Search for a local app: " term || return; [[ -z "$term" ]] && continue ;;
            2) term="" ;;
            3)
                clear_screen
                printf '%bSelected Local Apps%b\n\n' "$BOLD" "$RESET"
                jq -sr 'unique_by(.path) | .[] | "\(.name)\n   Path: \(.path)\n"' "$LOCAL_SELECTED_FILE"
                pause; continue ;;
            4) remove_local_app; continue ;;
            5) export_local_csv; continue ;;
            6) change_output_directory; continue ;;
            [Bb]) return ;;
            *) term="$choice" ;;
        esac
        echo "Searching application folders..."
        catalogue=$(scan_local_apps)
        response=$(printf '%s' "$catalogue" | jq -c --arg term "$term" \
            'map(select(.name | ascii_downcase | contains($term | ascii_downcase)))')
        if [[ $(printf '%s' "$response" | jq length) == 0 ]]; then
            echo "No local apps found."; pause
        else
            local_search_results "$response"
        fi
    done
}

main_menu() {
    local choice
    while true; do
        clear
        print_settings_title
        printf '%bWhat would you like to look up?%b\n\n' "$BOLD" "$RESET"
        MENU_ROW=0
        print_menu_option "  [1] App Store Apps"
        print_menu_option "  [2] Local Mac Apps"
        print_menu_option "  [h] Help"
        print_menu_option "  [q] Exit"
        read -r -p "Choose an option: " choice || return
        case "$choice" in
            [Hh]) help_menu; continue ;;
            1) app_store_menu ;;
            2) local_apps_menu ;;
            [Qq]) if confirm_exit; then return; fi ;;
            *) echo "Invalid selection."; pause ;;
        esac
    done
}

apple_preinstalled_data() {
    cat <<'APPLE_APPS_JSON'
[
  {
    "name": "App Store",
    "bundleId": "com.apple.AppStore",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "App Store Connect",
    "bundleId": "com.apple.AppStoreConnect",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Apple Business",
    "bundleId": "com.apple.business-essentials",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Apple Configurator",
    "bundleId": "com.apple.ios.configurator",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Apple Store",
    "bundleId": "com.apple.store.Jolly",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Apple Vision Pro",
    "bundleId": "com.apple.visionproapp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Barcode Scanner",
    "bundleId": "com.apple.BarcodeScanner",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Books",
    "bundleId": "com.apple.iBooks",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Calculator",
    "bundleId": "com.apple.calculator",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Calendar",
    "bundleId": "com.apple.mobilecal",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Camera",
    "bundleId": "com.apple.camera",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Classical",
    "bundleId": "com.apple.music.classical",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Classroom",
    "bundleId": "com.apple.classroom",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Clips",
    "bundleId": "com.apple.clips",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Clock",
    "bundleId": "com.apple.mobiletimer",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Compass",
    "bundleId": "com.apple.compass",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Contacts",
    "bundleId": "com.apple.MobileAddressBook",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Developer",
    "bundleId": "developer.apple.wwdc-Release",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "FaceTime",
    "bundleId": "com.apple.facetime",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Files",
    "bundleId": "com.apple.DocumentsApp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Final Cut Camera",
    "bundleId": "com.apple.FinalCutApp.companion",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Final Cut Pro",
    "bundleId": "com.apple.FinalCutApp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Find My",
    "bundleId": "com.apple.findmy",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Fitness",
    "bundleId": "com.apple.Fitness",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Freeform",
    "bundleId": "com.apple.freeform",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Games",
    "bundleId": "com.apple.games",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "GarageBand",
    "bundleId": "com.apple.mobilegarageband",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Health",
    "bundleId": "com.apple.Health",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Home",
    "bundleId": "com.apple.Home",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "iCloud Drive",
    "bundleId": "com.apple.iCloudDriveApp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "iMovie",
    "bundleId": "com.apple.iMovie",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Invites",
    "bundleId": "com.apple.rsvp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "iTunes Store",
    "bundleId": "com.apple.MobileStore",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Journal",
    "bundleId": "com.apple.journal",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Keynote",
    "bundleId": "com.apple.Keynote",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Logic Pro",
    "bundleId": "com.apple.mobilelogic",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Logic Remote",
    "bundleId": "com.apple.musicapps.remote",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Magnifier",
    "bundleId": "com.apple.Magnifier",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Mail",
    "bundleId": "com.apple.mobilemail",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Maps",
    "bundleId": "com.apple.Maps",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Measure",
    "bundleId": "com.apple.measure",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Messages",
    "bundleId": "com.apple.MobileSMS",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Music",
    "bundleId": "com.apple.Music",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "News",
    "bundleId": "com.apple.news",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Notes",
    "bundleId": "com.apple.mobilenotes",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Numbers",
    "bundleId": "com.apple.Numbers",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Pages",
    "bundleId": "com.apple.Pages",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Passwords",
    "bundleId": "com.apple.Passwords",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Phone",
    "bundleId": "com.apple.mobilephone",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Photo Booth",
    "bundleId": "com.apple.Photo-Booth",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Photomator",
    "bundleId": "com.pixelmatorteam.pixelmator.touch.x.photo",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Photos",
    "bundleId": "com.apple.mobileslideshow",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Pixelmator Classic iOS",
    "bundleId": "com.pixelmatorteam.pixelmator.touch",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Playground",
    "bundleId": "com.apple.GenerativePlaygroundApp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Podcasts",
    "bundleId": "com.apple.podcasts",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Preview",
    "bundleId": "com.apple.Preview",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Reality Composer",
    "bundleId": "com.apple.RealityComposer",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Reminders",
    "bundleId": "com.apple.reminders",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Research",
    "bundleId": "com.apple.Research",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Safari",
    "bundleId": "com.apple.mobilesafari",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Schoolwork",
    "bundleId": "com.apple.schoolwork.ClassKitApp",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Settings",
    "bundleId": "com.apple.Preferences",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Shazam",
    "bundleId": "com.shazam.Shazam",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Shortcuts",
    "bundleId": "com.apple.shortcuts",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Sports",
    "bundleId": "com.apple.sports",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Stocks",
    "bundleId": "com.apple.stocks",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Swift Playground",
    "bundleId": "com.apple.Playgrounds",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "TestFlight",
    "bundleId": "com.apple.TestFlight",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Tips",
    "bundleId": "com.apple.tips",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Translate",
    "bundleId": "com.apple.Translate",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "TV",
    "bundleId": "com.apple.tv",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Voice Memos",
    "bundleId": "com.apple.VoiceMemos",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Wallet",
    "bundleId": "com.apple.Passbook",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Watch",
    "bundleId": "com.apple.Bridge",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  },
  {
    "name": "Weather",
    "bundleId": "com.apple.weather",
    "developer": "Apple",
    "platforms": [
      "iPhone / iPad (Apple reference)"
    ],
    "appStoreId": null,
    "version": null,
    "minimumOS": null,
    "appStoreURL": null,
    "externalVersionId": null
  }
]
APPLE_APPS_JSON
}

# This reference list is deliberately embedded, so it is available offline.
# Verified against iPhone 17 / iPad Pro built-in app lists on 2026-09-11.
# Image Playground is also retained, subject to Apple Intelligence availability.
apple_builtin_data() {
    apple_preinstalled_data | jq --argjson names '
["App Store", "Apple Store", "Books", "Calculator", "Calendar", "Camera", "Clock", "Compass", "Contacts", "FaceTime", "Files", "Find My", "Fitness", "Freeform", "Games", "GarageBand", "Health", "Home", "iMovie", "Invites", "iTunes Store", "Journal", "Keynote", "Magnifier", "Mail", "Maps", "Measure", "Messages", "Music", "News", "Notes", "Numbers", "Pages", "Passwords", "Phone", "Photo Booth", "Photos", "Playground", "Podcasts", "Preview", "Reminders", "Safari", "Settings", "Shortcuts", "Stocks", "Swift Playground", "Tips", "Translate", "TV", "Voice Memos", "Wallet", "Watch", "Weather"]
' '
        map(select(.name as $name | $names | index($name)))
    '
}

apple_preinstalled_menu() {
    local apps count choice index app bundle show_all=0 redraw=1
    while true; do
    if (( redraw )); then
        if (( show_all )); then
            apps=$(apple_preinstalled_data)
        else
            apps=$(apple_builtin_data)
        fi
        count=$(printf '%s' "$apps" | jq length)
        clear_screen
    if (( show_all )); then
        printf '%b%bAll Apple Apps — iPhone and iPad%b\n' "$CYAN" "$BOLD" "$RESET"
    else
        printf '%b%bBuilt-in / Preinstalled Apple Apps — iPhone and iPad%b\n' "$CYAN" "$BOLD" "$RESET"
    fi
    printf '%s apps in this list.\n\n' "$count"
    printf '%s' "$apps" | jq -r --arg bold "$(printf '%b' "$BOLD")" \
        --arg cyan "$(printf '%b' "$CYAN")" --arg reset "$(printf '%b' "$RESET")" '
        to_entries[] | (if .key % 2 == 1 then $cyan else $reset end) as $colour |
        "\($colour)\(.key+1). \($bold)\(.value.name):\($reset)\($colour) \(.value.bundleId)\(if .value.name == "Playground" then " (Image Playground; requires compatible Apple Intelligence device/settings)" else "" end)\($reset)"'
    cat <<'NOTICE'

Source: https://support.apple.com/en-gb/guide/deployment/depece748c41/web
List verified against Apple's documentation on 11 September 2026.
Covers iPhone and iPad apps; not all are preinstalled on every device.
This reference list is independent of your chosen store and search platform.
Built-in selection checked against iPhone 17 and iPad Pro specifications:
https://www.apple.com/iphone-17/specs/
https://www.apple.com/ipad-pro/specs/
Image Playground is included where Apple Intelligence is supported.
Availability varies by device, OS version and region; this is not an inventory
of what is currently installed on a particular device.
NOTICE
    printf '\n%bEnter a number to add an app to your CSV selection.%b\n' "$BOLD" "$RESET"
    MENU_ROW=0
    if (( show_all )); then
        print_menu_option "  [a] Show built-in apps only"
    else
        print_menu_option "  [a] Show all Apple apps"
    fi
    print_menu_option "  [b] Back to search menu"
    print_menu_option "  [h] Help"
        redraw=0
    fi
        echo
        IFS= read -r -p "Choose an app number, or [b] Back: " choice || return
        case "$choice" in
            [Aa]) show_all=$((1 - show_all)); redraw=1; continue ;;
            [Bb]) return ;;
            [Hh]) help_topic 7; continue ;;
            '') continue ;;
        esac
        if [[ "$choice" =~ ^[0-9]+$ && ${#choice} -le 8 ]] && (( 10#$choice >= 1 && 10#$choice <= count )); then
            index=$((10#$choice - 1))
            app=$(printf '%s' "$apps" | jq -c --argjson index "$index" '.[$index]')
            bundle=$(printf '%s' "$app" | jq -r .bundleId)
            if jq -se --arg bundle "$bundle" 'any(.[]; .bundleId == $bundle)' "$SELECTED_APPS_FILE" >/dev/null; then
                echo "Already selected; no duplicate added."
            else
                printf '%s\n' "$app" >> "$SELECTED_APPS_FILE"
                printf 'Added %s. Selected apps: %s\n' "$(printf '%s' "$app" | jq -r .name)" "$(selected_count)"
            fi
        else
            echo "Please enter a number from 1 to $count, [a] Switch list, [b] Back, or [h] Help."
        fi
    done
}

remove_local_app() {
    local apps count choice index path temp
    while true; do
        clear_screen
        printf '%b%bRemove Selected Local App%b\n\n' "$CYAN" "$BOLD" "$RESET"
        apps=$(jq -sc 'unique_by(.path) | sort_by(.name | ascii_downcase)' "$LOCAL_SELECTED_FILE")
        count=$(printf '%s' "$apps" | jq length)
        if (( count == 0 )); then echo "No local apps selected."; pause; return; fi
        printf '%s' "$apps" | jq -r --arg bold "$(printf '%b' "$BOLD")" \
            --arg cyan "$(printf '%b' "$CYAN")" --arg reset "$(printf '%b' "$RESET")" '
            to_entries[] | "\(.key+1). \($cyan)\($bold)\(.value.name)\($reset)\n   Path: \(.value.path)\n"'
        MENU_ROW=0
        print_menu_option "  [b] Back to local menu"
        print_menu_option "  [h] Help"
        read -r -p "Select an app to remove: " choice || return
        case "$choice" in
            [Bb]) return ;;
            [Hh]) help_menu; continue ;;
        esac
        if [[ "$choice" =~ ^[0-9]+$ && ${#choice} -le 8 ]] && (( 10#$choice >= 1 && 10#$choice <= count )); then
            index=$((10#$choice - 1))
            path=$(printf '%s' "$apps" | jq -r --argjson i "$index" '.[$i].path')
            temp=$(mktemp) || return
            if jq -c --arg path "$path" 'select(.path != $path)' "$LOCAL_SELECTED_FILE" > "$temp"; then
                cat "$temp" > "$LOCAL_SELECTED_FILE"
                echo "App removed, including all architecture rows."
            else
                echo "Unable to remove app."
            fi
            rm -f "$temp"
            pause
        else
            echo "Invalid selection."; pause
        fi
    done
}

confirm_exit() {
    local answer
    if [[ -s "$SELECTED_APPS_FILE" || -s "$LOCAL_SELECTED_FILE" ]]; then
        echo "There are unexported app selections."
        read -r -p "Discard them and exit? [y/N]: " answer || return 1
        [[ "$answer" == [Yy] ]] || return 1
    fi
    echo "Goodbye."
    return 0
}

# Help is embedded so it remains available without a separate manual or network.
print_usage() {
    printf 'App Settings Lookup %s\n' "$SCRIPT_VERSION"
    cat <<'HELP'
A utility to find app identifiers and signing details for App Settings.

Usage:
  /bin/bash appSettingsUtility.sh           Open the interactive menus
  /bin/bash appSettingsUtility.sh --version Show the installed version
  /bin/bash appSettingsUtility.sh --help    Show this quick guide
  /bin/bash appSettingsUtility.sh --manual  Print the complete manual

Choose App Store Apps for online app metadata, or Local Mac Apps for
installed executable signing details. Use [h] for help within the menus.

App Store search: type an app name or choose a numbered menu action.
Use [1] Search first for names that conflict with menu shortcuts.
Local search also supports [2] Browse all local apps.
Use ApplePreInstalled in App Store search for the built-in reference list.
Navigation uses [b] Back, [s] Search again, [h] Help, and [q] Exit on the
opening menu. Back preserves selections; Exit asks before discarding them.

Selecting a result does not add it to CSV. Choose Add to CSV explicitly,
then Finish and create CSV to write the file. Selections last only until
this script exits. App Store and local selections are kept separately.

This tool shows and exports information. It does not create, install,
or enforce declarations, and it does not launch inspected applications.
HELP
}

help_topic() {
    case "$1" in
        1)
            cat <<'HELP'
GETTING STARTED

App Store Apps looks up online catalogue information for your chosen store.
Local Mac Apps inspects applications installed on this Mac.

Enter an app name at a search menu, or choose one of its menu shortcuts.
For a name such as "2", "b", or "h", choose [1] Search, then enter the name.
Local name searches and developer filters match partial names without
regard to case. App Store name results are ranked by Apple.

Results show five apps per page. Use [n]/[p] to change pages and enter the
result number to inspect an app. Selecting does not add it to CSV.

[s] Search again returns to the search menu, where menu actions work too.
[b] goes back one level and keeps your selections. Returning to results
preserves the current page. [q] exits from the opening menu and asks before
discarding unexported selections.
[h] Help is available in the main, mode, search, and selected-app menus.

The large headers identify the modes. Yellow dividers separate screens;
yellow numbers highlight counts, and cyan highlights app names.
HELP
            ;;
        2)
            cat <<'HELP'
APP STORE LOOKUP

Choose the store and platform before searching. All combines iPhone/iOS,
iPad, and Mac searches. Records with the same App Store ID are merged;
the platform labels reflect which search catalogues returned the app.
These labels are not a complete hardware compatibility assessment.

[f] Filter by developer narrows already-fetched results without another
request. [c] clears the filter. Changing a filter returns to page one.

Select an app, then choose Add to CSV or Show more detail.
Details are fetched by App Store ID using the selected country, only when
needed. Adding also fetches details so the CSV can include a version ID.
Successful detail lookups are cached for the current result list.

App Store ID identifies the app; External Version ID identifies a version
in Apple's catalogue. They are different values, and neither is a CDHash.
If the extra lookup fails, you can still add the app; unavailable external
version IDs are blank in CSV. Detail availability depends on Apple's data.
HELP
            ;;
        3)
            cat <<'HELP'
LOCAL MAC APPS

Search covers these folders, including organisational subfolders:
  /Applications
  /System/Applications
  /System/Cryptexes/App/System/Applications

The scan stops at each .app bundle. Embedded helpers, other executables,
and apps elsewhere (such as ~/Applications) are not listed separately.
The selected app's main executable is inspected without launching it.

The normal view prefers Apple Silicon (arm64/arm64e). If there is no ARM
slice, the available architecture is shown. Show ARM and Intel details
shows the concise fields for all discovered architectures, not a raw dump.

CSV keeps one row per architecture, including Intel x86_64 where present.
A universal app can have different CDHashes for its ARM and Intel slices.
Intel binaries can still be relevant on macOS 27 through Rosetta.

An unavailable or unverified value is reported rather than guessed.
HELP
            ;;
        4)
            cat <<'HELP'
SIGNING FIELDS

CDHash: identifies the signed code for a particular architecture. Updates
can change it. It is not the App Store External Version ID.
TeamID: the signing team identifier. Verified Apple-signed code with no
team identifier uses the literal token *APPLE*. A com.apple.* name alone
is not proof of Apple signing. Existing team identifiers are preserved.
SigningID: the Identifier in the code signature; it is not assumed to be
the same as the app bundle's identifier.
Designated Requirement: Apple's expression for recognising this signed
app, reported by codesign. It is shown once because it identifies the app,
rather than an individual ARM or Intel slice.
PathPrefix (suggested): the app folder with a trailing slash. This is an
optional path restriction you could choose, not data from the signature.

SigningState describes a signing category, not signature validity:
  Apple        Apple signing
  AppStore     Mac App Store signing
  DeveloperID  Developer ID signing
  TestFlight   TestFlight distribution
  Enterprise   Enterprise distribution
  All          No restriction to a particular signing category

This script detects Apple, AppStore, and DeveloperID when verification
supports it. Other or unconfirmed states display Unknown. Unknown is not
a declaration value. Signature verification is shown separately and does
not guarantee that an app is safe, notarized, or permitted by policy.
HELP
            ;;
        5)
            cat <<'HELP'
CSV EXPORTS AND SELECTIONS

Add to CSV queues an app; it does not immediately create a file.
Finish and create CSV writes a timestamped file in the CSV directory.
The directory setting is shared by both lookup modes and can be changed
in their menus. A successful export clears that mode's selection.

App Store CSV includes name, platforms, bundle ID, App Store ID, developer,
version, minimum OS, App Store URL, and External Version ID.

Local CSV includes name, app and executable paths, bundle ID, version,
architecture, CDHash, TeamID, SigningID, designated requirement, suggested
PathPrefix, SigningState, and signature verification. A universal app can
produce multiple rows; its designated requirement is repeated in each row.
Unknown SigningState is retained as Unknown; unavailable IDs are blank.

View selected apps shows the queue. Both modes let you remove an app.
Removing a local app removes all of its architecture rows together.
Ordinary lookups can add duplicate rows. ApplePreInstalled skips bundle
IDs already in the App Store selection.

Selections are temporary, separate for each mode, and lost on exit.
Export before exiting. A CSV is reference data, not a ready-to-use
App Settings declaration; choose the fields appropriate to your rule.
HELP
            ;;
        6)
            cat <<'HELP'
TROUBLESHOOTING

No App Store match: check the store, platform, spelling, and developer
filter. Try All, or a known App Store name. Apple searches may return
related apps, and results depend on the selected storefront.

No local match: check that the app is in a listed search folder. Use
Browse all local apps. Embedded helpers are not separate results.

SigningState Unknown or TeamID Unavailable: the signature may not match a
supported category, verification may fail, or the environment may not
trust the certificate chain. Do not replace a missing team with *APPLE*
unless Apple signing has been verified. Unsigned code is not Apple code.

CSV failed: choose an existing writable output directory. Local export
retains its selection if writing fails. Check the output before exiting.

Colours: output uses ANSI styling when attached to a terminal. Redirected
output is plain text. Block-letter headers need a Unicode-capable font.

Requirements: macOS Bash 3.2, jq and curl; local inspection also uses macOS
codesign, lipo and PlistBuddy. Local lookup needs no App Store request.
HELP
            ;;
        7)
            cat <<'HELP'
APPLEPREINSTALLED REFERENCE LIST

In App Store search, enter ApplePreInstalled (any letter case) to open the
built-in/preinstalled selection (53 entries). [a] switches to the complete
75-entry Apple reference list or back to the shorter list. Each view has
its own numbering: use the numbers in the currently displayed list.
Selections are retained when switching views; duplicates are still skipped.

The shorter list uses Apple's iPhone 17 and iPad Pro built-in app lists,
plus Image Playground where Apple Intelligence is supported. Availability
varies by device, OS version and region. Your current store and platform
do not filter either list.

Enter a number to add that app directly to the App Store CSV selection.
Then enter another number. The list stays open until [b] Back. Return with
no number simply prompts again; repeated selections do not add duplicates.
[h] prints this guide without clearing the list.

Export later using Finish and create CSV in App Store search. Version,
App Store ID and External Version ID are blank: this list supplies names
and bundle IDs, without extra network lookups or invented app metadata.

Source: https://support.apple.com/en-gb/guide/deployment/depece748c41/web
List verified against Apple's documentation on 11 September 2026.
The embedded snapshot does not update itself. Bundle ID case is preserved.
Apple's source also notes that certain Shortcut actions may require the
additional com.apple.ShortcutsActions identifier; that note is not a
separate app row in the list.
HELP
            ;;
    esac
}

help_menu() {
    local help_choice
    while true; do
        clear_screen
        printf '%b%bHelp & Manual%b\n\n' "$CYAN" "$BOLD" "$RESET"
        MENU_ROW=0
        print_menu_option "  [1] Getting started"
        print_menu_option "  [2] App Store lookup"
        print_menu_option "  [3] Local Mac Apps"
        print_menu_option "  [4] Signing fields explained"
        print_menu_option "  [5] CSV exports and selections"
        print_menu_option "  [6] Troubleshooting"
        print_menu_option "  [7] ApplePreInstalled reference list"
        print_menu_option "  [b] Back"
        echo
        read -r -p "Choose a topic: " help_choice || return
        case "$help_choice" in
            [1-7]) clear_screen; help_topic "$help_choice"; pause ;;
            [Bb]) return ;;
            *) echo "Invalid selection."; pause ;;
        esac
    done
}

case "${1:-}" in
    -v|--version) printf 'App Settings Utility %s\n' "$SCRIPT_VERSION"; exit 0 ;;
    -h|--help) print_usage; exit 0 ;;
    --manual)
        print_usage
        for topic in 1 2 3 4 5 6 7; do
            printf '\n============================================================\n\n'
            help_topic "$topic"
        done
        exit 0 ;;
esac

validate_dependencies
main_menu

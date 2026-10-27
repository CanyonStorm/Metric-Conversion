#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
application_name="MetricConversion"
installer_name="MetricConverter"
package_identifier="com.williamstpierre.MetricConversion"
version="${VERSION:-1.0.2}"
distribution_directory="$project_root/dist"
derived_data_directory="$(mktemp -d "$project_root/.installer-derived-data.XXXXXX")"
staging_directory="$(mktemp -d "$project_root/.installer-staging.XXXXXX")"
application_path="$derived_data_directory/Build/Products/Release/$application_name.app"
archive_directory="$staging_directory/Library/Application Support/MetricConverterInstaller"
archive_path="$archive_directory/$application_name.app.zip"
package_path="$distribution_directory/$installer_name-$version.pkg"

rm -rf "$distribution_directory"
mkdir -p "$distribution_directory"

build_arguments=(
    -project "$project_root/MetricConversion.xcodeproj"
    -scheme MetricConversion
    -configuration Release
    -derivedDataPath "$derived_data_directory"
    build
)

if [[ -n "${APPLICATION_SIGNING_IDENTITY:-}" ]]; then
    build_arguments+=(
        CODE_SIGN_STYLE=Manual
        "CODE_SIGN_IDENTITY=$APPLICATION_SIGNING_IDENTITY"
    )
else
    build_arguments+=(CODE_SIGNING_ALLOWED=NO)
fi

xcodebuild "${build_arguments[@]}"

if [[ -z "${APPLICATION_SIGNING_IDENTITY:-}" ]]; then
    xattr -cr "$application_path"
    codesign --force --deep --sign - "$application_path"
fi

mkdir -p "$archive_directory"
ditto -c -k --keepParent "$application_path" "$archive_path"

package_arguments=(
    --root "$staging_directory"
    --install-location /
    --identifier "$package_identifier"
    --version "$version"
    --scripts "$project_root/scripts/installer-scripts"
)

if [[ -n "${INSTALLER_SIGNING_IDENTITY:-}" ]]; then
    package_arguments+=(--sign "$INSTALLER_SIGNING_IDENTITY")
fi

pkgbuild "${package_arguments[@]}" "$package_path"

echo "Created installer: $package_path"
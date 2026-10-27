# Metric Converter

A macOS 13+ menu-bar utility for converting metric and imperial length units.

## Run it

Install full Xcode, select it as the active developer directory, then open [MetricConversion.xcodeproj](MetricConversion.xcodeproj) in Xcode. Choose the `MetricConversion` scheme and run it. The ruler icon appears in the menu bar; the app intentionally has no Dock icon.

The first launch from the built app registers Metric Converter to open at login. macOS may require approval in System Settings > General > Login Items.

## Tests

The conversion and persistence tests run with the Swift command-line tools:

```sh
swift test
```

`swift run` is useful for a quick UI preview, but login-item registration requires the signed `.app` produced by Xcode.

## Build an installer

Create a local installer package that installs Metric Converter in `/Applications`:

```sh
./scripts/create-installer.sh
```

The installer is written to `dist/MetricConverter-1.0.2.pkg`. Open it in Finder or run this command:

```sh
open dist/MetricConverter-1.0.2.pkg
```

The app inside the local installer is ad-hoc signed, but the installer package itself is unsigned. You can share `dist/MetricConverter-1.0.2.pkg` with friends on macOS 13 or later; because it is not notarized, Gatekeeper may block it. They can Control-click the downloaded package and choose **Open**, then, if macOS blocks the installed app on first launch, Control-click **Metric Converter** in Applications and choose **Open**.

To distribute it without Gatekeeper warnings, add a Developer ID Application certificate and a Developer ID Installer certificate, then build with:

```sh
APPLICATION_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
INSTALLER_SIGNING_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
./scripts/create-installer.sh
```

Notarization is also required before distributing the installer outside your own Mac.
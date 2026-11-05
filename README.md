# Metric Converter

Metric and imperial length conversion, with two separate implementations:

| Version | Location | Build / installation |
| --- | --- | --- |
| macOS 13+ menu-bar app (Swift / SwiftUI) | `Sources/MetricConversion/`, `Tests/MetricConversionTests/`, `MetricConversion.xcodeproj`, `Package.swift`, `scripts/` | Xcode and the macOS installer; instructions below |
| iPhone-friendly offline web app (HTML / CSS / JavaScript) | [`web/`](web/README.md) | Static hosting and Safari's Add to Home Screen; no Apple Developer membership |

The web app is self-contained: deploy only `web/public/`. Its tests and preview
tools live under `web/` as well. It does not change or use the Mac installer.
The implementations use the same units and conversion factors but do not sync
history or settings between devices.

The remaining sections describe the **macOS app**. For free web hosting, local
preview, tests, and iPhone installation, see the [web app instructions](web/README.md).

## Install

For end users installing the `.pkg` received by email, see the standalone [installation instructions](INSTALLATION.md).

## Run it

Install full Xcode, select it as the active developer directory, then open [MetricConversion.xcodeproj](MetricConversion.xcodeproj) in Xcode. Choose the `MetricConversion` scheme and run it. The ruler icon appears in the menu bar; the app intentionally has no Dock icon.

The first launch from the built app registers Metric Converter to open at login. macOS may require approval in System Settings > General > Login Items. Open the menu-bar panel's settings to configure units, precision, and launch at login; use **About** for app details or **Quit Metric Converter** to exit.

The macOS converter accepts decimal values and fractions such as `3/32` or `1 3/32`.

## Version 1.1.0

- Both apps accept simple and mixed fractions alongside decimal input.
- The macOS panel includes About with the installed version and Quit Metric
  Converter (Command-Q while the panel is open).
- The web app includes fraction input guidance and an updated offline cache.

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

The installer is written to `dist/MetricConverter-1.1.0.pkg`. Open it in Finder or run this command:

```sh
open dist/MetricConverter-1.1.0.pkg
```

The app inside the local installer is ad-hoc signed, but the installer package itself is unsigned. You can share `dist/MetricConverter-1.1.0.pkg` with friends on macOS 13 or later; because it is not notarized, Gatekeeper may block it. They can Control-click the downloaded package and choose **Open**, then, if macOS blocks the installed app on first launch, Control-click **Metric Converter** in Applications and choose **Open**.

To distribute it without Gatekeeper warnings, add a Developer ID Application certificate and a Developer ID Installer certificate, then build with:

```sh
APPLICATION_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
INSTALLER_SIGNING_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
./scripts/create-installer.sh
```

Notarization is also required before distributing the installer outside your own Mac.
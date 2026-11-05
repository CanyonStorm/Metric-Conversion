# Install Metric Converter on macOS

These instructions assume you received `MetricConverter-1.1.0.pkg` as an email attachment.

1. In Mail, download or save the attached package. If macOS warns about opening an attachment, save it to your **Downloads** folder rather than opening it from Mail.
2. Open **Finder > Downloads** and locate `MetricConverter-1.1.0.pkg`.
3. Since this installer is unsigned and not notarized, macOS may warn that it cannot verify the developer. Control-click the package, choose **Open**, and confirm **Open** in the warning dialog. If that option does not appear, open **System Settings > Privacy & Security** after trying to open the package and look for an **Open Anyway** option.
4. Follow the installer prompts. Enter your Mac password if requested. Metric Converter will be installed in **Applications**.
5. Open **Applications > Metric Converter**. If macOS blocks the app on its first launch, Control-click the app, choose **Open**, and confirm. You may instead need to use **System Settings > Privacy & Security > Open Anyway**.

Metric Converter is a menu-bar app, so look for its ruler icon in the menu bar; it does not have a Dock icon. On first launch it registers to open at login. If macOS asks you to approve that, review **System Settings > General > Login Items**.

The app targets macOS 13 and later. Golden Gate has not been specifically tested. Only install the package if you trust the person who sent it.

## Updating an existing installation

Quit the running app before installing: open its menu-bar panel and choose
**Quit Metric Converter**. Older versions without a Quit button can be stopped
using Activity Monitor.

Run the new package, then reopen the app from Applications. The installer
replaces `/Applications/MetricConversion.app`; settings and history are stored
separately and should be preserved. Copies installed elsewhere are not replaced.

Quitting does not disable launch at login. To change that behavior, use the
app's settings or System Settings > General > Login Items.

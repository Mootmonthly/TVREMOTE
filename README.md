# TV Remote (Samsung)

A small SwiftUI iPhone remote for Samsung Smart TVs (2016 and newer).
Buttons: Back, Home, Power, D-pad + OK, Volume, Mute, Channel.

No Mac needed: GitHub builds the app, and you install it from a Windows PC.

## 1. Get the .ipa
1. Open the **Actions** tab of this repo → **Build IPA**.
2. Open the latest green run, scroll to **Artifacts**, download **TVRemote-ipa**.
3. Unzip it; you get `TVRemote.ipa`.

(Pushing to `main` rebuilds it, or press **Run workflow** on the Actions page.)

## 2. Install on your iPhone from Windows
1. Install **iTunes from apple.com** (not the Microsoft Store version) and **Sideloadly** (sideloadly.io).
2. Plug in your iPhone, tap **Trust** on the phone.
3. Open Sideloadly, drag in `TVRemote.ipa`, enter your Apple ID, click **Start**.
4. On the iPhone: Settings → General → VPN & Device Management → trust your Apple ID.
5. iOS 16+: Settings → Privacy & Security → **Developer Mode** → on (phone restarts).

With a free Apple ID the app stops opening after 7 days; just run Sideloadly again.

## 3. First connection
1. TV and iPhone on the same Wi-Fi.
2. Find the TV's IP: TV Settings → General → Network → Network Status → IP Settings.
3. Open the app, allow **Local Network**, type the IP, tap Connect.
4. Choose **Allow** on the TV prompt. It remembers you after that.

No prompt on the TV? TV Settings → General → External Device Manager → Device Connection Manager: turn on Access Notification and make sure "TV Remote" isn't on the denied list.

## Notes
- Power only turns the TV **off**; turning it on needs the real remote.
- Key codes are in `SamsungKey` in `Sources/SamsungRemote.swift`.
- Building on a Mac instead: `brew install xcodegen && xcodegen && open TVRemote.xcodeproj`.

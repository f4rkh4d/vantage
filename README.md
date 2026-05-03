# vantage

a macOS menubar app that does ten things. window snapping, clipboard history, system monitor, app launcher, pomodoro, display info, text snippets, ai chat (openai / anthropic / gemini / deepseek), network tools, battery stats.

built because i kept having five different apps open to do stuff that should live in one place. probably has bugs on edge cases i haven't hit yet.

---

**requires macOS 14+.** runs on apple silicon, probably fine on intel too.

## what's in it

- **window manager** — snap to halves, thirds, quarters, two-thirds, center float. global hotkeys with `⌃⌥` + a key. uses accessibility api so you'll need to grant that once
- **clipboard history** — last 200 items, searchable, pin the ones you reuse, copy back with one click
- **system monitor** — process list with live cpu/mem, disk usage donut, network i/o delta. kill button on hover
- **app launcher** — scans /Applications, shows recents, search by name
- **focus** — pomodoro timer (25/5/15). auto-advances, sends a notification when a phase ends. configurable durations
- **display controls** — shows your monitors, resolution, refresh rate, retina info. opens system settings for brightness (can't do that without private apis)
- **text snippets** — store short texts with a trigger abbreviation, copy to clipboard in one click
- **ai assistant** — chat with openai, anthropic, gemini, or deepseek. keys stored locally in userdefaults. switch providers mid-session
- **network tools** — live interface info with ipv4/ipv6, ping tool, dns from resolv.conf
- **battery & power** — cycle count, health %, temperature, capacity (mah), time to empty or full

## install

download `Vantage.dmg`, open it, drag to Applications. grant accessibility permission when window manager asks (settings > privacy & security > accessibility).

## build from source

```sh
brew install xcodegen
xcodegen generate
open Vantage.xcodeproj
```

requires Xcode 15+. swift 5, swiftui.

## notes

- no auto-update (yet)
- brightness control intentionally missing — apple locks that behind private apis that break every major release, not worth it
- ai module doesn't store conversation history between sessions, just the api keys
- tested on m2 pro, macOS 15. haven't tested on intel

## issues

open feedback at [github.com/f4rkh4d/vantage/issues](https://github.com/f4rkh4d/vantage/issues).

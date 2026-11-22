# Vendored fonts

These woff2 files are latin subsets fetched once from Google Fonts and committed
so `next build` never needs network access to `fonts.googleapis.com`. The Docker
builder previously failed when that request returned a CSS payload the Next.js
font loader could not parse.

| File | Family | Source |
| --- | --- | --- |
| `JetBrainsMono-Variable.woff2` | JetBrains Mono (100–800) | https://fonts.google.com/specimen/JetBrains+Mono |
| `IBMPlexSans-Variable.woff2` | IBM Plex Sans (100–700) | https://fonts.google.com/specimen/IBM+Plex+Sans |
| `Archivo-Variable.woff2` | Archivo (wght 100–900, wdth 62–125) | https://fonts.google.com/specimen/Archivo |
| `PublicSans-Variable.woff2` | Public Sans (100–900) | https://fonts.google.com/specimen/Public+Sans |
| `IBMPlexMono-400.woff2` | IBM Plex Mono 400 | https://fonts.google.com/specimen/IBM+Plex+Mono |
| `IBMPlexMono-500.woff2` | IBM Plex Mono 500 | https://fonts.google.com/specimen/IBM+Plex+Mono |

All families are licensed under the SIL Open Font License 1.1:
https://openfontlicense.org/open-font-license-official-text/

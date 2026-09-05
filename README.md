# music-stream-match API

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-5865F2?logo=discord&logoColor=white)](https://discord.gg/rwJcE5Zwez)
[![Track Mappings](https://img.shields.io/badge/Tracks-1.45M%2B-blue)](https://api.musica.mobulum.com)

> Free, open, static REST API for cross-platform music streaming track matching between Spotify, Apple Music, Deezer, and Tidal.

---

## What

**music-stream-match** is a response to the need for free, fast, and normalized music streaming track identifier matching.
It provides direct mappings between track IDs across the most popular music platforms:
- **Spotify**
- **Apple Music**
- **Deezer**
- **Tidal**

Query the REST API using any standard HTTP client and receive clean JSON responses.
Hosted statically via GitHub Pages and custom CDN for zero downtime, global edge caching, and zero rate limits.

Available to everyone, free, forever.

---

## Why

When building music applications, playlist synchronizers, smart DJ tools, or managing personal digital audio collections,
you often have a track identifier from one streaming service (e.g., Spotify or Apple Music) and need to locate the equivalent track
on other services (such as Tidal or Deezer) with high fidelity.

Querying streaming APIs dynamically at runtime introduces high latency, requires maintaining developer accounts and OAuth
tokens for each platform, and is subject to restrictive rate limits.

**music-stream-match** solves this by pre-resolving and continuously maintaining cross-provider track mappings into a static,
highly available API structure. No authentication, no tokens, no rate limits — just direct HTTP GET requests.

---

## How to Use

All you need is an HTTP client (like `curl`, `fetch`, `axios`, etc.) capable of making simple GET requests.

### Base URL

```text
https://api.musica.mobulum.com
```

Alternative (GitHub Pages):
```text
https://music-stream-match.github.io/api
```

---

## API Endpoints

### Track Resolution

```text
GET /api/providers/{provider}/tracks/{trackId}.json
```

Where `{provider}` is one of: `spotify`, `apple`, `deezer`, `tidal`.  
And `{trackId}` is the provider's native track identifier.

---

## Examples

### 1. Lookup by Spotify Track ID

```bash
curl "https://api.musica.mobulum.com/api/providers/spotify/tracks/1cEg7nTVIatIQ6UQuZn5Ow.json"
```

Response:

```json
{
  "id": "1cEg7nTVIatIQ6UQuZn5Ow",
  "providers": {
    "spotifyTrackId": "1cEg7nTVIatIQ6UQuZn5Ow",
    "deezerTrackId": "505561852",
    "tidalTrackId": "89379997",
    "appleTrackId": "1388093424"
  }
}
```

### 2. Lookup by Apple Music Track ID

```bash
curl "https://api.musica.mobulum.com/api/providers/apple/tracks/300313670.json"
```

Response:

```json
{
  "id": "300313670",
  "providers": {
    "appleTrackId": "300313670",
    "deezerTrackId": "4085351",
    "tidalTrackId": "10902798"
  }
}
```

### 3. Lookup by Deezer Track ID

```bash
curl "https://api.musica.mobulum.com/api/providers/deezer/tracks/100156210.json"
```

Response:

```json
{
  "id": "100156210",
  "providers": {
    "deezerTrackId": "100156210",
    "tidalTrackId": "45465756",
    "appleTrackId": "993345918"
  }
}
```

### 4. Lookup by Tidal Track ID

```bash
curl "https://api.musica.mobulum.com/api/providers/tidal/tracks/187760504.json"
```

Response:

```json
{
  "id": "187760504",
  "providers": {
    "tidalTrackId": "187760504",
    "deezerTrackId": "1405085262",
    "appleTrackId": "1572341403"
  }
}
```

---

## Response Structure

Each track entry contains:
- `id` *(string)*: The requested track ID for the specified provider.
- `providers` *(object)*: Map of matching identifiers across resolved platforms:
  - `spotifyTrackId` *(string, optional)*
  - `appleTrackId` *(string, optional)*
  - `deezerTrackId` *(string, optional)*
  - `tidalTrackId` *(string, optional)*

If a track is not found, the server returns a standard `404 Not Found`.

---

## FAQ

**Q: How can I contact you?**  
**A:** Join the Discord community: [https://discord.gg/rwJcE5Zwez](https://discord.gg/rwJcE5Zwez)

**Q: Do I need an API key or registration?**  
**A:** No. The API is completely public, static, and requires no API keys or tokens.

**Q: Why a static REST API?**  
**A:** Static files served via CDN offer unmatched speed, global edge caching, zero infrastructure maintenance, and 100% uptime with no database bottlenecks.

**Q: How often is the database updated?**  
**A:** The database is continuously updated and pushed from our radio station playlists, crawler pipelines, and audio synchronization tools.

---

## Free, forever

Feel free to use however you like, but please do not sell it. It is FREE for everyone! FOREVER. You can buy me a coffee if you like to thank me:

- [PayPal](https://paypal.me/zenedithPL)
- [Ko-Fi](https://ko-fi.com/K3K11ABGW5)
- [Patreon](https://patreon.com/Zenedith)

---

## Stats

Current verified track mappings in the database:

| Provider | Track Mappings |
| :--- | :--- |
| **Apple Music** | 619,315 |
| **Deezer** | 335,462 |
| **Tidal** | 325,501 |
| **Spotify** | 172,231 |
| **Total Track Mappings** | **1,452,509** |

---

## License

music-stream-match is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---
#
# By default, content added below the "---" mark will appear in the home page
# between the top bar and the list of recent posts.
# To change the home page layout, edit the _layouts/home.html file.
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
#
layout: home
title: "Welcome to music-stream-match"
---

# What

**music-stream-match** is a free, open-source API that maps track IDs across music streaming services — [Deezer](https://www.deezer.com), [Tidal](https://tidal.com), [Spotify](https://www.spotify.com), and [Apple Music](https://music.apple.com).

Given a track ID from one provider, you can look up its equivalent on another. The API is served as static JSON files hosted on [GitHub Pages](https://pages.github.com/), making it fast, reliable, and freely accessible to any developer.

Currently supported providers:
- **Deezer**
- **Tidal**
- **Spotify**
- **Apple Music**

# Why

Switching between music streaming platforms is painful. Playlists, favorites, and libraries are locked within each service. There is no universal track identifier shared across all providers.

**music-stream-match** solves this by providing a simple cross-reference database. It enables developers to build tools that:

- **Migrate playlists** between streaming services
- **Sync libraries** across multiple platforms
- **Compare catalogs** to find availability differences
- **Build universal music apps** that work with any provider

The data is sourced from [yotuna.com](https://yotuna.com) — a free service that matches tracks from radio playlists to specific files across streaming providers. This ensures real-world, high-quality matching based on actual music metadata.

# How

The API is a collection of static JSON files. Each file represents a track and contains a map of its IDs across all matched providers.

## API Endpoint

```
GET https://api.music-stream-match.space/api/providers/{provider}/tracks/{trackId}.json
```

### Parameters

| Parameter  | Description                                               |
|------------|-----------------------------------------------------------|
| `provider` | Streaming service name: `deezer`, `tidal`, `spotify`, `apple` |
| `trackId`  | The track ID from the specified provider                  |

### Response

A JSON object with the track ID and a `providers` map containing matched IDs:

```json
{
  "id": "366898781",
  "providers": {
    "deezerTrackId": "366898781",
    "tidalTrackId": "74463286",
    "spotifyTrackId": "2QlPByrmEO9XciNBXCrawR",
    "appleTrackId": "1523973949"
  }
}
```

### Examples

**Find Tidal equivalent of a Deezer track:**

```bash
curl https://api.music-stream-match.space/api/providers/deezer/tracks/3259841.json
```

**Find Deezer equivalent of a Tidal track:**

```bash
curl https://api.music-stream-match.space/api/providers/tidal/tracks/144815.json
```

### Error Handling

| HTTP Status | Meaning                                      |
|-------------|----------------------------------------------|
| `200`       | Track found — JSON response returned         |
| `404`       | Track not found in the database              |

## Contributing

The project is open source. Contributions are welcome via pull requests on [GitHub](https://github.com/music-stream-match/api).

Join the community on [Discord](https://discord.gg/rwJcE5Zwez).

## Support the Project

**music-stream-match** is free and open source. If you find it useful, consider supporting its development:

- [PayPal](https://paypal.me/zenedithPL)
- [Ko-fi](https://ko-fi.com/K3K11ABGW5)
- [Patreon](https://patreon.com/Zenedith)

Your support helps keep the project maintained and the data up to date. Thank you!

## Contact

If you have questions about this Privacy Policy, contact us at:

**Email:** [music-stream-match@mobulum.com](mailto:music-stream-match@mobulum.com)

**Discord:**

# License

The music-stream-match is licensed under the [MIT license](https://opensource.org/licenses/MIT).

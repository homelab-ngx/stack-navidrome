# stack-navidrome

[Navidrome](https://www.navidrome.org), a music server with a web player and
the Subsonic API for phone apps, as a stack for [homelab-ngx](https://github.com/homelab-ngx/homelab-ngx).
[deemix](https://github.com/bambanah/deemix) downloads from Deezer into the
same library.

## Getting started

1. Add the stack: `homelab stacks add github:homelab-ngx/stack-navidrome`,
   or Add stack on the dashboard's Stacks page.
2. On the stack's page, set `MUSIC_DIR` to your music folder. Both apps
   write to it through the folder's group, so the group needs write access.
3. Approve the grants and start the stack.
4. Open `https://music.<your domain>` and create the admin account.
5. Open `https://deemix.<your domain>` and sign in with your Deezer ARL.

deemix has no login of its own. Its route is served only on your private
network.

A download lands in the library as `Artist/Album`. A playlist becomes a
Various Artists compilation with an m3u8 playlist. Navidrome scans the
library every hour.

The backup folders below hold Navidrome's users, play counts, stars and
playlists, and deemix's settings. The music is not among them: add
`MUSIC_DIR` to a backup yourself.

<!-- manifest:start -->
<!-- Made from homelab-stack.json. Change the manifest, not these lines. -->

## Grants

You approve each of these before the stack starts.

- Route: `music.<your domain>` to port 4533 in the stack.
- Route: `deemix.<your domain>` to port 6595 in the stack.
- Storage: the folder in `MUSIC_DIR`, at `/pool/media/library/music` in the stack, read-write.

## Variables

| Name | Kind | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `MUSIC_DIR` | path | yes |  | The music library: Navidrome plays it and deemix downloads into it. Its group becomes the stack's media group, which both use. |

## Backup

The stack recommends these folders. None is backed up until you add it to a backup.

- Navidrome settings: `/var/lib/navidrome` in the stack.
  - Without `/cache/**`. Resized artwork and transcodes. They are made again.
  - Without `/artwork/**`. Downloaded artist and album images. They download again.
- Deemix settings: `/var/lib/deemix` in the stack.
  - Without `/logs/**`. Log files.
  - Without `/queue/**`. The download queue.

## Health

An update is kept when all of this holds, and rolled back when it does not.

- `navidrome.service` is active.
- `deemix.service` is active.
- Port 4533 answers at `/ping`.

Manifest version 9, built with nixpkgs `nixos-unstable`. Runs on [homelab-ngx](https://github.com/homelab-ngx/homelab-ngx).

<!-- manifest:end -->

## License

MIT, see [LICENSE](LICENSE).

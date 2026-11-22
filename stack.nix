{ pkgs, deemix, ... }:

# Navidrome streams the music library; deemix downloads from Deezer straight
# into it. The homelab daemon's host module gives the media group the
# library's gid and opens the routes' ports.

let
  library = "/pool/media/library/music";
  appdata = "/var/lib/deemix";

  deemixPkg = deemix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    # Its packageManager field pins a pnpm the nixpkgs it builds with does
    # not have; rewrite it to the pnpm at hand.
    preBuild = (old.preBuild or "") + ''
      PNPM_VERSION=$(pnpm --version) node -e 'const fs=require("fs");const p=JSON.parse(fs.readFileSync("package.json"));p.packageManager="pnpm@"+process.env.PNPM_VERSION;fs.writeFileSync("package.json",JSON.stringify(p,null,2))'
    '';
    pnpmDeps = old.pnpmDeps.overrideAttrs {
      outputHash = "sha256-uvi7hudXj6yaaRM7q9iWpa2E/SKUvXnjTWZlzhcEgFQ=";
    };
  });

  # deemix files downloads the way Navidrome reads them: Artist/Album
  # folders, a playlist as a Various Artists compilation with an m3u8.
  # Merged into its config.json on every start; its other settings are kept.
  layout = {
    downloadLocation = library;
    tags.savePlaylistAsCompilation = true;
    createPlaylistFolder = false;
    createStructurePlaylist = true;
    createArtistFolder = true;
    artistNameTemplate = "%artist%";
    createAlbumFolder = true;
    albumNameTemplate = "%album%";
    createCDFolder = true;
    createSingleFolder = true;
    albumTracknameTemplate = "%tracknumber% %title%";
    playlistTracknameTemplate = "%tracknumber% %title%";
    tracknameTemplate = "%tracknumber% %title%";
    createM3U8File = true;
    playlistFilenameTemplate = "%playlist%";
    saveArtwork = true;
    coverImageTemplate = "cover";
    overwriteFile = "n";
  };
  layoutFile = pkgs.writeText "deemix-layout.json" (builtins.toJSON layout);
  applyLayout = pkgs.writeShellScript "deemix-apply-layout" ''
    set -eu
    f=${appdata}/config.json
    if [ -s "$f" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$f" ${layoutFile} > "$f.tmp"
    else
      cp ${layoutFile} "$f.tmp"
    fi
    mv "$f.tmp" "$f"
  '';
in
{
  users.groups.media = { };

  # ── Navidrome ───────────────────────────────────────────────────────────
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = library;
      Scanner.Schedule = "@every 1h";
      Backup = {
        Path = "/var/lib/navidrome/backup";
        Schedule = "@every 24h";
        Count = 7;
      };
      EnableReplayGain = true;
      LogLevel = "info";
    };
  };
  users.users.navidrome.extraGroups = [ "media" ];
  systemd.tmpfiles.settings."10-navidrome"."/var/lib/navidrome/backup".d = {
    user = "navidrome";
    group = "navidrome";
    mode = "0700";
  };

  # ── deemix ──────────────────────────────────────────────────────────────
  users.users.deemix = {
    isSystemUser = true;
    group = "media";
    home = appdata;
  };

  systemd.services.deemix = {
    description = "deemix Deezer downloader web UI";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      DEEMIX_HOST = "0.0.0.0";
      DEEMIX_SERVER_PORT = "6595";
      DEEMIX_DATA_DIR = appdata;
      DEEMIX_MUSIC_DIR = library;
      DEEMIX_SINGLE_USER = "true";
      HOME = appdata;
    };
    serviceConfig = {
      ExecStartPre = [ applyLayout ];
      ExecStart = "${deemixPkg}/bin/deemix-webui";
      User = "deemix";
      Group = "media";
      StateDirectory = "deemix";
      StateDirectoryMode = "0700";
      UMask = "0002";
      Restart = "on-failure";
      RestartSec = 10;
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ library ];
    };
  };
}

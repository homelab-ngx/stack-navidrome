{
  description = "Navidrome and deemix as a stack for homelab-ngx";

  inputs = {
    # deemix-webui 4.7.0. No follows: its pnpm hash is tied to its own nixpkgs.
    deemix.url = "github:bambanah/deemix/230bcd9171a93eee1b1c96c54453f255e9fd59a7";
  };

  # The homelab daemon builds nixosModules.default on its base module with
  # the nixpkgs homelab-stack.json recommends (manifest version 8).
  outputs =
    { deemix, ... }:
    {
      nixosModules.default = {
        imports = [ ./stack.nix ];
        _module.args.deemix = deemix;
      };
    };
}

{ isHydra }: with builtins;
let
  defaultNixDroid = {
    nixexprpath = "default.nix";
    checkinterval = 0;
    schedulingshares = 1000;
  };
  mkInput = t: v: e: { type = t; value = v; emailresponsible = e; };
  nixdroid = mkInput "git" "https://github.com/ajs124/NixDroid" true;
  manifests = {
    LineageOS = "https://github.com/LineageOS/android";
    ResurrectionRemix = "https://github.com/ResurrectionRemix/platform_manifest";
    UnlegacyAndroid = "https://github.com/Unlegacy-Android/android";
    PixelExperience = "https://github.com/PixelExperience/manifest";
  };
  defaultInputs = args: {
    inherit nixdroid;
    nixpkgs = mkInput "git" "https://github.com/nixos/nixpkgs-channels nixos-19.03" false;
    rev = mkInput "string" args.rev false;
    keyStorePath = mkInput "string" "/var/lib/nixdroid/keystore" false;
    device = mkInput "string" args.device false;
    manifest = mkInput "string" manifests."${args.rom}" false;
    sha256Path = mkInput "path" ("/var/lib/nixdroid/hashes/${args.rev}-${args.device}.sha256") false;
    extraFlags = mkInput "string" (optConf args "extraFlags" "-g all,-darwin,-infra,-sts --no-repo-verify") false;
    opengappsVariant = mkInput "string" (optConf args "opengappsVariant" null) false;
    enableWireguard = mkInput "boolean" (optConf args "enableWireguard" "false") false;
    usePatchedCoreutils = mkInput "boolean" "true" false;
    otaURL = mkInput "string" "https://ipv2.de/nixdroid/${args.device}/" false;
    localManifests = let
      list = [ (../roomservice + "/${args.rom}/${args.device}.xml") ] ++  # enableWireguard is a string, because hydra expects it to be one
          (if (hasAttr "enableWireguard" args && args.enableWireguard == "true") then [ ../roomservice/misc/wireguard.xml ] else []) ++
          (if (hasAttr "opengappsVariant" args) then [ ../roomservice/misc/opengapps.xml ] else []);
      in {
      type = "nix";
      value = if isHydra then "[ " + toString list + " ]" else list;  # hydra does not take lists, only nix expressions
      emailresponsible = false;
    };
  };
  optConf = set: attr: default: if (hasAttr attr set) then set.${attr} else default;
in {
  defaultJobset = {
    enabled = 1;
    hidden = false;
    nixexprinput = "nixdroid";
    nixexprpath = "default.nix";
    checkinterval = 300;
    schedulingshares = 1000;
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
  };
  jobsets = {
    "los-15.1-hammerhead" = defaultNixDroid // {
      description = "LineageOS 15.1 for Hammerhead";
      inputs = defaultInputs {
        device = "hammerhead";
        rom = "LineageOS";
        rev = "lineage-15.1";
        opengappsVariant = "pico";
      };
    };
    "los-16.0-hammerhead" = defaultNixDroid // {
      description = "LineageOS 16.0 for Hammerhead";
      inputs = defaultInputs {
        device = "hammerhead";
        rom = "LineageOS";
        rev = "lineage-16.0";
        opengappsVariant = "pico";
      };
    };
    "los-16.0-payton" = defaultNixDroid // {
      description = "LineageOS 16.0 for Payton";
      inputs = defaultInputs {
        device = "payton";
        rom = "LineageOS";
        rev = "lineage-16.0";
        enableWireguard = "true";
        opengappsVariant = "nano";
      };
    };
    "los-16.0-oneplus3" = defaultNixDroid // {
      description = "LineageOS 16.0 for OnePlus 3";
      inputs = defaultInputs {
        device = "oneplus3";
        rom = "LineageOS";
        rev = "lineage-16.0";
        enableWireguard = "true";
        opengappsVariant = "nano";
      };
    };
    prefetch = {
      description = "prefetch script for other jobsets hashes";
      nixexprpath = "hydra/prefetch.nix";
      hidden = true;
      inputs = {
        inherit nixdroid;
        nixpkgs = mkInput "git" "https://github.com/nixos/nixpkgs-channels nixos-unstable" false;
      };
    };
    # "los-16.0-bacon" = defaultNixDroid // {
    #   description = "LineageOS 16.0 for Bacon";
    #   inputs = defaultInputs {
    #     device = "bacon";
    #     enableWireguard = "true";
    #     opengappsVariant = "pico";
    #   };
    # };
  };
}

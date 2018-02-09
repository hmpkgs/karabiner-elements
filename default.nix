{ config, pkgs, lib, ... }:

with import <home-manager/modules/lib/dag.nix> { inherit lib; };
with lib;
with builtins;

let
  appName = "Karabiner-Elements.app";
  cfg = config.programs.viscosity;

  package = pkgs.stdenv.mkDerivation rec {
    name = appName;
    src = pkgs.fetchurl {
      url = "https://pqrs.org/osx/karabiner/files/Karabiner-Elements-11.5.0.dmg";
      sha256 = "0iza7vpaa3rikrg0bq80zdf62i6y1lpx71zfknwidr8zsamms6bk";
    };

    buildInputs = [ pkgs.undmg ];
    installPhase = ''
      source $stdenv/setup
      mkdir -pv $out/Applications/${appName}
      cp -r ./* $out/Applications/${appName}
    '';

    meta = {
      description = "Karabiner-Elements for macOS";
      homepage = https://pqrs.org/osx/karabiner/;
      platforms = pkgs.stdenv.lib.platforms.darwin;
    };
  };

in {
  options = {
    programs.karabiner-elements = {
      enable = mkEnableOption "Karabiner-Elements";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];
    home.activation.karabiner-elements = dagEntryAfter["installPackages"] (let
      home = config.home.homeDirectory;
      applications = "${home}/.nix-profile/Applications";
      source = "${applications}/${appName}";
      target = "${home}/Applications/";
    in ''
      if [ -e ${target}/${appName} ]; then
        rm -r ${target}/${appName}
      fi
      osascript << EOF
        tell application "Finder"
        set mySource to POSIX file "${source}" as alias
        make new alias to mySource at POSIX file "${target}"
        set name of result to "${appName}"
      end tell
      EOF
    '');
  };
}

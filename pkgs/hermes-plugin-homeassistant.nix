{
  lib,
  fetchFromGitHub,
  runCommand,
}:
let
  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = "8b5b6296bbb900f90e296b4729d2c9a5d1139825";
    hash = "sha256-BPXL09hZYhoHBjEgsMs8BhDTDrI4N4N5OiidIcJqrJE=";
  };
in
runCommand "hermes-plugin-homeassistant" { } ''
  mkdir -p $out
  cp -r ${src}/homeassistant/* $out/
''

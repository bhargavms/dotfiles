{ buildGoModule, fetchFromGitHub, lib }:

{
  go-enum = buildGoModule rec {
    pname = "go-enum";
    version = "0.9.2";
    src = fetchFromGitHub {
      owner = "abice";
      repo = "go-enum";
      rev = "v${version}";
      hash = "sha256-VZH7xLEDqU8N7oU3tOWVdTABEQEp2mlh1NtTg22hzco=";
    };
    vendorHash = "sha256-bqJ+KBUsJzTNqeshq3eXFImW/JYL7zmCEwcy2xQHJeE=";
    subPackages = [ "." ];
    ldflags = [ "-X main.version=v${version}" "-X main.builtBy=nix" ];
    meta = {
      description = "Generate Go enum helpers";
      homepage = "https://github.com/abice/go-enum";
      license = lib.licenses.mit;
      mainProgram = "go-enum";
      platforms = [ "aarch64-darwin" ];
    };
  };

  gojsonstruct = buildGoModule rec {
    pname = "gojsonstruct";
    version = "3.3.0";
    src = fetchFromGitHub {
      owner = "twpayne";
      repo = "go-jsonstruct";
      rev = "v${version}";
      hash = "sha256-mNZAezLKMrgnzsRikrZhmjTuF+B1ob5Bjh33voNsyCs=";
    };
    vendorHash = "sha256-5gtUZfXrob+4IJYrugjDJl6TJ1wYW5Occ1P6mRJBHjA=";
    subPackages = [ "cmd/gojsonstruct" ];
    meta = {
      description = "Generate Go structs from JSON or YAML";
      homepage = "https://github.com/twpayne/go-jsonstruct";
      license = lib.licenses.bsd2;
      mainProgram = "gojsonstruct";
      platforms = [ "aarch64-darwin" ];
    };
  };

  gomvp = buildGoModule rec {
    pname = "gomvp";
    version = "0.0.4";
    src = fetchFromGitHub {
      owner = "abenz1267";
      repo = "gomvp";
      rev = "v${version}";
      hash = "sha256-dXjI+nItJCAGKxyC9tX11hxWHCP+NgXtTYtm5+6dqDU=";
    };
    vendorHash = null;
    subPackages = [ "." ];
    meta = {
      description = "Move Go packages and rename modules";
      homepage = "https://github.com/abenz1267/gomvp";
      license = lib.licenses.mit;
      mainProgram = "gomvp";
      platforms = [ "aarch64-darwin" ];
    };
  };

  json-to-struct = buildGoModule rec {
    pname = "json-to-struct";
    version = "0.1.0";
    src = fetchFromGitHub {
      owner = "tmc";
      repo = "json-to-struct";
      rev = "v${version}";
      hash = "sha256-7zvWUVo0w+eXyNLP1mnoLMWnyfc3xQIMgK+eD/yCSeU=";
    };
    vendorHash = "sha256-fj0gTSKG38GYyScHfT4gh512mm1uv1Sunqs3P8V7e4U=";
    subPackages = [ "." ];
    meta = {
      description = "Generate Go struct definitions from JSON";
      homepage = "https://github.com/tmc/json-to-struct";
      license = lib.licenses.gpl3Only;
      mainProgram = "json-to-struct";
      platforms = [ "aarch64-darwin" ];
    };
  };
}

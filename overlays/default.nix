final: prev: {
  # nixpkgs-unstable trails OmniWM's GitHub releases. Bump the upstream
  # derivation in place rather than reaching for the Homebrew cask: the package
  # already unpacks the signed release zip with bsdtar (plain unzip breaks the
  # Developer ID signature), and the Home Manager module keeps working
  # unchanged because it still reads `pkgs.omniwm`.
  #
  # Pinned unconditionally, even once nixpkgs catches up: every OmniWM version
  # needs its own captured defaults file (modules/home/omniwm), so a version
  # change must be a deliberate edit here followed by `just omniwm-capture`,
  # never a side effect of `nix flake update`.
  omniwm = prev.omniwm.overrideAttrs (finalAttrs: _: {
    version = "0.7.5";
    src = prev.fetchurl {
      url = "https://github.com/OmniNull/OmniWM/releases/download/v${finalAttrs.version}/OmniWM-v${finalAttrs.version}.zip";
      hash = "sha256-oV/KNBGojdBviTUyjChiY9V6RMe8wiVUd+KTA/qUzM4=";
    };
  });

  # bicep builds from source on this Mac (not yet in the binary cache for every
  # release), and its test Basic_formatting_works expects "0.3s" but .NET reads
  # the macOS system locale (Estonian) and prints "0,3s". The other 73 tests
  # pass, but a test filter does not reach dotnetCheckHook, so the unit tests
  # are skipped for this package only. Drop once the release is cached or
  # nixpkgs skips the test.
  #
  # Its Bicep.Local.Rpc project also runs protoc and grpc_csharp_plugin from the
  # Grpc.Tools NuGet package, which ships only x86_64 macOS binaries, so the
  # build dies with "Bad CPU type in executable" on Apple silicon without
  # Rosetta. MSBuild reads environment variables as properties, so point
  # Grpc.Tools at the native nixpkgs tools instead; protobuf_35 matches the
  # Google.Protobuf 3.35 runtime bicep links against. Drop once Grpc.Tools
  # ships macosx_arm64 binaries or nixpkgs does the same.
  bicep = prev.bicep.overrideAttrs (old: {
    doCheck = false;
    preBuild = (old.preBuild or "") + ''
      export Protobuf_ProtocFullPath=${final.protobuf_35}/bin/protoc
      export gRPC_PluginFullPath=${final.grpc}/bin/grpc_csharp_plugin
    '';
  });

  # debugpy (pulled in by the ms-python.python VS Code extension) builds from
  # source on darwin, and test_lldb_command fails there: it attaches lldb to a
  # live process, which the build sandbox forbids. The other 965 tests pass.
  # Drop once nixpkgs disables it upstream.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyPrev: {
      debugpy = pyPrev.debugpy.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_lldb_command" ];
      });
    })
  ];
}

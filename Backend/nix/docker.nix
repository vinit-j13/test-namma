{ self, ... }:

let
  imageName = "ghcr.io/vinit-j13/test-namma";
  # self.rev will be non-null only when the working tree is clean
  # This is equivalent to `git rev-parse --short HEAD`
  imageTag = builtins.substring 0 6 (self.rev or "dev");
in
{
  config = {
    perSystem = { self', pkgs, lib, ... }: {
      packages = lib.optionalAttrs pkgs.stdenv.isLinux {
        dockerImage = (pkgs.dockerTools.buildImage {
          name = imageName;
          created = "now";
          tag = imageTag;
          copyToRoot = pkgs.buildEnv {
            paths = with pkgs; [
              cacert
              awscli
              coreutils
              bash
              self'.packages.nammayatri
              gdal
              postgis
              curl
              htop
              wget
              zbar
            ];
            name = "beckn-root";
            pathsToLink = [
              "/bin"
              "/opt"
            ];
          };
          config = {
            Env = [
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              # Ref: https://hackage.haskell.org/package/x509-system-1.6.7/docs/src/System.X509.Unix.html#getSystemCertificateStore
              "SYSTEM_CERTIFICATE_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
            Cmd = [ "${self'.packages.nammayatri}/bin/rider-app-exe" ];
          };

          # Test that the docker image contains contents we expected for
          # production.
          extraCommands = ''
            # Executables are under /opt/app
            ls opt/app/rider-app-exe
            # Swagger configs are copied over
            ls opt/app/swagger
          '';
        }).overrideAttrs (lib.addMetaAttrs {
          description = "Docker image for test-namma backend";
          homepage = "https://github.com/vinit-j13/test-namma/pkgs/container/test-namma";
        });
      };
    };
  };
}

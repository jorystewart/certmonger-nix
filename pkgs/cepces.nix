{ pkgs ? import <nixpkgs> {} }:

let
  python = pkgs.python3;
  pythonPackages = pkgs.python3Packages;

  deps = with pythonPackages; [
    cryptography
    requests
    requests-gssapi
    keyring
    urllib3
    idna
    charset-normalizer
    certifi
  ];

  pythonPath = pkgs.lib.concatStringsSep ":" (map (pkg: "${pkg}/${python.sitePackages}") deps);
in

pythonPackages.buildPythonPackage {
  pname = "cepces";
  version = "0.3.9";
  format = "other";

  src = pkgs.fetchFromGitHub {
    owner = "openSUSE";
    repo = "cepces";
    rev = "v0.3.9";
    sha256 = "sha256-bbUh5kMSbZD2EpTOUPMtC0xRVpOlWg98r59zOlXUYrM=";
  };

  propagatedBuildInputs = deps;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildPhase = "true";

  installPhase = ''
    # Install Python module
    mkdir -p $out/${python.sitePackages}
    cp -r cepces $out/${python.sitePackages}/

    # Install and wrap the CLI script
    mkdir -p $out/bin
    cp bin/cepces-submit $out/bin/cepces-submit
    chmod +x $out/bin/cepces-submit

    makeWrapper $out/bin/cepces-submit $out/bin/cepces-submit \
      --set PYTHONPATH "${pythonPath}:$out/${python.sitePackages}"

    mkdir -p $out/etc
    cp conf/cepces.conf.dist $out/etc/cepces.conf
    cp conf/logging.conf.dist $out/etc/logging.conf
  '';

  checkPhase = ''
    echo "Testing Python module import..."
    python -c "from cepces.certmonger.core import Result; print(Result)"
  '';

  meta = {
    description = "CEP/CES certificate enrollment client for certmonger";
    homepage = "https://github.com/openSUSE/cepces";
    license = pkgs.lib.licenses.gpl3;
  };
}

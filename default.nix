{
  pkgs ? import <nixpkgs> {},
  listenDefault ? "127.0.0.1:1080",
  defaultConfig ? ./config.inc.php,
}:
with pkgs; let
  defaultConfigFolder = linkFarm "phpmyadmin-config" [
    {
      name = "config.inc.php";
      path = defaultConfig;
    }
  ];

  phpmyadminBase = stdenv.mkDerivation rec {
    pname = "phpmyadmin";
    version = "5.1.0";

    src = fetchurl {
      url = "https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-all-languages.tar.xz";
      sha256 = "qozPNX9nIBI4TfNOHCvHAUdHZ2HIRYoNrWIzSX4ULGg=";
    };

    phases = ["unpackPhase" "patchPhase"];

    unpackPhase = ''
      mkdir $out
      cd $out
      tar --strip-components=1 -xf $src
    '';

    patches = [./legacy_mysql.patch ./vendor_config.patch];
  };

  phpIni = runCommand "php.ini" {} ''
    cat ${php}/etc/php.ini > $out
    cat <<EOF >> $out
    [PHP]
    display_errors = stderr
    display_startup_errors = on
    log_errors = on
    error_reporting = E_ALL
    error_log = /dev/stderr
    EOF
  '';

  phpmyadminRun = writeShellScriptBin "phpmyadmin" ''
    set -euo pipefail

    listen="${listenDefault}"
    random_tmp_dir=0
    delete_tmp_dir=0
    : ''${PMA_CONFIG_DIR:="${defaultConfigFolder}"}
    : ''${PMA_TEMP_DIR:="$PWD/tmp"}

    while getopts "l:c:t:rd" opt; do
      case "$opt" in
        l) listen="$OPTARG";;
        r) random_tmp_dir=1; delete_tmp_dir=1;;
        d) delete_tmp_dir=1;;
        c) PMA_CONFIG_DIR="$(readlink -f "$OPTARG")";;
        t) PMA_TEMP_DIR="$OPTARG";;
      esac
    done

    shift $((OPTIND-1))
    [[ $# -gt 0 && "$1" = "--" ]] && shift || :

    [[ -n ''${PMA_BLOWFISH_SECRET:-} ]] || \
      export PMA_BLOWFISH_SECRET="$(${php}/bin/php -r 'echo base64_encode(random_bytes(24));')"
    (( random_tmp_dir )) && \
      PMA_TEMP_DIR="$(mktemp -d --tmpdir phpmyadmin.XXXXXX)" || :
    (( delete_tmp_dir )) && \
      trap 'echo Deleting "$PMA_TEMP_DIR"; rm -R "$PMA_TEMP_DIR"' EXIT || :
    export PMA_TEMP_DIR="''${PMA_TEMP_DIR%%/}/"
    export PMA_CONFIG_DIR="''${PMA_CONFIG_DIR%%/}/"

    cd ${phpmyadminBase}
    ${php}/bin/php -S $listen -c ${phpIni}
  '';
in
  phpmyadminRun

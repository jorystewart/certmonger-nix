{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "certmonger";
  version = "0.79.20";

  src = pkgs.fetchurl {
    url = "https://pagure.io/certmonger/archive/0.79.20/certmonger-0.79.20.tar.gz";
    sha256 = "sha256-I2RaXBsoTXPfRI27lzZsG25jkiP8lGXng0+lxf7z8B4=";
  };

  nativeBuildInputs = with pkgs; [
    autoconf
    automake
    libtool
    pkg-config
    gettext
    talloc
    tevent
    nss
    curl
    jansson
    openldap
  ];

  buildInputs = with pkgs; [
    krb5
    dbus
    openssl
    libxml2
    libxslt
    popt
  ];

  makeFlags = [
  	"dbusservicedir=$out/etc/dbus-1/services"
  ];


  configureFlags = [
  	"--with-file-store-dir=/var/lib/certmonger"
  ];

  preConfigure = ''
    substituteInPlace configure.ac \
    --replace 'mylocalstatedir="$localstatedir/lib/''${PACKAGE_NAME})"' \
              'mylocalstatedir="/var/lib/''${PACKAGE_NAME}"'

    --replace 'AC_DEFINE_UNQUOTED(CM_STORE_CONFIG_DIRECTORY,"$mysysconfdir/''${PACKAGE_NAME}"' \
              'AC_DEFINE_UNQUOTED(CM_STORE_CONFIG_DIRECTORY,"$out/etc/''${PACKAGE_NAME}"'
 
    substituteInPlace dbus/Makefile.in \
      --replace /etc/dbus-1 $out/etc/dbus-1
  
    substituteInPlace dbus/Makefile.am \
      --replace '$(sysconfdir)/dbus-1' '$out/etc/dbus-1'

    substituteInPlace dbus/Makefile.in \
      --replace '$(mkdir_p) $(DESTDIR)$(dbusservicedir)' 'true'

    sed -i '/^install-data-hook::/a\\ttrue' src/Makefile.am
    sed -i 's|\$mylocalstatedir|/var/lib|g' configure.ac

    '';

  configurePhase = ''
    autoreconf -fi

    sed -i '/^install-data-hook::/a\\ttrue' src/Makefile.in
    sed -i 's|\$mylocalstatedir|/var/lib|g' configure.ac
    
    ./configure --prefix=$out \
      --with-systemdsystemunitdir=${pkgs.systemd}/lib/systemd/system \
      --with-store-dir=/var/lib/certmonger \
      --sysconfdir=$out/etc \
      --with-session-bus-services-dir=$out/etc/dbus-1/services

    echo "=== DEBUG: Dumping dbus/Makefile ==="
    head -n 50 dbus/Makefile || true
    grep -C 5 '/etc/dbus-1' dbus/Makefile || true

    mkdir -p $out/debug
    cp dbus/Makefile $out/debug/dbus-Makefile
  '';


  buildPhase = ''
    make
    grep dbus-1 dbus/Makefile || true
  '';

  installFlags = [
  	"dbusservicedir=$out/etc/dbus-1/services"
  ];
  
  installPhase = "make install";
  
  meta = {
    description = "Daemon that monitors and renews certificates via CAs";
    homepage = "https://pagure.io/certmonger";
    license = pkgs.lib.licenses.gpl2Plus;
    platforms = pkgs.lib.platforms.linux;
  };
}

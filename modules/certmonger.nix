{ config, lib, pkgs, inputs, ... }:
{
  options.services.certmonger.enable = lib.mkEnableOption "Enable the certmonger certificate renewal daemon";

  config = lib.mkIf config.services.certmonger.enable {
  
    users.groups.certmonger = {};

    users.users.certmonger = {
      isSystemUser = true;
      group = "certmonger";
      home = "/var/lib/certmonger";
      createHome = false;
    };

    systemd.services.certmonger = {
      description = "Certmonger Certificate Renewal Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "dbus.service" ];
      serviceConfig = {
        ExecStart = "${inputs.certmonger.packages.${pkgs.system}.certmonger}/sbin/certmonger -f -S";
        Restart = "always";
        User = "root";
        Group = "root";
        StateDirectory = "certmonger";
	Environment = [
    	  "CERTMONGER_REQUESTS_DIR=/var/lib/certmonger/requests"
          "CERTMONGER_CAS_DIR=/var/lib/certmonger/cas"
          "CERTMONGER_LOCAL_CA_DIR=/var/lib/certmonger/local"
          "CERTMONGER_SYSTEM_LOCK_FILE=/var/lib/certmonger/lock"
        ];
      };
    };

    environment.systemPackages = [ inputs.certmonger.packages.${pkgs.system}.certmonger ];
  };
}

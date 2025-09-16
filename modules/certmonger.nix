{ config, lib, pkgs, inputs, ... }:
{
  options.services.certmonger = {
    enable = lib.mkEnableOption "Enable the certmonger certificate renewal daemon";
    ca.name = lib.mkOption {
      type = lib.types.str;
      description = "CA nickname (-c)";
    };
    ca.url = lib.mkOption {
      type = lib.types.str;
      description = "URL of the CA server's SCEP interface";
    };
    ca.certificate = lib.mkOption {
      type = lib.types.str;
      description = "PEM-formatted copy of the SCEP server's CA certificate";
    };
    cepces = {
      enable = lib.mkEnableOption "Enable cepces plugin for certmonger";
      authMechanism = lib.mkOption {
        type = lib.types.enum [ "anonymous" "kerberos" "usernamePassword" "certificate"];
        default = "kerberos";
        description = "Authentication mechanism for connecting to the service endpoint. Only Kerberos is tested at this time.";
      };
      keytab = lib.mkOption {
      	type = lib.types.str;
      	description = "Path to a Kerberos keytab. If blank, system default is used.";
      }; 
    };
  };

  config = lib.mkMerge [

   (lib.mkIf config.services.certmonger.enable {
  
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
        PreStart = ''
          mkdir -p /var/lib/certmonger/requests
          mkdir -p /var/lib/certmonger/cas
          mkdir -p /var/lib/certmonger/local
          touch /var/lib/certmonger/lock
        '';
        ExecStart = "${inputs.certmonger.packages.${pkgs.system}.certmonger}/sbin/certmonger -f -S";
        Restart = "always";
        User = "root";
        Group = "root";
        StateDirectory = "certmonger";
      };
    };

    environment.systemPackages = [
      inputs.certmonger.packages.${pkgs.system}.certmonger ]
      ++ lib.optional config.services.certmonger.cepces.enable
        inputs.certmonger.packages.${pkgs.system}.cepces;
  })
  
  (lib.mkIf config.services.certmonger.cepces.enable (
    let
      baseConfig = builtins.fromTOML (builtins.readFile "${inputs.certmonger.packages.${pkgs.system}.cepces/etc/cepces.conf}");
      modifiedConfig = baseConfig // { 
        server = config.services.certmonger.ca.name;
        endpoint = baseConfig.endpoint // config.services.certmonger.ca.url;
      
      };
    in {
  	  environment.etc."cepces/cepces.conf".source = pkgs.formats.toml.generate modifiedConfig;
  	}))
  ];
  

  /*systemd.services.configure-cepces = lib.mkIf config.services.certmonger.cepces.enable {
  	description = "Configure cepces";
  	after = [ "network.target" ];
  	wantedBy = [ "multi-user.target" ];
  	serviceConfig = {
  	  Type = "oneshot";
  	  ExecStart = '${inputs.certmonger.packages.${pkgs.system}.cepces/}'
  	    
  	      
  	  '';
  	};
  };*/


  
}

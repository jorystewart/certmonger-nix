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
      default = "https://\${server}/ADPolicyProvider_CEP_\${auth}/service.svc/CEP";
      description = "CEP server URL";
    };
    ca.certificates = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "PEM-formatted copy of the CEP server's CA certificate chain, or a directory containing it. If left blank, uses system default.";
    };
    cepces = {
      enable = lib.mkEnableOption "Enable cepces plugin for certmonger";
      authMechanism = lib.mkOption {
        type = lib.types.enum [ "Anonymous" "Kerberos" "UsernamePassword" "Certificate" ];
        default = "Kerberos";
        description = "Authentication mechanism for connecting to the service endpoint. Only Kerberos is tested at this time.";
      };
      keytab = lib.mkOption {
      	type = lib.types.str;
      	default = "";
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
      baseConfig = builtins.readFile "${inputs.certmonger.packages.${pkgs.system}.cepces}/etc/cepces.conf";

      defaultStrings = [ "server=ca" ]
        ++ lib.optional (config.services.certmonger.ca.url != "https://\${server}/ADPolicyProvider_CEP_\${auth}/service.svc/CEP") "endpoint=https://\${server}/ADPolicyProvider_CEP_\${auth}/service.svc/CEP"
        ++ lib.optional (config.services.certmonger.ca.certificates != "") "#cas="
        ++ lib.optional (config.services.certmonger.cepces.authMechanism != "Kerberos") "auth=Kerberos"
        ++ lib.optional (config.services.certmonger.cepces.keytab != "") "#keytab=";
        

      newStrings = [ "server=${config.services.certmonger.ca.name}" ]
        ++ lib.optional (config.services.certmonger.ca.url != "https://\${server}/ADPolicyProvider_CEP_\${auth}/service.svc/CEP") "endpoint=${config.services.certmonger.ca.url}" 
        ++ lib.optional (config.services.certmonger.ca.certificates != "") "cas=${config.services.certmonger.ca.certificates}"
        ++ lib.optional (config.services.certmonger.cepces.authMechanism != "Kerberos") "auth=${config.services.certmonger.cepces.authMechanism}"
        ++ lib.optional (config.services.certmonger.cepces.keytab != "") "keytab=${config.services.certmonger.cepces.keytab}";
        
        
      modifiedConfig = lib.replaceStrings defaultStrings newStrings baseConfig;
      configFile = pkgs.writeText "cepces.conf" modifiedConfig;
    in {
  	  environment.etc."cepces/cepces.conf".source = configFile;
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

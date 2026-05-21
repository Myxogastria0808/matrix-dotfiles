{ ... }:

let
  serverName = "matrix.yukiosada.work";
in
{
  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = serverName;
      public_baseurl = "https://${serverName}";
      enable_registration = false;
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            { names = [ "client" "federation" ]; compress = false; }
          ];
        }
      ];
    };
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      email r.rstudio.c@gmail.com
    '';
    virtualHosts.${serverName}.extraConfig = ''
      reverse_proxy /_matrix/* http://127.0.0.1:8008
      reverse_proxy /_synapse/client/* http://127.0.0.1:8008
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

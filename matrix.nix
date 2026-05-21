{ ... }:

let
  serverName = "matrix.yukiosada.work";
in
{
  services.matrix-conduit = {
    enable = true;
    settings.global = {
      server_name = serverName;
      port = 6167;
      database_backend = "rocksdb";
      allow_registration = false;
      allow_federation = true;
    };
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      email admin@yukiosada.work
    '';
    virtualHosts.${serverName}.extraConfig = ''
      reverse_proxy /_matrix/* http://127.0.0.1:6167
      reverse_proxy /_synapse/client/* http://127.0.0.1:6167
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

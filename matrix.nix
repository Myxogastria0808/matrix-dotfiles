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

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts.${serverName} = {
      enableACME = true;
      forceSSL = true;
      locations."/_matrix/" = {
        proxyPass = "http://127.0.0.1:6167";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 20M;
        '';
      };
      locations."/_synapse/client/" = {
        proxyPass = "http://127.0.0.1:6167";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 20M;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@yukiosada.work";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

{ pkgs, ... }:

let
  serverName = "matrix.yukiosada.work";
in
{
  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN;
      CREATE DATABASE "matrix-synapse"
        ENCODING 'UTF8'
        LC_COLLATE = 'C'
        LC_CTYPE = 'C'
        TEMPLATE template0
        OWNER "matrix-synapse";
    '';
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = serverName;
      public_baseurl = "https://${serverName}";
      enable_registration = false;
      database = {
        name = "psycopg2";
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
          host = "/var/run/postgresql";
          cp_min = 5;
          cp_max = 10;
        };
      };
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "0.0.0.0" ];
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

  # ホスト側Caddyからの接続を許可
  networking.firewall.allowedTCPPorts = [ 8008 ];
}

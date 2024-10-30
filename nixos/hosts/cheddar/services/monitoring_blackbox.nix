{ cfg, lib }:
{
  modules = {
    http_head_fast_2xx = {
      prober = "http";
      timeout = "5s";
      http = {
        method = "HEAD";
        fail_if_not_ssl = true;
      };
    };

    # A DNS probe that succeeds if bergman.house matches a known address
    home_dns = {
      prober = "dns";
      dns = {
        preferred_ip_protocol = "ip4";
        query_name = "bergman.house";
        query_type = "A";
        validate_answer_rrs = {
          fail_if_not_matches_regexp = [ (lib.strings.escapeRegex cfg.addrIPv4) ];
        };
      };
    };
  };
}

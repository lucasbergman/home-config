{ ... }:
{
  groups = [
    {
      name = "prober_home_dns";
      rules = [
        {
          record = "home_dns:probe_duration_seconds";
          expr = "probe_dns_duration_seconds{job='home_dns'}";
        }
        {
          record = "home_dns:probe_dns_query_succeeded";
          expr = "probe_dns_query_succeeded{job='home_dns'}";
        }
        {
          record = "home_dns:probe_success";
          expr = "probe_success{job='home_dns'}";
        }
        {
          alert = "HomeIPAddressChanged";
          expr = "(home_dns:probe_success == 0) and (home_dns:probe_dns_query_succeeded == 1)";
          labels = {
            severity = "mail";
          };
          annotations = {
            summary = "Home IP address has changed";
            description = "Home DNS record does not match known IP address";
          };
        }
      ];
    }
  ];
}

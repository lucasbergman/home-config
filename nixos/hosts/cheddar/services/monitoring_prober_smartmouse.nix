{ ... }:
{
  groups = [
    {
      name = "prober_smartmouse";
      rules = [
        {
          record = "smartmouse:probe_http_duration_seconds";
          expr = "probe_http_duration_seconds{job='smartmouse'}";
        }
        {
          record = "smartmouse:probe_duration_seconds";
          expr = "probe_duration_seconds{job='smartmouse'}";
        }
        {
          record = "smartmouse:probe_success";
          expr = "probe_success{job='smartmouse'}";
        }
        {
          record = "smartmouse:probe_cert_expiry_days";
          expr = "(probe_ssl_earliest_cert_expiry{job='smartmouse'} - time()) / 60 / 60 / 24";
        }
        {
          alert = "SmartmouseProberFailed";
          expr = "smartmouse:probe_success == 0";
          for = "5m";
          labels = {
            severity = "page";
          };
          annotations = {
            summary = "Main smartmousetravel.com prober failed";
            description = "Main smartmousetravel.com prober has failed for >5m";
          };
        }
        {
          alert = "SmartmouseCertExpiringSoon";
          expr = "smartmouse:probe_cert_expiry_days < 30";
          labels = {
            severity = "mail";
          };
          annotations = {
            summary = "smartmousetravel.com cert expiring soon";
            description = "smartmousetravel.com cert expiring in <30d";
          };
        }
        {
          alert = "SmartmouseCertExpiringVerySoon";
          expr = "smartmouse:probe_cert_expiry_days < 5";
          labels = {
            severity = "page";
          };
          annotations = {
            summary = "smartmousetravel.com cert expiring very soon";
            description = "smartmousetravel.com cert expiring in <5d";
          };
        }
      ];
    }
  ];
}

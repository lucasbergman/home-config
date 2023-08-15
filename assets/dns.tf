#
# bergmans.us
#

resource "google_dns_managed_zone" "bergmans" {
  name        = "bergmans"
  dns_name    = "bergmans.us."
  description = "bergmans.us"
}

resource "google_dns_record_set" "bergmans_ns" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = google_dns_managed_zone.bergmans.dns_name
  type         = "NS"
  rrdatas = [
    "ns-cloud-c1.googledomains.com.",
    "ns-cloud-c2.googledomains.com.",
    "ns-cloud-c3.googledomains.com.",
    "ns-cloud-c4.googledomains.com.",
  ]
  ttl = 21600
}

resource "google_dns_record_set" "bergmans_soa" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = google_dns_managed_zone.bergmans.dns_name
  type         = "SOA"
  rrdatas      = ["ns-cloud-c1.googledomains.com. cloud-dns-hostmaster.google.com. 2 21600 3600 259200 300"]
  ttl          = 21600
}

#
# bergman.house
#

resource "google_dns_managed_zone" "bergmanhouse" {
  name        = "bergmanhouse"
  dns_name    = "bergman.house."
  description = "bergman.house"
}

resource "google_dns_record_set" "bergmanhouse_ns" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = google_dns_managed_zone.bergmanhouse.dns_name
  type         = "NS"
  rrdatas = [
    "ns-cloud-b1.googledomains.com.",
    "ns-cloud-b2.googledomains.com.",
    "ns-cloud-b3.googledomains.com.",
    "ns-cloud-b4.googledomains.com.",
  ]
  ttl = 21600
}

resource "google_dns_record_set" "bergmanhouse_soa" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = google_dns_managed_zone.bergmanhouse.dns_name
  type         = "SOA"
  rrdatas      = ["ns-cloud-b1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"]
  ttl          = 21600
}

resource "google_dns_record_set" "bergmanhouse_srv_matrix" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "_matrix._tcp.bergman.house."
  type         = "SRV"
  rrdatas      = ["10 0 443 matrix.bergman.house."]
  ttl          = 300
}

#
# blurt.chat
#

resource "google_dns_managed_zone" "blurt" {
  name        = "blurt"
  dns_name    = "blurt.chat."
  description = "blurt.chat"
}

resource "google_dns_record_set" "blurt_ns" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = google_dns_managed_zone.blurt.dns_name
  type         = "NS"
  rrdatas = [
    "ns-cloud-a1.googledomains.com.",
    "ns-cloud-a2.googledomains.com.",
    "ns-cloud-a3.googledomains.com.",
    "ns-cloud-a4.googledomains.com.",
  ]
  ttl = 21600
}

resource "google_dns_record_set" "blurt_soa" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = google_dns_managed_zone.blurt.dns_name
  type         = "SOA"
  rrdatas      = ["ns-cloud-a1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"]
  ttl          = 21600
}

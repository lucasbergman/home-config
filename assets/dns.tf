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

resource "google_dns_record_set" "bergmans_mx" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = google_dns_managed_zone.bergmans.dns_name
  type         = "MX"
  rrdatas      = ["10 mail.bergmans.us."]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_a_mail" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "mail.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_txt" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = google_dns_managed_zone.bergmans.dns_name
  type         = "TXT"
  rrdatas = [
    "\"google-site-verification=DYzhaKYuvnbDIayaFdYl9m9OfzEZsMOWQggj0jujG38\"",
    "\"google-site-verification=euMnMSULQKzf2y2fKSF-3N3DpJaY8QjgNO_4ItxgG9M\"",
    "\"keybase-site-verification=oh8jpluTkVNxsrqj2A90qoKDhPY3SOCJjQJhkp6v9Tc\"",
    "\"v=spf1 mx include:amazonses.com include:_spf.google.com ~all\"",
  ]
  ttl = 3600
}

# TODO: Delete this when POP3 clients are moved to pop.bergmans.us
resource "google_dns_record_set" "bergmans_a_greywind" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "greywind.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
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

resource "google_dns_record_set" "bergmanhouse_mx" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = google_dns_managed_zone.bergmanhouse.dns_name
  type         = "MX"
  rrdatas      = ["10 mail.bergman.house."]
  ttl          = 1800
}

resource "google_dns_record_set" "bergmanhouse_a_mail" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "mail.bergman.house."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 1800
}

resource "google_dns_record_set" "bergmanhouse_srv_matrix" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "_matrix._tcp.bergman.house."
  type         = "SRV"
  rrdatas      = ["10 0 443 matrix.bergman.house."]
  ttl          = 300
}

resource "google_dns_record_set" "bergmanhouse_a" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = google_dns_managed_zone.bergmanhouse.dns_name
  type         = "A"
  rrdatas      = [var.slb_house_ipv4]
  ttl          = 300
}

resource "google_dns_record_set" "bergmanhouse_txt" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = google_dns_managed_zone.bergmanhouse.dns_name
  type         = "TXT"
  rrdatas = [
    "\"keybase-site-verification=yqOuTyKp0FzHtSIG_9dMEEzaibRJWvhqATJhZTOlYuU\"",
    "\"v=spf1 mx include:amazonses.com include:_spf.google.com ~all\"",
  ]
  ttl = 300
}

resource "google_dns_record_set" "bergmanhouse_cname" {
  for_each     = toset(["hass", "hedwig", "metrics", "plex"])
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "${each.value}.bergman.house."
  type         = "CNAME"
  rrdatas      = ["bergman.house."]
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

resource "google_dns_record_set" "blurt_a" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = "blurt.chat."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 1800
}

resource "google_dns_record_set" "blurt_mx" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = google_dns_managed_zone.blurt.dns_name
  type         = "MX"
  rrdatas      = ["10 mail.blurt.chat."]
  ttl          = 1800
}

resource "google_dns_record_set" "blurt_a_mail" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = "mail.blurt.chat."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 1800
}

resource "google_dns_record_set" "blurt_txt" {
  managed_zone = google_dns_managed_zone.blurt.name
  name         = google_dns_managed_zone.blurt.dns_name
  type         = "TXT"
  rrdatas = [
    "\"v=spf1 mx include:amazonses.com include:_spf.google.com ~all\"",
  ]
  ttl = 300
}

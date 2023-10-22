# SES password for mail submission
resource "google_secret_manager_secret" "mail_ses_password" {
  secret_id = "mail-ses-password"
  replication {
    auto {}
  }
}

# User names and (hashed) passwords for mail server users
resource "google_secret_manager_secret" "mail_userdb" {
  secret_id = "mail-userdb"
  replication {
    auto {}
  }
}

# SES for bergman.house
resource "aws_ses_domain_identity" "bergmanhouse" {
  domain = "bergman.house"
}

resource "aws_ses_domain_dkim" "bergmanhouse" {
  domain = aws_ses_domain_identity.bergmanhouse.domain
}

resource "google_dns_record_set" "bergmanhouse_ses_dkim" {
  count        = 3
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "${aws_ses_domain_dkim.bergmanhouse.dkim_tokens[count.index]}._domainkey.bergman.house."
  type         = "CNAME"
  rrdatas      = ["${aws_ses_domain_dkim.bergmanhouse.dkim_tokens[count.index]}.dkim.amazonses.com."]
  ttl          = 3600
}

# SES for bergmans.us
resource "aws_ses_domain_identity" "bergmans" {
  domain = "bergmans.us"
}

resource "aws_ses_domain_dkim" "bergmans" {
  domain = aws_ses_domain_identity.bergmans.domain
}

resource "google_dns_record_set" "bergmans_ses_dkim" {
  count        = 3
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "${aws_ses_domain_dkim.bergmans.dkim_tokens[count.index]}._domainkey.bergmans.us."
  type         = "CNAME"
  rrdatas      = ["${aws_ses_domain_dkim.bergmans.dkim_tokens[count.index]}.dkim.amazonses.com."]
  ttl          = 3600
}

# SES for blurt.chat
resource "aws_ses_domain_identity" "blurt" {
  domain = "blurt.chat"
}

resource "aws_ses_domain_dkim" "blurt" {
  domain = aws_ses_domain_identity.blurt.domain
}

resource "google_dns_record_set" "blurt_ses_dkim" {
  count        = 3
  managed_zone = google_dns_managed_zone.blurt.name
  name         = "${aws_ses_domain_dkim.blurt.dkim_tokens[count.index]}._domainkey.blurt.chat."
  type         = "CNAME"
  rrdatas      = ["${aws_ses_domain_dkim.blurt.dkim_tokens[count.index]}.dkim.amazonses.com."]
  ttl          = 3600
}

# Inbound mail delivery for smartmousetravel.com
resource "google_dns_record_set" "smartmouse_a_mail" {
  managed_zone = "smartmouse"
  project      = "smartmouse-web"
  name         = "mail.smartmousetravel.com."
  type         = "A"
  rrdatas      = [var.slb_greywind_ipv4]
  ttl          = 300
}

resource "google_dns_record_set" "smartmouse_mx" {
  managed_zone = "smartmouse"
  project      = "smartmouse-web"
  name         = "smartmousetravel.com."
  type         = "MX"
  rrdatas      = ["10 mail.smartmousetravel.com."]
  ttl          = 300
}

# SES for smartmousetravel.com
resource "aws_ses_domain_identity" "smartmouse" {
  domain = "smartmousetravel.com"
}

resource "aws_ses_domain_dkim" "smartmouse" {
  domain = aws_ses_domain_identity.smartmouse.domain
}

resource "google_dns_record_set" "smartmouse_ses_dkim" {
  count        = 3
  managed_zone = "smartmouse"
  project      = "smartmouse-web"
  name         = "${aws_ses_domain_dkim.smartmouse.dkim_tokens[count.index]}._domainkey.smartmousetravel.com."
  type         = "CNAME"
  rrdatas      = ["${aws_ses_domain_dkim.smartmouse.dkim_tokens[count.index]}.dkim.amazonses.com."]
  ttl          = 3600
}

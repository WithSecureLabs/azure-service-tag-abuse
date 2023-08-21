data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "random_string" "lab_id" {
  length  = 4
  special = false
  upper   = false
}

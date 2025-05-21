variable "awin_password" {}
variable "jpo_password" {}
variable "fbl_password" {}
variable "dmarc_reports_password" {}

variable "john_password" {}
variable "jane_password" {}
variable "test_password" {}
variable "demo_password" {}

resource "local_file" "james_initialize_sh" {
  filename = "james_initialize.sh"
  content = replace(<<EOF
echo "Initializing James server..."
docker exec james bash -c "james-cli AddDomain awin.dk"
docker exec james bash -c "james-cli AddUser awin@awin.dk ${awin_password}"
docker exec james bash -c "james-cli AddUser jpo@awin.dk ${jpo_password}"
docker exec james bash -c "james-cli AddUser dmarc-reports@awin.dk ${dmarc_reports_password}"
docker exec james bash -c "james-cli AddUser fbl@awin.dk ${fbl_password}"

docker exec james bash -c "james-cli AddUser john@awin.dk ${john_password}"
docker exec james bash -c "james-cli AddUser jane@awin.dk ${jane_password}"
docker exec james bash -c "james-cli AddUser test@awin.dk ${test_password}"
docker exec james bash -c "james-cli AddUser demo@awin.dk ${demo_password}"
EOF
, "\r", "")
}

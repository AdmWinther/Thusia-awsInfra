variable "domain_name" {}

variable "admin_password" {}
variable "awin_password" {}
variable "crm_password" {}
variable "joomla_password" {}
variable "wordpress_password" {}
variable "api_joomla_password" {}
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
docker exec james bash -c "james-cli AddDomain ${var.domain_name}"
docker exec james bash -c "james-cli AddUser admin@${var.domain_name} ${var.admin_password}"
docker exec james bash -c "james-cli AddUser awin@${var.domain_name} ${var.awin_password}"
docker exec james bash -c "james-cli AddUser crm@${var.domain_name} ${var.crm_password}"

docker exec james bash -c "james-cli AddUser jpo@${var.domain_name} ${var.jpo_password}"
docker exec james bash -c "james-cli AddUser dmarc-reports@${var.domain_name} ${var.dmarc_reports_password}"
docker exec james bash -c "james-cli AddUser fbl@${var.domain_name} ${var.fbl_password}"
docker exec james bash -c "james-cli AddUser joomla@${var.domain_name} ${var.joomla_password}"
docker exec james bash -c "james-cli AddUser wordpress@${var.domain_name} ${var.wordpress_password}"
docker exec james bash -c "james-cli AddUser api_joomla@${var.domain_name} ${var.api_joomla_password}"

docker exec james bash -c "james-cli AddUser john@${var.domain_name} ${var.john_password}"
docker exec james bash -c "james-cli AddUser jane@${var.domain_name} ${var.jane_password}"
docker exec james bash -c "james-cli AddUser test@${var.domain_name} ${var.test_password}"
docker exec james bash -c "james-cli AddUser demo@${var.domain_name} ${var.demo_password}"
EOF
, "\r", "")
}

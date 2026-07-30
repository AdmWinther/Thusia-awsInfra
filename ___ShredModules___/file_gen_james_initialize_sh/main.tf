variable "domain_name" {}

variable "admin_password" {}
variable "crm_password" {}
variable "joomla_password" {}
variable "api_joomla_password" {}
variable "fbl_password" {}
variable "dmarc_reports_password" {}


resource "local_file" "james_initialize_sh" {
  filename = "james_initialize.sh"
  content = replace(<<EOF
echo "Initializing James server..."
docker exec james bash -c "james-cli AddDomain ${var.domain_name}"
docker exec james bash -c "james-cli AddUser admin@${var.domain_name} ${var.admin_password}"
docker exec james bash -c "james-cli AddUser crm@${var.domain_name} ${var.crm_password}"

docker exec james bash -c "james-cli AddUser dmarc-reports@${var.domain_name} ${var.dmarc_reports_password}"
docker exec james bash -c "james-cli AddUser fbl@${var.domain_name} ${var.fbl_password}"
docker exec james bash -c "james-cli AddUser joomla@${var.domain_name} ${var.joomla_password}"
docker exec james bash -c "james-cli AddUser api_joomla@${var.domain_name} ${var.api_joomla_password}"

EOF
, "\r", "")
}

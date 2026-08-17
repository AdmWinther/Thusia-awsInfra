variable "New_Mail_Request_Secret_key" {}
variable "domain_name" {}
variable "joomla_components_path" {}

# Both components read the same two keys, so one template serves both. Keeping it in a
# single local guarantees the shared HMAC secret cannot drift between the two files.
locals {
  configuration_content = replace(<<EOF
<?php
defined('_JEXEC') or die;

return [
    'backend_url' => 'https://api.${var.domain_name}/maskemails',
    'secretKey' => '${var.New_Mail_Request_Secret_key}'
];
EOF
  , "\r", "")
}

# NOTE: filename is resolved against the directory terraform runs in (the repo root),
# not this module's directory. joomla_components_path must end with a slash.
resource "local_file" "newemailform_configuration" {
  filename             = "${var.joomla_components_path}JoomlaComponent_NewEmailForm_JV4/site/src/configuration/com_newemailformconfiguration.php"
  content              = local.configuration_content
  file_permission      = "0600"
  directory_permission = "0755"
}

resource "local_file" "maskemailslist_configuration" {
  filename             = "${var.joomla_components_path}JoomlaComponent_MaskEmailsList/site/src/configuration/com_maskemailslistconfiguration.php"
  content              = local.configuration_content
  file_permission      = "0600"
  directory_permission = "0755"
}
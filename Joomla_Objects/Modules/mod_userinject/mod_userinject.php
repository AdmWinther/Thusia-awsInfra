<?php
// No direct access
defined('_JEXEC') or die;

require_once __DIR__ . '/helper.php';

$doc = JFactory::getDocument();
$jsVar = UserInjectHelper::getUsernameJS();
$doc->addScriptDeclaration($jsVar);

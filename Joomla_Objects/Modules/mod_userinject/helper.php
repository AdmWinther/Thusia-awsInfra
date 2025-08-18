<?php
defined('_JEXEC') or die;

class UserInjectHelper
{
    public static function getUsernameJS()
    {
        $user = JFactory::getUser();
        $username = addslashes($user->username);
        return "const joomlaUsername = \"$username\";";
    }
}

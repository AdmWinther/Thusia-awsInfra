<?php
defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\Table\Table;
use Joomla\CMS\Log\Log;

class com_signupformInstallerScript
{
    public function install($parent)
    {
        // Debug marker to confirm execution
        file_put_contents(
            JPATH_ROOT . '/logs/signup_debug.txt',
            ">>> script.php install() executed at " . date('c') . "\n",
            FILE_APPEND
        );


        Log::add('>>> com_signupform script.php executed install()', Log::INFO, 'jerror');

        $db = Factory::getDbo();

        // Get the component ID for com_signupform
        $query = $db->getQuery(true)
            ->select($db->quoteName('extension_id'))
            ->from($db->quoteName('#__extensions'))
            ->where($db->quoteName('element') . ' = ' . $db->quote('com_signupform'));
        $db->setQuery($query);
        $componentId = (int) $db->loadResult();

        if (!$componentId) {
            Factory::getApplication()->enqueueMessage('Component ID not found, menu not created.', 'error');
            return;
        }

        // Prepare menu table row
        $menu = Table::getInstance('Menu');
        $menu->title       = 'Signup';
        $menu->alias       = 'signup_';
        $menu->path        = 'signup';
        $menu->link        = 'index.php?option=com_signupform';
        $menu->type        = 'component';
        $menu->published   = 1;
        $menu->parent_id   = 1;              // top-level
        $menu->component_id = $componentId;
        $menu->menutype    = 'mainmenu';     // your main menu type
        $menu->access      = 1;              // Public
        $menu->language    = '*';
        $menu->client_id   = 0;

        try {
            $menu->store();
        } catch (\Exception $e) {
            Factory::getApplication()->enqueueMessage('Menu not created: ' . $e->getMessage(), 'error');
        }
    }
}

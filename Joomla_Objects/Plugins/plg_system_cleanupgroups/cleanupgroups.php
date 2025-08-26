<?php
/**
 * @package     Joomla.Plugin
 * @subpackage  System.cleanupgroups
 *
 * Plugin Name: Cleanup Groups
 * Description: Removes unnecessary Joomla user groups on install/enable
 * Version:     1.0
 * Author:      Adam Winther
 */

use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\CMS\Factory;

defined('_JEXEC') or die;

class PlgSystemCleanupgroups extends CMSPlugin
{
    public function onAfterInitialise()
    {
        $db = Factory::getDbo();

        // List of group titles you want to remove
        $groupsToDelete = ['Manager', 'Administrator', 'Author', 'Editor', 'Publisher'];

        foreach ($groupsToDelete as $groupTitle) {
            $query = $db->getQuery(true)
                ->select('id')
                ->from($db->quoteName('#__usergroups'))
                ->where($db->quoteName('title') . ' = ' . $db->quote($groupTitle));
            $db->setQuery($query);
            $groupId = $db->loadResult();

            if ($groupId) {
                // Delete the group
                $query = $db->getQuery(true)
                    ->delete($db->quoteName('#__usergroups'))
                    ->where($db->quoteName('id') . ' = ' . (int) $groupId);
                $db->setQuery($query);
                $db->execute();
            }
        }
    }
}

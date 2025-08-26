<?php
 /**
  * @package     Joomla.Administrator
  * @subpackage  com_signupform
  *
  * @copyright   Copyright (C) 2005 - 2018 Open Source Matters, Inc. All rights reserved.
  * @license     GNU General Public License version 2 or later; see LICENSE.txt
  */

 // No direct access to this file
 defined('_JEXEC') or die('Restricted access');

 // Get an instance of the controller prefixed by signupForm
 $controller = JControllerLegacy::getInstance('Signupform');

 // Perform the Request task
 //If no task is set, the default task 'display' will be assumed.
 //When display is used, the 'view' variable will decide what will be displayed.
 $input = JFactory::getApplication()->input;
 $controller->execute($input->getCmd('task'));

 // Redirect if set by the controller
 $controller->redirect();
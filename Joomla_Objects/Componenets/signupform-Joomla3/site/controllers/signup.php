<?php
defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\FormController;
use Joomla\CMS\Factory;
use Joomla\CMS\Router\Route;

class SignupformControllerSignup extends FormController
{
    public function forward($key = null, $urlVar = null)
    {
        jimport('joomla.application.component.controller');
        echo "<pre>";
        print_r($_POST);  // dump submitted form
        echo "</pre>";
        die("✅ Forward() controller method executed");
//         $app = Factory::getApplication();  // ✅ define $app first
//
//         // Debug 1: enqueueMessage
//         $app->enqueueMessage('✅ SignupController::forward() reached!', 'message');
//
//         // Debug 2: grab POST data
//         $data = $app->input->post->getArray();
//         $app->enqueueMessage('Form data: ' . print_r($data, true), 'notice');
//
//         //debug 2.3: Browser console log
//         $app->enqueueMessage('<script>console.log("forward() hit");</script>', 'message');
//
//         // Debug 3: log into Docker logs
//         error_log("SignupController::forward() got data: " . print_r($data, true));
//
//         //debug 4: write to joomla debug log file
//         \Joomla\CMS\Log\Log::add('forward() hit, data: ' . json_encode($_POST), \Joomla\CMS\Log\Log::DEBUG, 'com_signupform');
//
//
//         //Redirect after processing
         $this->setRedirect(JRoute::_('index.php? ', false));
//         //$this->setRedirect(Route::_('index.php?option=com_signupform', false));
    }
}

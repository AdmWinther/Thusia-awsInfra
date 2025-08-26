<?php
namespace Joomla\Component\Signupform\Administrator\View\Signup;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\View\HtmlView as BaseHtmlView;

class HtmlView extends BaseHtmlView
{
    public function display($tpl = null)
    {
        // Example data for debugging
        $this->msg = "Admin view working!";

        parent::display($tpl);
    }
}

<?php
defined('_JEXEC') or die;

use Joomla\CMS\Router\Route;

$user = JFactory::getUser();
?>



<?php if (!$user->guest): ?>
    <p>You do not need to login to see this form.</p>
<?php else: ?>

    <div class="row justify-content-center">
        <!-- form class="col-lg-4" action="index.php?option=com_signupform&task=signup.forward" method="post" -->
        <form class="col-lg-4" action="<?php echo JRoute::_('index.php?task=signup.forward'); ?>" method="post" name="signupForm" id="signupForm">
            <h2>Sign Up Form</h2>

            <label class="required form-label invalid" for="mydata">First Name:</label>
            <input type="text" name="firstName" id="firstName" required>
            </br>

            <label class="required form-label invalid" for="mydata">Last Name:</label>
            <input type="text" name="lastName" id="lastName" required>
            </br>

            <label class="required form-label invalid" for="mydata">Email Address:</label>
            <input type="text" name="emailAddress" id="emailAddress" required>
            </br>

            <label class="required form-label invalid" for="mydata">Password:</label>
            <input type="password" name="password" id="password" required>
            </br>

            <button class="btn btn-primary btn-lg w-100" type="submit">Send</button>

            <!-- Always include form.token to protect against CSRF.-->
            <p><?php echo JHtml::_('form.token'); ?></p>
            <?php echo JHtml::_('form.token'); ?>
        </form>
    </div>
<?php endif; ?>

<?php
defined('_JEXEC') or die;

use Joomla\CMS\Router\Route;

$user = $this->user;
?>

<h2>New Email Form</h2>

<?php if ($user->guest): ?>
    <p>You must be logged in to submit this form.</p>
<?php else: ?>
    <form action="<?php echo Route::_('index.php?option=com_newemailform&task=form.submit'); ?>" method="post">
        <label for="mydata">Data:</label>
        <input type="text" name="mydata" id="mydata" required>
        <button type="submit">Send</button>
        <?php echo JHtml::_('form.token'); ?>
    </form>
<?php endif; ?>

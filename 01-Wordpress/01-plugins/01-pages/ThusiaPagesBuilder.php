<?php
/*
Plugin Name: Thusia Pages Builder
Author: Adam Winther
Description: Automatically creates Home, What is Email Mask, Why you need Email mask, Sign up, and Login with images.
Version: 1.0
*/

function adam_create_pages_on_activate() {
    $pages = [
        'Home' => 'Welcome to our website! <img src="' . plugin_dir_url(__FILE__) . 'images/home.jpg" />',
        'What is Email Mask' => 'This is the a page to tell you What is Email Mask. <img src="' . plugin_dir_url(__FILE__) . 'images/WhatIsEmailMask.jpg" />',
        'Why You Need Email Mask' => 'Ok, we are going to show you, Why you need Email Mask! <img src="' . plugin_dir_url(__FILE__) . 'images/WhyYouNeedEmailMask.jpg" />',
        'Sign Up' => 'Join us today! <img src="' . plugin_dir_url(__FILE__) . 'images/WhyYouNeedEmailMask.jpg" />',
        'Login' => 'Welcome back! <img src="' . plugin_dir_url(__FILE__) . 'images/WhyYouNeedEmailMask.jpg" />',
    ];

    foreach ($pages as $title => $content) {
        // Check if page already exists
        $check = get_page_by_title($title, OBJECT, 'page');
        if (!$check) {
            wp_insert_post([
                'post_title'   => $title,
                'post_content' => $content,
                'post_status'  => 'publish',
                'post_type'    => 'page'
            ]);
        }
    }
}
register_activation_hook(__FILE__, 'adam_create_pages_on_activate');

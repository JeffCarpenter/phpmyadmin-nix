<?php
$cfg['blowfish_secret'] = getenv('PMA_BLOWFISH_SECRET') ?: '';
$cfg['AllowArbitraryServer'] = true;

$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['host'] = 'custom';
$cfg['Servers'][1]['AllowNoPassword'] = true;
?>

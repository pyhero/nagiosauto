<?php
$name = $_POST['name'];
$lo_pub = $_POST['lo_pub'];
$re_pub = $_POST['re_pub'];
$lo_pri = $_POST['lo_pri'];
$re_pri = $_POST['re_pri'];
file_put_contents('/ROOT/conf/nginx/static/data/tuninfo', $name." ".$lo_pub." ".$re_pub." ".$lo_pri." ".$re_pri."\n",FILE_APPEND);

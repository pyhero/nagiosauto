<?php
$ip = $_POST['clientips'];
$privkey = $_POST['privkey'];
$authkey = $_POST['authkey'];

$path = '/ROOT/conf/nginx/static/data/';
$snmp_file = 'snmpd.xml';
$fp = fopen("$path"."$snmp_file", 'r+')or die("文件打开失败");
fseek($fp, -10, SEEK_END);
fwrite($fp, "<device ip=\"$ip\" authkey=\"$authkey\" privkey=\"$privkey\" version=\"3\" />\n");
fwrite($fp, "</config>\n");
fclose($fp);

$ip_file = date('Ymd').'.ip';
$fp = fopen("$path"."$ip_file",'a+');
fseek($fp, -0, SEEK_END);
fwrite($fp, "$ip\n");
fclose($fp);

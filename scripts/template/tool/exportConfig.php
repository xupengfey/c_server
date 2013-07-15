<?php    
	$tabNameObj = array(
		"tpl_city",
		"tpl_citycell",
		"tpl_citycell_creature",
		"tpl_card",
		"tpl_hero",
		"tpl_magic",
		"tpl_skill"
		);


	$serverAddr = "192.168.99.200";
	$user = "root";
	$pass = "root";
	

	
	$dbName = "game_tpl";
	$lang = 1;
	$langSet = array();
	$langSet[1] = "";
	$langSet[2] = "zhTW_";
	$langSet[3] = "enUS_";
	
	
	set_time_limit(10000000);	
	mysql_connect($serverAddr,$user,$pass);
	mysql_select_db($dbName);
	mysql_query("set names UTF8");
	mysql_query("set interactive_timeout=24*3600");
	mysql_query("set wait_timeout=24*3600");
	
	$SERVER_TEMPLATE_DIR = "../data/";
?>

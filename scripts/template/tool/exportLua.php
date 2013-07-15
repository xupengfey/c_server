<?php
    require("exportConfig.php");
	foreach ($tabNameObj as $tbid => $tbname) { 
		$sql="select * from $tbname";
		$result=mysql_query($sql);
		if (!$result) {
			echo "sql wrong:".$tbid.$tbname;
			exit();
		}
		
		//输出文件头部
		$content="module(\""."template.data.".substr($tbname,4)."\")\n";
		$content.="data = {\n";

		while ($row = mysql_fetch_assoc($result)) {
		  
			$content.="[".$row["id"]."]={";
			$id = 0;
			//输出本地化字段
			foreach($row as $k=>$v)
			{
				if($langSet[$lang] != ""){
					$pos = strpos($k, $langSet[$lang]); //
					if($pos !== false){
						// echo "exchange col  ".$k."\n";
						$row[substr($k,5)] = $v;
					}
				}
			}
			
			foreach ($row as $k=>$v)
			{
				$isLangCol = false;
				foreach($langSet as $kk=>$vv){
					if($vv != ""){
						$tmpos = strpos($k, $vv);
						if($tmpos !== false){
							$isLangCol = true;
						}
					}
				}
				if($isLangCol == false){
					$fieldType = mysql_field_type($result,$id);
					$id = $id + 1;
					if (is_string($v)) {
						$v = str_replace("\r","",$v);
						$v = str_replace("\n","\\n",$v);
					}
					
					if (($fieldType == "int") or ($fieldType == "real")) {
						$content.=$k." = $v,";
					}
					else {
						$content.=$k." = '$v',";
					}
				}
			}
			//去掉末尾的逗号
			$content = substr($content,0,strlen($content)-1);
			$content.="},\n";
		}
		$content.="}\n";

		if( file_put_contents($SERVER_TEMPLATE_DIR.substr($tbname,4).".lua",$content) ){
			echo $tbname," success<br>\n";
		}
		else{
			echo $tbname," error<br>\n";
		}
	}
	
	//输出
	$reqAll = "";
	foreach ($tabNameObj as $tbid => $tbname) { 
		$reqAll .="local " . substr($tbname,4) ." = require(\"template.data.".substr($tbname,4)."\")\n";
	}
	
	$reqAll .= "module(\"template.data.gametemplate\")\n";
	$reqAll .= "gameTemplate = {}\n";
	
	foreach ($tabNameObj as $tbid => $tbname) { 
		$reqAll .= "gameTemplate[\"".substr($tbname,4)."\"] =".substr($tbname,4).".data\n";
	}
	
	$reqAll .= "return gameTemplate\n";
	
	file_put_contents($SERVER_TEMPLATE_DIR."gametemplate.lua",$reqAll);
	
	echo "Template output finished.\n";
	
?>
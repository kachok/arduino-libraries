<!--
Sample server-side script for demonstrating WiFly_Get example.
No elegance, sophistication or grace is purported in this script.
Use at your own risk.

And make sure you have read/write access to /tmp

Install in your apache server's cgi-bin folder, with appropriate permissions (read-execute)

Copyright(c) 2011 Tom Waldock
LGPL 2.1

-->
<form action="userprog_get.php" method="get">
Counter: <input type="text" name="counter" />
Value: <input type="text" name="value" />
<input type="submit" />
</form> 


<?php
$model_file_name="/tmp/WiFly_Get.txt";
$my_counter=$_GET["counter"];
$my_value=$_GET["value"];

if (strlen($my_counter) > 0 ) 
{
  echo "Counter is: $my_counter";
  echo ".<br />";
  echo "And the value is: $my_value";   
  $my_date=date(DATE_RFC822);
  $model_file=fopen($model_file_name,"w+");
  fwrite($model_file, "$my_counter,$my_value,$my_date");
  fclose($model_file);
}
else
{
  echo "No counter value found:  Parameters are ?counter=nn&value=vvv<br/>";
  $model_file=fopen($model_file_name,"r");
  $last_update=fgetcsv($model_file);
  echo "Counter		Value		Date<br/>";
  echo "$last_update[0]	$last_update[1]	$last_update[2] $last_update[3]<br/>";
  fclose($model_file);
}
?>


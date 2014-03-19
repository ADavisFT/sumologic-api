
Perl implementation of the sumologic Collector-Management-API

Configuration file required.
cat sumo.cfg
[sumologic]
 user="adavis\@site.com:sumopasswd"


Running the script
run  sumologic.pl from same folder as ypur config file 

Search
PC-1#   ./sumologic.pl -s ma_sandbox
id: 100022346 Host: ma_sandbox_app_i_d4fa
id: 100022428 Host: ma_sandbox_app_i_c9ec
id: 100023236 Host: ma_sandbox_app_i_5c7e
id: 100023239 Host: ma_sandbox_app_i_bc9d


List  log sources configured for all your collectors returned by the search 
PC-1# ./sumologic.pl -v ma_sandbox_app_i_5e

ma_sandbox_app_i_5e
	Chef Client Log: /var/log/chef/chef-client.log
	Cron: /var/log/cron.log
	Nginx Access Log: /mnt/ma/shared/log/nginx-proxy.log
	Rails Application Log: /mnt/ma/shared/log/production.log
	Secure: /var/log/auth.log
	Syslog File: /var/log/syslog

Add a new source for all returned by your search 
Only Nginx and rails (passenger) at the moment till I have time to add more. 

PC-1#  ./sumologic.pl -s ma_sandbox_app_i_5e  -add nginx
Enter path or "/mnt/app/shared/log/nginx*.log" will be used  : 
ma_sandbox_app_i_5e source nginx added 

It gives you the option of changing the path as some applications have a different path structure 


For help 

./sumologic.pl -h

 USAGE: ./sumologic.pl 
-s <search string>   #search collectors  
 		 -v <search string>                  #view sources 
 		  -add [nginx | rails ]                 #add nginx or rails log
 		 ./sumologic.pl -h

 

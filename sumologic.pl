#!/usr/bin/perl

#use strict;
#use warnings;
use JSON::XS;
use LWP::UserAgent;
use Data::Dumper;
use Config::Simple;
use Getopt::Long;
use REST::Client;
use MIME::Base64;
use JSON;

my $cfg = new Config::Simple('sumo.cfg');

my $endpoint = "api.sumologic.com";
my $userpass = $cfg->param('sumologic.user');

my $usage="\n USAGE: $0 \n\t\t -s <search string> #search collectors  \n \t\t -v <search string> #view sources \n \t\t  -add [nginx | rails ] \n \t\t $0 -h\n";

# check if script has been invoked with options
if (! @ARGV) { print $usage;exit(1)}

my $search;
my $help;

Getopt::Long::GetOptions(
   's=s' => \$search,
   'v=s' => \$view,
   'add=s' => \$add,
   'h' => \$help,
   );

if ($help){ print $usage; exit(0) }

   if (defined $add){
        &sumo_add($search, $add);
   }elsif (defined $view){
        &sumo_view($view);
   }elsif (defined $search){
        &sumo_search($search);
   }else{
        print "Invalid. No option givin please check options -h\n";
        exit(1);
   }

sub sumo_search(){
	my $search= $_[0];
	chomp($search);
	my $client = REST::Client->new( );
	$client->setHost( "https://$endpoint" );
	$client->addHeader( "Authorization", "Basic ".encode_base64( $userpass ) );

	$client->GET( "/api/v1/collectors" );
	$out=Dumper($client);
	@out=split(/\n/,$out);

	while($_= shift @out){
                	$_=~s/\s+/ /g;$_=~s/^\s+//g;
        	if($_=~/\"id\":/){
                	$_=~s/\"id\":(.+),/$1/;
                	$id=$_;
        	}
        	if($_=~/\"name\":/){
                	$_=~s/\"name\":"(.+)",/$1/;
                	$collectors{$id} = $_;

        	}
	}

 	foreach (sort keys %collectors) {
        	if($collectors{$_}=~/$search/){
    			print "id: $_ Host: $collectors{$_}\n";
 		}
	}
}


sub sumo_view(){
        my $view= $_[0];
        chomp($view);
	
    	my $client = REST::Client->new( );
        $client->setHost( "https://$endpoint" );
        $client->addHeader( "Authorization", "Basic ".encode_base64( $userpass ) );

	$client->GET( "/api/v1/collectors" );
	$out=Dumper($client);
	@out=split(/\n/,$out);

	while($_= shift @out){
               	$_=~s/\s+/ /g;$_=~s/^\s+//g;
        	if($_=~/\"id\":/){
                	$_=~s/\"id\":(.+),/$1/;
                	$id=$_;
        	}
        	if($_=~/\"name\":/){
                	$_=~s/\"name\":"(.+)",/$1/;
                	$collectors{$id} = $_;

        		}
	}

	foreach (sort keys %collectors) {
		  if($collectors{$_}=~/$view/){
			print "\n$collectors{$_}\n";
			$client->GET( "/api/v1/collectors/$_/sources");
			$out=Dumper($client);
			@out=split(/\n/,$out);

			while($_= shift @out){
				$_=~s/\s+/ /g;$_=~s/^\s+//g;
				if($_=~/\"name\":/){
                			$_=~s/\"name\":"(.+)",/$1/;
                			print "\t$_: ";
				}
				if($_=~/\"pathExpression\":/){
			                $_=~s/\"pathExpression\":"(.+)",/$1/;
                			print  "$_\n";
        			}

			
			}

        	}
	}		

}

sub sumo_add(){
        my $search= $_[0];
        chomp($search);
	if(length $search <= 0){print "you must specify a search criteria when adding\n";exit;};
        my $add= $_[1];
        chomp($add);

        my $client = REST::Client->new( );
        $client->setHost( "https://$endpoint" );
        $client->addHeader( "Authorization", "Basic ".encode_base64( $userpass ) );

	$client->GET( "/api/v1/collectors" );
	$out=Dumper($client);
	@out=split(/\n/,$out);

	while($_= shift @out){
                $_=~s/\s+/ /g;$_=~s/^\s+//g;
       	    if($_=~/\"id\":/){
                $_=~s/\"id\":(.+),/$1/;
                $id=$_;
       	    }
           if($_=~/\"name\":/){
                $_=~s/\"name\":"(.+)",/$1/;
                $collectors{$id} = $_;

           }
	}
	$count=0;
 	foreach (sort keys %collectors) {
        	if($collectors{$_}=~/$search/){
			if($add=~/^nginx$/){
				if($count == 0){
					print "Enter path or \"/mnt/app/shared/log/nginx*.log\" will be used  : ";
					$in=<STDIN>;
					chomp($in);
					if(length $in <= 0){
						$PATH='/mnt/app/shared/log/nginx*.log';
					}else{
						$PATH=$in;
					}
					$count=1;
				}
					$nginx='{ "source":{ "name":"Nginx Access Log", "category":"Application/Nginx", "hostName":"' . $collectors{$_} . '", "pathExpression":"' . $PATH . '", "sourceType":"LocalFile", }}';
					$client->POST("/api/v1/collectors/$_/sources", "$nginx",  {"Content-type" => 'application/json'} );
                			print "$collectors{$_} source $add added \n";
			}elsif($add=~/^rails$/){
				if($count == 0){
					print "Enter path or \"/mnt/app/shared/log/production.log\" will be used  : ";
                        		$in=<STDIN>;
                        		chomp($in);
                        			if(length $in <= 0){
                                			$PATH='/mnt/app/shared/log/production.log';
                        			}else{
                                			$PATH=$in;
                        			}
				        $count=1;
                                }

					$rails='{ "source":{ "name":"Rails Application Log", "category":"Application/Rails", "hostName":"' . $collectors{$_} . '", "pathExpression":"' . $PATH . '", "sourceType":"LocalFile", }}';
		    			$client->POST("/api/v1/collectors/$_/sources", "$rails",  {"Content-type" => 'application/json'} );
                			print "$collectors{$_} source $add added \n";
			}else{
					print "error add entry not recognised\n";
				}	
 		}

	}

}


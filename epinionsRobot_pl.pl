#EpinionsRobot.pl: crawl Epinions.com web site and download users, their ratings on items and their trust statements. It saves users as perl objects and this might not be a good idea. I modified the code for saving html pages (see EpinionsRobot_html.pl) but I never tested this version.
#
#Copyright (C) 2006  paolo massa
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# I quickly learn Perl just for creating this program. I know the code is orrible and can contains bugs. Feel free to send me an email saying how bad this code is. ;-)
# You can contact me at < massa AT itc DOT it >
# 
#
### BUG BUG XXX
### if an user has expressed no trust 
# i wrongly parse her trust page and not extract her name...
# see http://www.epinions.com/user-onesuperma/show_~trust/pp_~1/pa_~1
### what if an user has expresse no rating? it's ok see 
# http://www.epinions.com/user-squippel1/show_~trust

### BUG ON epinions site!
# if there is a ? in the user name, the page does not exist! example: gotflute?
# we check if user_name contains ?

### note: if one user gave 2 opinions to the same item, I keep the oldest. 

### do the same stuff for reviews as i did for trust!
### mor thatn 200!!!

#### create read_lists (read the 3 files and return 3 arrays)
#### remove user- from user-pippo
#
# i shoudl write usernames found in a file or in a hash (the list should be dumped every fetch so that i can restart downloading if something break)
# 
# this should became a method "save_user(username)"
# I should call it recursively and keep a list of users I already downloaded.
# 
#
# given a <login>
# look page www.epinions.com/user-<login>/show_~trust.html
#   for people trusted by <login> (and also for "leader", "editor", ...)
# look page www.epinions.com/user-<login>/show_~content.html
#   for rating of people on stuff
#
# i must look this page (reviews made by petra)
# and follow every single review in order to get the rating given by author
# http://www.epinions.com/user-petra/show_~content/contype_~opinion/pp_~1/pa_~1#list
#

use strict;
# Create a user agent object
use LWP::UserAgent;
use Data::Dumper;
use File::Spec::Functions;
use Storable;

#-------------

my $VERSION = "0.1";

my $ua = LWP::UserAgent->new;
#my $ua->agent("EpinionsRobot/$VERSION");

my @already_visited_users;
my @to_be_visited_users=("drdevience"); #=seed;
my $current_user;
my $i=1;
my $dir_for_lists = "./lists/";
my $dir_for_data = "./data/";
my $prefix="u_";
my $temp_prefix="tt_";

save_seeds_list();

#temp_debug($i++);

#fetch_user("caronis");
#temp_debug(0);

#fetch_user("onesuperma");
#temp_debug(0);
#fetch_user("drdevience");
#temp_debug($i++);
#fetch_user("daily-llama");
#temp_debug($i++);
#fetch_user("petra");
#temp_debug($i++);
#fetch_user("mshooterville");
#temp_debug($i++);
#save_lists(\@already_visited_users,\@to_be_visited_users);


restore_lists_from_files();
temp_debug(0);

while ($#to_be_visited_users >= 0) {
    #extract $current_user from $to_be_visited_users
    $current_user=shift(@to_be_visited_users);

    
    my $nr_visited_users=@already_visited_users; #number of users already done! +1? #up to now i use it only for debugging

    #once every 200 users we make a backup copy
    if ($nr_visited_users % 200 == 0) {
	print "\n### Now I make a backup because this user is the ".$nr_visited_users;
#	system('perl backup_epinions_downloaded_data.pl');
	print "\n### BACKUP ENDED ###\n\n\n";
    }

    if (index($current_user,'?') < 0) {
    #### debug message
#    temp_debug($i++);
	
	#fetch current user
	print "start fetch user..................";
	fetch_user($current_user);
	
	#add $current_user to already visited users.
	push(@already_visited_users, $current_user);
	$current_user="";
	#### save info on file
	save_lists(\@already_visited_users,\@to_be_visited_users);
    } else {
	print "\nWARNING\n\nCurrent User |".$current_user."| contains a ? . This means the corresponding web page is not present and we are going to skip it and create a file for him with 0 reviews and 0 friends\n\n";
#save information
	my %user_info;
	$user_info{"name"}=$current_user;
	$user_info{"url"}=$current_user;
	my %web_of_trust;
	my %reviews;
	
	$user_info{"web_of_trust"}=\%web_of_trust;
	$user_info{"reviews"}=\%reviews;
	
	my $user_file = catfile($dir_for_data, $current_user.'.data');	
	my $ref_hash = \%user_info;
	
	require Storable;
	
	Storable::store($ref_hash, $user_file);
    }
    print "aaa".$#to_be_visited_users;


}

exit;

sub restore_lists_from_files {
    my $start_from_beginning=0;

    my $already_visited_file = catfile($dir_for_lists, 'already_visited.txt');
    my $already_visited_data = scalar eval { Storable::retrieve($already_visited_file) } || {};
    if ($@) 
    {
	$start_from_beginning=1;
    } else {
	@already_visited_users = @$already_visited_data;   
	$i=@already_visited_users; #number of users already done! +1? #up to now i use it only for debugging
	$i+=1;
    }

    my $to_be_visited_file = catfile($dir_for_lists, 'to_be_visited.txt');
    my $to_be_visited_data = scalar eval { Storable::retrieve($to_be_visited_file) } || {};
    if ($@) 
    {
	$start_from_beginning=1;
    } else {
	@to_be_visited_users = @$to_be_visited_data;   
    }

    #if one of the file was not there, it means we need to start from the beginning but we are kind enough to let the user know we haven't found an "already_visited.txt" file ;-)
    if ($start_from_beginning ==1) 
    {
	print "\n\n#### WARNING! ####\nWe haven't found previous saved files! This means we should restart to download from zero. It is the correct?\nPress ENTER if yes, otherwise end the program and check the files!\n";
	my $input_keyboard = <STDIN>; # just wait press enter.
    } else {
	print "\n\nWe have found previous saved files. The computation is going to start from where it was interrupted\n";
	print "This means from user=|".@to_be_visited_users[0]."|\nIf ok, press ENTER\n";

	my $input_keyboard = <STDIN>; # just wait press enter.
    }
}

#this will save the @to_be_visited_users into "seeds_list.txt"
sub save_seeds_list {
    my $seeds_list_ref=\@to_be_visited_users;
    my $seeds_list_file = catfile($dir_for_lists, 'seeds_list.txt');    
    require Storable;
    Storable::store($seeds_list_ref, $seeds_list_file);
}

sub save_lists {
    my $val1 = shift;
    die("expected array, you supplied ", ref $val1)
	unless ref $val1 eq 'ARRAY';
    my $val3 = shift;
    die("expected array, you supplied ", ref $val3)
	unless ref $val3 eq 'ARRAY';

    my $already_visited_array_ref=$val1;
    my $to_be_visited_array_ref=$val3;

    my $already_visited_file = catfile($dir_for_lists, 'already_visited.txt');    
    my $ref_hash1 = $already_visited_array_ref;
    
    my $to_be_visited_file = catfile($dir_for_lists, 'to_be_visited.txt');    
    my $ref_hash3 = $to_be_visited_array_ref;
    
    require Storable;
    
    Storable::store($ref_hash1, $already_visited_file);
    Storable::store($ref_hash3, $to_be_visited_file);
		
#    my $already_visited_data = scalar eval { Storable::retrieve($already_visited_file) } || {};
#    my @a_v_array = @$already_visited_data;   
#    print "datilettidafile".Dumper(@a_v_array);

#    print "saved\n";
}

sub temp_debug {
    my $num=shift(@_);
    print $num." | ";

    foreach (@already_visited_users) {
                   print "$_ ";
               }
    print " < ";
    print $current_user;
    print " > ";
    foreach (@to_be_visited_users) {
                   print "$_ ";
               }
    print "\n";


    print "\nAlready visited=".@already_visited_users;
    print "\nTo be visited=".@to_be_visited_users;

    print "\n###Next user to be visited=".@to_be_visited_users[0]."\n";

#    print $num.") to be visited users=".Dumper(\@to_be_visited_users)."";
#    print $num.") already visited users=".Dumper(\@already_visited_users)."";
#    print $num.") current_user=".$current_user."\n";

    print "----------------------------\n";
    print "if ok, presse ENTER\n";
    my $input_keyboard = <STDIN>; # just wait press enter.
}

sub insert_user_in_to_be_visited_users {
#this sub is call in fetch_user for every friend of current user in order to add it in $to_be_visited_users_hash
#this usb controls that the user is not already in $to_be_visited_users_hash or $already_visited_users_hash
    my $user_to_be_inserted=shift(@_);
#    unless (exists $already_visited_users[$user_to_be_inserted] && exists $to_be_visited_users[$user_to_be_inserted]) {
    my $exists_in_already_visited_users=0;
    foreach (@already_visited_users) {
                   if($_ eq $user_to_be_inserted) {
		       $exists_in_already_visited_users=1;
		   };
               }
    my $exists_in_to_be_visited_users=0;
    foreach (@to_be_visited_users) {
                   if($_ eq $user_to_be_inserted) {
		       $exists_in_to_be_visited_users=1;
		   };
               }
#    print "in->".$user_to_be_inserted."    ";
#    print "in already=".$exists_in_already_visited_users."   ";
#    print "in to be=".$exists_in_to_be_visited_users."   \n";

    unless($exists_in_already_visited_users or $exists_in_to_be_visited_users or $user_to_be_inserted eq $current_user) {
	push(@to_be_visited_users, $user_to_be_inserted);
    }
}

sub fetch_user {
	my $user_name_string = shift(@_);

#	print "user name=".$user_name_string;

	my $continue_fetching_trust_pages=1;
	my $continue_fetching_reviews_pages=1;
	my $trust_page_index=1;
	my $reviews_page_index=1;

	my %user_info;
	my $user_url;
	my %web_of_trust;
	my %reviews;


	my $user_page_url = 'http://www.epinions.com/user-'.$user_name_string;
	my $req = HTTP::Request->new(POST => $user_page_url);	
	my $res = $ua->request($req);
	my $cont=$res->{_content};

	open(OUTFILE, ">data/".$temp_prefix.$user_name_string);
	print OUTFILE ($cont);

	close OUTFILE;


USER_CYCLE:	while ($continue_fetching_trust_pages == 1) {
# Create a request
	    my $user_trust_page_url = 'http://www.epinions.com/user-'.$user_name_string.'/show_~trust/pp_~'.$trust_page_index++.'/pa_~1';
#	    print "fetch trust   of ".$user_name_string." from ".$user_trust_page_url."\n";
	    
	    my $req = HTTP::Request->new(POST => $user_trust_page_url);

# Pass request to the user agent and get a response back
	    my $res = $ua->request($req);
	    
########## XXXX i need to check if in this page there are trusts or not! if not i set continue to 0    
	    my $cont=$res->{_content};

	    if (index($cont,"There are no members in your trust list") != -1) {
		$continue_fetching_trust_pages=0;
		last USER_CYCLE; #go out of while
#		print "no friends in this page, set continue to 1\n";
	    } else {
#in this case i need to consider this friend normally (add her in hash, ...) 
		open(OUTFILE, ">data/".$temp_prefix.$user_name_string."_trust_".$trust_page_index);
		print OUTFILE ($cont);
		close OUTFILE;
	    }

#i add the friends in the to_be_visted_list!
	    use HTML::TokeParser;
	    my $p = HTML::TokeParser->new(\$cont);
	    
	    $p->get_tag("html");
	    
	    if ($p->get_tag("title")) {
		my $title = $p->get_trimmed_text;
#               print "Title: $title\n";
		if (index($title,"This Page Cannot Be Found",0) >= 0)
		{
		    # This Page ... string found, this means it is a missing page.
		    print "\n\nWARNING. This user is strange, it has no page!\n\n";
		    
		    last USER_CYCLE; #go out of while
		}
	    }
	    
	    $p->get_tag("body");
	    
#we need to skip 12 table tags
	    for(my $i=0;$i<4;$i++){
#    print $i.Dumper($p->get_tag("table"));
		$p->get_tag("table");
	    }
	    
	    $p->get_tag("/table");
	    $p->get_tag("/span");
	    $p->get_tag("/span");
	    $p->get_tag("/span");
	    my $token = $p->get_tag("a");
	    $user_url = $token->[1]{href} || "-";
	    my $user_name = $p->get_text("/a");
	    $user_url =~ s|^/user-||;
	    
#print $p->get_trimmed_text("table");
	    
	    for(my $i=0;$i<8;$i++){
#    print $i.Dumper($p->get_tag("table"));
		$p->get_tag("table");
	    }
	    
#           print "User:".$user_name."\nUrl=".$user_url."\n\n";
	    
	    $user_info{"name"}=$user_name;
	    $user_info{"url"}=$user_url;
	    
	    #if user is $user-url this means the first link is a link to the same page because there are no fri ends (this means we should stop looking for pages of 200 friends with suffix pp_~X/pa_~1 (where X is the progre ssive number)
	    
#in this case i need to consider this friend normally (add her in hash, ...)
	    
	    if (my $token = $p->get_tag("table")) {
#           print Dumper($token);
#print "eee".$p->get_trimmed_text("/html")."\n\n----------------------------\n\n";
#print "eee".$p->get_text()."\n\n----------------------------\n\n";
#print "wertyeee".$p->get_trimmed_text("/table")."\n\n----------------------------\n\n";
		
		if($token->[1]{width} eq '100%' && $token->[1]{cellpadding} eq '4') {
		    $p->get_tag("tr");
		    $p->get_tag("tr");
		    $p->get_tag("tr");
		}
		
	      LINE: while () {
		  my $token = $p->get_tag("tr");
		  $p->get_tag("td");
		  $p->get_tag("span");
		  my $token = $p->get_tag("a");
		  my $friend_url = $token->[1]{href} || "-";
		  my $friend_name = $p->get_text("/a");
		  $friend_url =~ s|^/user-||;
		  $p->get_tag("/span");
		  $p->get_tag("/td");
		  $p->get_tag("td");
		  $p->get_tag("span");
		  my $description = $p->get_trimmed_text("span");
#           my $description = $p->get_text("br");
#           $p->get_tag("br");
		  $p->get_tag("span");
		  $p->get_tag("/span");
		  my $location = $p->get_trimmed_text("/span");
		  $p->get_tag("/span");
		  $p->get_tag("td");
		  $p->get_tag("span");
		  my $friend_since = $p->get_trimmed_text("/span");
		  $p->get_tag("/span");
		  last LINE unless ($p->get_tag("/td"));
		  
		  $p->get_tag("/tr");
		  my %friend_info_hash;
#           $friend_info_hash{"name"} = $friend_name;
#           $friend_info_hash{"url"} = $friend_url;
		  $friend_info_hash{"since"} = $friend_since;
#           print Dumper(%friend_info_hash)."\n";
		  
		  $web_of_trust{$friend_url} = \%friend_info_hash;
		  
#                     print "\nAdding ".$friend_url." friend of ".$user_name." to to_be_analzyed";
		  
		  insert_user_in_to_be_visited_users($friend_url);
		  #   print "number of friends".Dumper(\%user_info);
#           print Dumper(\%web_of_trust)."\n";
#           print "\n\nname=$name";
#           print "\nurl=$url";
#           print "\nsince=$since";
#           print "\nlocation=$location";
#           print "\ndescr=$description";
	      }
	    }
	}
	
#print "sono qui!";
	while ($continue_fetching_reviews_pages == 1) {
		
#now i fetch information from the page that contains the reviews made by user_name

	    my $user_reviews_page_url = 'http://www.epinions.com/user-'.$user_name_string.'/show_~content/contype_~opinion/pp_~'.$reviews_page_index++.'/pa_~1/sort_~date/sort_dir_~asc';
	    my $req = HTTP::Request->new(POST => $user_reviews_page_url);
	    
#	    print "fetch reviews of ".$user_name_string." from ".$user_reviews_page_url."\n";	
# Pass request to the user agent and get a response back
	    my $res = $ua->request($req);
	    
	    my $cont=$res->{_content};
	    
#	    if (index($cont,'sort_~date/sort_dir_~des">Date&nbsp;Written'== -1)) {	    
	    if (index($cont,'Date&nbsp;Written') < 0) {
		$continue_fetching_reviews_pages=0;
#		print "no reviews in this page, set continue to 1\n";
	    } else {
		open(OUTFILE, ">data/".$temp_prefix.$user_name_string."_ratings_".$reviews_page_index);
		print OUTFILE ($cont);
		close OUTFILE;
	    }
	}
	
#save information
    #try to read info from structure
	
#	$user_info{"web_of_trust"}=\%web_of_trust;
#	$user_info{"reviews"}=\%reviews;
	
#	my $number_reviews=keys %reviews;
#	my $number_friends=keys %web_of_trust;
#	print "\n###\n";
	print "### ".$i++." Summary for user ".$user_url;
	print "###\n";

### now we try to zip
# name of the zip binary
	my $tar = "tar";
# switches for zip
	my $tar_switches = " jcfvm";
# what we will call the file locally and on the server
	my $tar_file_output = $prefix.$user_name_string.".tbz";
	my $tar_files_input = $temp_prefix.$user_name_string."*";
#	my $tar_dir = $dir_for_data;

### Create the ZIP ile
	print "compressing...";
	system("echo cd $dir_for_data");
	chdir $dir_for_data;
#	system("ls");
	system("echo $tar $tar_switches $tar_file_output $tar_files_input");
	system("$tar $tar_switches $tar_file_output $tar_files_input >/dev/null");
	system("echo rm \"$tar_files_input\"");
	system("rm $tar_files_input");
	chdir "..";
	print "[done]\n"
	
#	print "\n\nEXIT";

}





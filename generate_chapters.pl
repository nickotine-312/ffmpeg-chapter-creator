#!/usr/bin/env perl
$| = 1;
use 5.010;
use Capture::Tiny qw/capture/;

$dirpath='/home/nick/media/shows/';
opendir DIR,$dirpath;
my @fname_list = readdir(DIR);
close DIR;

foreach $fname (@fname_list)
{
	next if $fname eq '.' || $fname eq '..';
	say "###########################################################################################\n";
	say "##### STARTING: $fname #####\n";
	say "###########################################################################################\n";

	my ($out, $err) = capture {
		system("ffmpeg -i \"$dirpath/$fname\" -vf blackdetect=d=0.1:pix_th=.1 -f rawvideo -y /dev/null");
	};

	$length = `ffprobe -i "$dirpath/$fname" -show_format -v quiet | grep duration | cut -d= -f2`;
	say "DURATION: $length";

	#Convert carriage returns to newlines
	#(dos2unix didnt work for me so we're doing it the way I know instead.)
	$err =~ s/\r/\n/g;
	@lines = split(/\n/, $err);
	say "#\n";

	foreach (@lines) {
		#Parse the timestamp (in seconds) that blackness starts, and how long it lasts
		$_ =~ /.*black_start:([0-9\.]+) .*black_duration:([0-9\.]+)/ || next;
		my ($start, $duration) = ($1, $2);

		#Skip darkness if in first 5 minutes (theme song), less than 1 second (scene change), or within 4 minutes of end (credits)
		next if $start < 360;
	        next if	$duration < 1.0; 
		next if $length - $start < 300;
		
		print("Start: $start | Duration $duration\n");
	}
}

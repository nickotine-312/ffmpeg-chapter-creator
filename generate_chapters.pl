#!/usr/bin/env perl
use 5.010;
use Capture::Tiny;

system("rm ./temp");

$dirpath='/home/nick/media/';
@fname_list=(
);

foreach $fname (@fname_list)
{
	say "###########################################################################################\n";
	say "##### STARTING: $fname #####\n";
	say "###########################################################################################\n";

	my ($out, $err) = capture {
		system("ffmpeg -i \"$dirpath/$fname\" -af silencedetect=n=-50dB:d=0.1 -f null -");
	};

	@lines = split(/\n/, $err);
	say "#\n";

	foreach $line (@lines) {
		say "Line is :$line:";
		say "Next...";
	}
}

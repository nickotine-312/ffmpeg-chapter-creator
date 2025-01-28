# ffmpeg-chapter-creator
Used to automatically insert chapter metadata into video files using ffmpeg, for use inserting commercial breaks in ErsatzTV (or whatever else you want to do with it!)

Originally this script identified the breaks by detecting silence, but there was too much ambiguity, so now it scans the file for black frames in the video. This is a more resource intensive operation, but it yields much more consistent results. 

# Requirements
Perl v5.010
Capture::Tiny CPAN module installed

Linux packages: gcc, build-essential, ffmpeg (only tested on ffmpeg 6.1.1)

# Usage

At the top of the script are several variables that must be manually set:
* `$dirpath`: Directory path containing episodes to be re-encoded
* `$removestr`: A string to be removed from each filename (if no such string exists, set this variable to `""`)
* `$oldext`: The old file extension to be removed. All videos are re-encoded as mp4, and this prevents output files ending with things like `.avi.mp4`
* * (If your source files are mp4, you should include that extension here, since the script manually adds .mp4 to the output filename later.)
* Just before generating the metadata file, a block of regex commands are used to transform source filenames as desired. You will want to edit this section accordingly. The script can misbehave with quotes in filenames (and I got lazy about fixing it) so I strip those - if you remove those lines, other things may break.

# TODO

* format strings for header to make output prettier.
* Update directory traversal to move through subdirectories too. 
* Stretch goal would be to somehow query IMDb for episode summaries etc of the episodes we're scanning....

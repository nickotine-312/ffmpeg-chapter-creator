# ffmpeg-chapter-creator
Used to automatically insert chapter metadata into video files using ffmpeg, for use inserting commercial breaks in ErsatzTV (or whatever else you want to do with it!)

Originally this script identified the breaks by detecting silence, but there was too much ambiguity, so now it scans the file for black frames in the video. This is a more resource intensive operation, but it yields much more consistent results. 

# TODO
* Provide the string to remove from the filename (any text from the filename that you do not wish to include in the final file.)
* Normalize start time for commercial breaks by taking `($end-$start)/2`
* Figure out how to dynamically convert the timestamps in the above output file to a format ffmpeg metadata understands
* Build episode-specific metadata file with chapters and title
* Encode input file with that metadata file, using a name for the output file with any desired text (from above) removed. 


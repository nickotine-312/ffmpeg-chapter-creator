# ffmpeg-chapter-creator
Used to automatically insert chapter metadata into video files using ffmpeg, for use inserting commercial breaks in ErsatzTV (or whatever else you want to do with it!)

Originally this script identified the breaks by detecting silence, but there was too much ambiguity, so now it scans the file for black frames in the video. This is a more resource intensive operation, but it yields much more consistent results. 

# TODO
* Update directory traversal to move through subdirectories too. 

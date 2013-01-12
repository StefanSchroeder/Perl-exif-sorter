Perl-exif-sorter
================

Recursively search a directory hierarchy and copy|move images into folders named YYYY/MM based on EXIF-data.

= Usage =

perl exif-sorter.pl /path/to/images

will create folders in the current directory, e.g. 2012/01, 2012/02
and so forth, an copy or move images or movies into these folders.

Supported file formats are

jp(e)g, mov and 3gp

I will add command line options to choose copy or move. For images
without EXIF information the folder unknown/unknown is created.


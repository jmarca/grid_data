# Ideas on reworking cached files to couchdb

I need to move 2012 docs again to couchdb

Couple of things.

## on using glob

First, I considered using glob (perhaps once again) to find files to
process prior to processing them.  I think originally I figured that
glob has to run through each file in the file system and that is slow,
whereas I could construct the expected file from i cell, j cell arrays
much faster.  While that is true, looking at it again now, I don't
think it is faster to access...that is, I have to look for files that
might not exist, whereas glob just looks at all of the files and finds
them.

So that is why I am switching to using glob and a pattern match.

## on deleting stuff from couchdb

So I have one iteration of data in couchdb, and am looking at
reprocessing a second batch of data and stuffing couchdb once again.
However, I don't really want to delete the existing db, so that means
if a certain cell had data in the old pass and doesn't in the new,
then I can't tell by looking.  That is, if I just look at couchdb, I
will see old and new and not know which is which.

To fix this, I am going to use the fact that regardless of whether
there is any data or not, every cell that has a matching cell in the
postgresql database table of carb grid cells has a corresponding file
in the fs.  If it is empty, my current code skips it and returns the
error message "no data".

My current thinking is to expand this.  Rather than skipping the file,
instead look it up in the db and see if it is there.  Rather, do an
`_all_docs` query to see if any doc exists from day one of the year to
day last of the year for that given grid cell.  If any docs do exist,
then pass them along to `node_couch_view_deleter.make_bulk_deleter`
which will take the list and assign the delete flag, etc, to mark the
files as deleted.

If nothing is in the couchdb database, all that costs is a single
fairly quick primary key query.  If there are docs for that now
missing grid cell, then the cost is a query plus 365*24 bulkdoc push
to save delete flags, but the benefit is that I can be sure that the
database has only the grid cell records it is supposed to have in it.

**WARNING**

This code should not be considered stable or reliable in even the furthest
stretch of the imagination!  Feel free to read it, fork it, play with it,
and attempt to improve it; but do *not* expect it to work well, stably, or even
at all.  It comes as is with no warrenty or expectations of functionality or
safety any kind.

If you use it in something important, you get to keep the pieces when it breaks!!

General description
-------------------

This is a document mapper for integrating Cassandra with Ruby on Rails.  It
attempts (and no doubt fails) to be somewhat ActiveModel-compliant, has
a limitted system for automatically maintaining orderings on requested document
fields, and has a versioning system.

This code was thrown together in a matter of days to facilitate a last-minute
database transition of a Rails app to Cassandra.  It's mostly working for our
purposes, but no-doubt still has numerous bugs.

Feel free to take portions of this code for your own use or use it as a basis
for creating a better Cassandra document mapper.  It is however not recommended
that you attempt to use this code in your own Rails app unless you are prepared
to make a lot of modifications and bug fixes.

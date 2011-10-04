GEM NEW HISTORY
===============



2011-10-04 Released Version 0.2.0
------------------------------

* New:      Added basic rake tasks to build the gem.
* Changed:  .literal Suffix no longer exists, use .stop instead.
* Changed:  Files are now processed by suffix, until .stop or an unknown suffix is hit.
  E.g. foo.html.markdown.erb will first be processed by the ERB processor, then by the
  Markdown  processor and then it'll stop (because .html is not being processed any
  further)
* Fixed:    Fixed broken template file default/skeleton/lib/REQUIRE_NAME.rb.
* Improved: Added executables detection and setting of spec.executables to
  GEM\_NAME.gemspec.erb
* Improved: Removed spec.date from GEM\_NAME.gemspec.erb



2011-06-15 - Released Version 0.1.2
-----------------------------------

* Fixed:    Fixed a bug in the text of "gem help new"



2011-06-13 - Released Version 0.1.1
-----------------------------------

* Fixed:    Fixed a small bug in the initial release



2011-06-13 - Released Version 0.1.0
-----------------------------------

* Initial Release
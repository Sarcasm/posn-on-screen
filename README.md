Find cursor position on the screen
==================================

This package aimed to provide one or more functions to get
informations about the position on the screen of a visible point. With
this information someone can create a frame near the point and provide
a completion UI for example.

Why make a package for such a small thing ?
-------------------------------------------

Because I saw more than one Emacs package doing that thing and I
needed it too. 

I prefer to do that in a separate file because:

* it can be used by one or more package
* it can be enhanced to handle different window systems more
  accurately

Note
----

At the moment of this writing the code is shamelessly stolen from the
[esense](http://esense.sourceforge.net) package.

Here is a list of packages that implements similar routines inside
their code.

* [esense](http://esense.sourceforge.net)
* [Pos Tip](http://www.emacswiki.org/PosTip)
* [tooltip-help.el](http://www.emacswiki.org/emacs/tooltip-help.el)
* [csense.el](http://code.google.com/p/csense/source/browse/trunk/csense.el)
* `dframe-reposition-frame-emacs` in dframe.el (shipped with Emacs)

Editing hairstyles
==================

Hairstyles don't generally need to be customized for each of the 178 different animation frames in the spritesheet. Really you only need to define one frame for each direction, plus a few customized versions for the "hurt" animation.

Then you can run an automated script that builds the full sheets from those individual frames, for both the male and female body types, in all the color schemes.

Prerequisites
=============

To generate the full hair spritesheets, you'll need to:

* Download and install [Ruby](https://www.ruby-lang.org/en/).
* Go to a command prompt and type `gem install rake` to install [Rake](http://rake.rubyforge.org/).
* Download and install [ImageMagick](http://www.imagemagick.org/). During installation, make sure to select the option to add ImageMagick to your PATH.

Editing hair source images
==========================

The hair source images are in the `_build/hair` folder. There's a subfolder for each hairstyle. To add a new hairstyle, just add a new subfolder and add images to it.

Each source image needs to be 128x128 pixels. The pixel at (64, 64) in the source image corresponds to the leftmost pixel in the first row of pixels in the character's head.

Filenames should be of the form `[prefix-]d[-suffix].png`, where:

* `d` is the direction the character is facing: `n`, `s`, `e`, or `w`.
* `prefix-` is an optional layer name. If specified, this is either `bg-` or `behindbody-`.
* `-suffix` is optional, and specifies one or more individual animation frames. If specified, this image is only used for those specific frames. Typically this will only be one of `-hurt2`, `-hurt3`, `-hurt4` or `-hurt5`.

You must have at least one each of `n.png`, `s.png`, `e.png` and `w.png`.

`s-hurt2`, `s-hurt3`, `s-hurt4` and `s-hurt5` are strongly recommended. You can combine these, e.g. `s-hurt2-hurt3.png` would be used for both frame 2 and 3 of the "hurt" animation.

Generating the spritesheets
===========================

Open a command prompt anywhere in your git checkout, and type `rake`.

The first time you run it, it's possible that this may rebuild all the spritesheets, which takes 5-10 minutes. Thereafter it should be faster, as it only rebuilds the spritesheets whose ingredients have changed.

Problems with ImageMagick
-------------------------

You must have ImageMagick installed to run the process. If you receive errors running rake, try installing ImageMagick: http://www.imagemagick.org/

Some versions of Windows have problems working with ImageMagick's "convert" command. Check out this page if you need help: http://savage.net.au/ImageMagick/html/install-convert.html

Advanced topics
===============

Layers
------

In the east- and west-facing "bow" animations, the character's arm reaches out in front of their hair. The script automatically applies a cutout to these animation frames to remove the hair pixels that should be behind that front arm.

By default, hair images are in the "foreground" layer, which is in front of everything but the bow arm. The bow arm is used as a cutout for these frames.

You can add some images with a `behindbody-` prefix, which will be behind the character's torso, but still in front of the far arm (in east- and west-facing poses). This is useful for things like a braid slung over the character's far shoulder, which should be obscured by the character's torso, but should itself obscure the far arm. (See e.g. the "princess", "shoulderl" and "shoulderr" hairstyles.)

You can also add images with a `bg-` prefix, which will be behind the character's entire body. This is useful for things like long hair behind the character's body, different amounts of which will be exposed depending on the body movements in different animations. (See e.g. the "ponytail2" hairstyle.)

Bugs / Feedback
===============

The hair script was written by @joewhite. If you have problems or questions, you can open an issue on his fork: https://github.com/joewhite/Universal-LPC-spritesheet/tree/universal-hair
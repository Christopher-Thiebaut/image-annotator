# Welcome to Image Annotator

The purpose of *Image Annotator* is to make it easy to annotate the locations of different objects in a series of images and then output those annotations in a format that can easily be used to train an Object Detection model that can be used in Apple's `CoreML` framework in an iOS or MacOS application.

## About Image Annotator:

*Image Annotator* is a MacOS app written in Swift.  A simple Python script is also included for converting the output file from *Image Annotator* to a model compatible with `CoreML`.

### Usage:

The core *Image Annotator* application has no external dependencies and is compatible with MacOS sandboxing.  That being said, the application does not directly create models for `CoreML` and relies on [*Turi Create*](https://github.com/apple/turicreate) to do the heavy lifting. In order to use the included `object_detection.py` script, you will need to install *Turi Create* by following the instructions found on that project's GitHub page.

You can easily annotate some images in a directory and then come back later to pick up where you left off. If you use *Image Annotator* to open a directory in which you have previously annotated images, the application will automatically pick up where you left off including restoring all of the annotations you previously made to images and navigating back to the image you were most recently viewing. (If this is undesired behavior and you want to start from scratch, you can use `Edit > Reset Directory`.

To output your annotations in a format that can be read by `object_detection.py` and used to train a model, use `File > Save As`.

The `object_detection.py` script should be run from the same directory where the images are located.  to run `object_detection.py`, enter `python object_detection.py path_to_image_annotator_output`.

### Contributions:

There's lots of room for this project to grow.  The long-term goal of this project is to be able to abstract away a lot of the complexities of creating a machine learning model for developers who just want to add a bit of computer vision smarts to their applications. Contributions that further that goal are welcomed and encouraged.

In addition, support for more than one output format that can be used by machine learning software suites other than *Turi Create* is also a long-term goal of this project.  If there's another format you use and would like to see supported, I encourage you to make a pull request.
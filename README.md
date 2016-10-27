### Virtual Tourist

**Virtual Tourist** allows users to specify travel locations around the world, and create virtual photo albums for each location. The locations and photo albums are stored in Core Data.

Users chose location on the map by dropping pins and when the pin is tapped a photo album is created with images from Flickr for that location. Users can delete photos from that album, or reload a new set of photos from Flickr.

It showcases how to use **CoreData** to persist data. It also uses **web APIs** and diplay photos in a collection view. Using **CoreData** is a core skill. This can help others learn this.


#### Documentation

The code is well documented. More information can be found on the [project's page](http://hexaedre.com/projects/virtual-tourist/).

#### Install

1. Fork the repo (press the `Fork` button near the top right) to your account.
2. Clone the repo on your computer. You find the link in your own github repo then type `git clone <github link>`
3. Get API key from Flickr. Just visit [the Flickr API documentation](https://www.flickr.com/services/apps/create/noncommercial/?).
3. Open the Xcode project file and in the API.swift file, replace API_Key and API_SECRET by strings containing your credentials.
4. Run the project.

#### Swift and Xcode versions

This project is for **Swift version 2.2** and **Xcode version 7.3**.

#### More information

More information and screenshots can be found on the [project's page](http://hexaedre.com/projects/virtual-tourist/). If you have questions I'd be happy to help. Contact information can be found below or on the project's page.

#### How to contribute

I'm always happy to improve code and learn, so if you find thigs to improve please submit a pull request.

##### Here are some ways you can contribute:

* by reporting bugs
* by writing or editing documentation
* by writing code ( no patch is too small : fix typos, add comments, clean up * inconsistent whitespace )
* by refactoring code
* by closing issues
* by reviewing patches
* Submitting an Issue

I use the GitHub issue tracker to track bugs and features. Before submitting a bug report or feature request, check to make sure it hasn't already been submitted. When submitting a bug report, please include a Gist that includes a stack trace and any details that may be necessary to reproduce the bug, including your Swift and Xcode version, and operating system. Ideally, a bug report should include a pull request with failing specs.

##### Submitting a Pull Request

1. Fork the repository.
1. Create a topic branch.
1. Implement your feature or bug fix.
1. Add, commit, and push your changes.
1. Submit a pull request.

This is based on [https://github.com/middleman/middleman-heroku/blob/master/CONTRIBUTING.md](https://github.com/middleman/middleman-heroku/blob/master/CONTRIBUTING.md)

#### License

On the Map is Copyright © 2016 Denis Ricard. It is free software, and may be redistributed under the terms specified in the LICENSE file.

#### About

I'm an iOS developer. You can find my web site at [hexaedre.com](http://hexaedre.com), find me on Twitter under [@hexaedre](http://twitter.com/hexaedre), or [contact me](http://hexaedre.com/contact/).

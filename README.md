# Baker
This project is a fork of [SwiftCGI](https://github.com/ianthetechie/SwiftCGI), an object-functional microframework for developing FCGI applications in Swift. While the source has as yet retained the original name, the name will someday change to Baker...if I ever get a 1.0 release :)

I took a lot of inspiration from the original project and tried to experiment with different techniques, adding a MVC pattern and a first-class router. Next step is to add a rich view/templating enging.

# How to get this works
Clone the repo, run the fcgi server via the Vagrant file included (in `fcgi-server`), and then run the `SwiftCGI Demo` scheme. Point your browser to the fcgi server, which will communicate with the SwiftCGI app running on your host.

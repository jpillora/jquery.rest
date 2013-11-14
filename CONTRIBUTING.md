## How to test jQuery.rest locally

* Install Node http://nodejs.org

* `npm install -g grunt-source`

* `git clone https://github.com/jpillora/jquery.rest`

* `cd jquery.rest`

* `grunt-source`

This will create an HTTP server on http://localhost:3000 inside the `jquery.rest` folder and will start watching `src` for changes and will then compile and minify into `dist`

### Issues and Pull-requests welcome.
This is a new project of mine to prototype a dozen or so educational programs for learning languages -- and in particular Attic Greek.

The project is organized thusly:
  * a bunch of top-level projects, util/, site/, module1/, ..., moduleN/, each being a standalone node package
  * the packages depend upon one another, and development requires using `npm link`
  * util/ is miscellaneous but includes an object model for the Greek Grammar
  * site/ is a simple web app, with an api for making grammatical queries (e.g., "gimme all participles for the verb λέγω")
  * module1/ is a simple participle game. it's meant to show a participle form and the user indicates its inflection
  * everything is a work-in-progress, beware

Notes
  * Directory structure is more influenced by Maven layouts than by the rails MVC approach. Subject to change.
  * I have, probably unwisely, built my own client-side dependency management system. After looking through the alternatives (the most popular being Stitch), nothing existing supports the full capabilities of npm on the client, as well as coffeescript. My bundler.coffee system subclasses node's Module to allow anything requireable by Node to be requireable on the client. This supports coffeescript and anything added to the extensions supported by node's module system. Note that this currently exposes the structure of your filesystem, so beware of using it until that is fixed.

 To get setup
   * create a database named `pseudw` with the scheme described in site/.../schema.sql
   * import all the morphological data using the import script:
     DB_USER=jibba DB_PASS=jabba site/src/scripts/coffee/import.coffee /path/to/greek.morph.xml
   * note that you have to download greek.morph.xml from Perseus http://www.perseus.tufts.edu/hopper/opensource/download
   * start the server:
     cd site
     DB_USER=jibba DB_PASS=jabba npm start

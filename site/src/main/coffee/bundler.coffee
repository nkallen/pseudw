Module = require('module')

###

This allows anything requireable by node.js to be requireable in the browser.
This includes npm packages as well as local files and all transitive dependencies.
It supports anything supported by the server (as registered in module extensions),
including coffeescript.

Example:

  Bundler = require('./bundler')

  bundler = new Bundler(module, require)
  bundler.dependency('my-npm-package')
  bundler.dependency('./my_local_file')
  bundler.dependency('./my_other_local_file', 'renamed-for-the-client')

  ...

  app = express()

  app.get('/application.js', (req, res) ->
    res.charset = 'utf-8'
    res.type('application/javascript')
    res.end(bundler.toString())
  )

In index.html

    <script type="text/javascript" charset="utf-8">
      document.addEventListener("DOMContentLoaded", function() {
        var foo = require("my-npm-package");
        var bar = require("./my_local_file");
        var baz = require("renamed-for-the-client");
      }, false);
    </script>

Note that, for now, this uses the server's paths in the filesystem to index the compiled cache --
a security leak. I will fix this shortly.

###

class Bundler
  class RichModule extends Module
    constructor: (@name, resolved, parent) ->
      super(resolved, parent)

    _compile: (content, filename) ->
      super(content, filename)
      @content = content

    require: (path) ->
      resolved = Module._resolveFilename(path, this)
      richModule = new RichModule(path, resolved, this)
      richModule.load(resolved)
      richModule.exports

    load: (filename) ->
      if nativeContent = process.binding('natives')[filename]
        @_compile(nativeContent, filename)
      else
        super(filename)

    toString: ->
      "{
        id: '#{@id}',
        content: function(exports, require, module) {#{@content}},
        children: {#{("'#{module.name}': #{module.toString()}" for module in @children).join(", ")}}
      }"

  constructor: (@parent, @require) ->
    @modules = []

  dependency: (name, rename = name) ->
    resolved = @require.resolve(name)
    richModule = new RichModule(rename, resolved, @parent)
    richModule.load(resolved)
    @modules.push(richModule)
    this

  toString: ->
    globals = "{#{("'#{module.name}': #{module.toString()}" for module in @modules).join(", ")}}"
    """
      (function() {
        if (!this.require) {
          var globals = {}, cache = {}, require = function(name, environment) {
            var module = environment[name], cached = cache[module.id];
            if (cached) {
              return cached.exports;
            } else if (module) {
              try {
                var module_ = {exports: {}};
                module.content(
                  module_.exports,
                  function(name) { return require(name, module.children) },
                  module_);
                cache[name] = module_.exports;
                return module_.exports;
              } catch (err) {
                delete cache[name];
                throw err;
              }
            } else {
              throw 'module \\'' + name + '\\' not found';
            }
          };
          this.require = function(name) {
            return require(name, globals);
          };
          return function(globals_) {
            for (var key in globals_) globals[key] = globals_[key];
          };
        }
      }).call(this)(#{globals});
    """

module.exports = Bundler
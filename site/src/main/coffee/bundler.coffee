Module = require('module')

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

    toString: () ->
      "{
        id: '#{@id}',
        content: function(exports, require, module) {#{@content}},
        children: {#{("'#{module.name}': #{module.toString()}" for module in @children).join(", ")}}
      }"

  constructor: (@parent, @require) ->
    @modules = []

  dependency: (name, rename = name) ->
    resolved = @require.resolve(name)
    richModule = new RichModule(rename, resolved, @parent, @require)
    richModule.load(resolved)
    @modules.push(richModule)
    this

  toString: () ->
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
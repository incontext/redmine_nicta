var editor = CodeMirror.fromTextArea('script_content', {
  parserfile: ["tokenizeruby.js", "parseruby.js"],
  stylesheet: "/plugin_assets/redmine_nicta/stylesheets/codemirror/rubycolors.css",
  path: "/plugin_assets/redmine_nicta/javascripts/codemirror/",
  lineNumbers: false,
  textWrapping: false,
  indentUnit: 2,
  parserConfig: {},
  height: '300px'
});

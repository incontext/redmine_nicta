
var RubyParser = Editor.Parser = (function() {
  // Token types that can be considered to be atoms.
  var atomicTypes = {"atom": true, "number": true, "variable": true, "string": true, "regexp": true};
  // Constructor for the lexical context objects.
  function JSLexical(indented, column, type, align, prev, info) {
    // indentation at start of this line
    this.indented = indented;
    // column at which this scope was opened
    this.column = column;
    // type of scope ('vardef', 'stat' (statement), 'form' (special form), '[', '{', or '(')
    this.type = type;
    // '[', '{', or '(' blocks that have any text after their opening
    // character are said to be 'aligned' -- any lines below are
    // indented all the way to the opening character.
    if (align != null)
      this.align = align;
    // Parent scope, if any.
    this.prev = prev;
    this.info = info;
  }
  
  var NORMALCONTEXT = 'rb-normal';
  var ERRORCLASS = 'rb-error';
  var COMMENTCLASS = 'rb-comment';
  var SYMBOLCLASS = 'rb-symbol';
  var CONSTCLASS = 'rb-constant';
  var OPCLASS = 'rb-operator';
  var INSTANCEMETHODCALLCLASS = 'rb-method'
  var VARIABLECLASS = 'rb-variable';
  var STRINGCLASS = 'rb-string';
  var FIXNUMCLASS =  'rb-fixnum rb-numeric';
  var METHODCALLCLASS = 'rb-method-call';
  var HEREDOCCLASS = 'rb-heredoc';
  var ERRORCLASS = 'rb-parse-error';
  var BLOCKCOMMENT = 'rb-block-comment';
  var FLOATCLASS = 'rb-float';
  var HEXNUMCLASS = 'rb-hexnum';
  var BINARYCLASS = 'rb-binary';
  var ASCIICODE = 'rb-ascii'
  var LONGCOMMENTCLASS = 'rb-long-comment';
  var WHITESPACEINLONGCOMMENTCLASS = 'rb-long-comment-whitespace';
  var KEWORDCLASS = 'rb-keyword';
  var REGEXPCLASS = 'rb-regexp';
  var GLOBALVARCLASS = 'rb-global-variable';
  var EXECCLASS = 'rb-exec';
  var INTRANGECLASS = 'rb-range';
  var OPCLASS = 'rb-operator';
  var METHODPARAMCLASS = 'rb-method-parameter';


  // My favourite JavaScript indentation rules.
  function indentRuby(lexical) {
    return function(firstChars) {
      var firstChar = firstChars && firstChars.charAt(0), type = lexical.type;
      var closing = firstChar == type;
      //console.log(lexical);
      
      if (type == "vardef")
        return lexical.indented + 2;
      else if (type == "form" && firstChar == "{")
        return lexical.indented;
      else if (type == "stat" || type == "form")
        return lexical.indented + indentUnit;
      else if (lexical.info == "switch" && !closing)
        return lexical.indented + (/^(?:case|default)\b/.test(firstChars) ? indentUnit : 2 * indentUnit);
      else if (lexical.align)
        return lexical.column - (closing ? 1 : 0);
      else
        return lexical.indented + (closing ? 0 : indentUnit);
    };
  }

  // The parser-iterator-producing function itself.
  function parseRuby(input, basecolumn) {
    // Wrap the input in a token stream
    var tokens = tokenizeRuby(input);
    // The parser state. cc is a stack of actions that have to be
    // performed to finish the current statement. For example we might
    // know that we still need to find a closing parenthesis and a
    // semicolon. Actions at the end of the stack go first. It is
    // initialized with an infinitely looping action that consumes
    // whole statements.
    var cc = [statement];
    // Context contains information about the current local scope, the
    // variables defined in that, and the scopes above it.
    var context = {prev: null, vars: {"this": true, "arguments": true, 'block' : 0}};
    // The lexical scope, used mostly for indentation.
    var lexical = new JSLexical((basecolumn || 0) - indentUnit, 0, "block", false);
    // Current column, and the indentation at the start of the current
    // line. Used to create lexical scope objects.
    var column = 0;
    var indented = 0;
    // Variables which are used by the mark, cont, and pass functions
    // below to communicate with the driver loop in the 'next'
    // function.
    var consume, marked;

    // The iterator object.
    var parser = {next: next, copy: copy};

    function next(){
      // Start by performing any 'lexical' actions (adjusting the
      // lexical variable), or the operations below will be working
      // with the wrong lexical state.
      while(cc[cc.length - 1].lex)
        cc.pop()();

      // Fetch a token.
      var token = tokens.next();

      // Adjust column and indented.
      if (token.type == "whitespace" && column == 0) {
        indented = token.value.length;
      }
      column += token.value.length;
      if (token.content == "\n"){
        indented = column = 0;
        // If the lexical scope's align property is still undefined at
        // the end of the line, it is an un-aligned scope.
        if (!("align" in lexical))
          lexical.align = false;
        // Newline tokens get an indentation function associated with
        // them.
        token.indentation = indentRuby(lexical);
      }
      // No more processing for meaningless tokens.
      //if (token.type == "whitespace" || token.type == "comment")
      //  return token;
      
      // When a meaningful token is found and the lexical scope's
      // align is undefined, it is an aligned scope.
      if (!("align" in lexical))
        lexical.align = true;

      // Execute actions until one 'consumes' the token and we can
      // return it.
      while(true) {
        consume = marked = false;
        // Take and execute the topmost action.
        cc.pop()(token, token.content);
        if (consume){
          // Marked is used to change the style of the current token.
          if (marked)
            token.style = marked;
            return token;
        }
      }
    }

    // This makes a copy of the parser state. It stores all the
    // stateful variables in a closure, and returns a function that
    // will restore them when called with a new input stream. Note
    // that the cc array has to be copied, because it is contantly
    // being modified. Lexical objects are not mutated, and context
    // objects are not mutated in a harmful way, so they can be shared
    // between runs of the parser.
    function copy(){
      var _context = context, _lexical = lexical, _cc = cc.concat([]), _tokenState = tokens.state;

      return function copyParser(input){
        context = _context;
        lexical = _lexical;
        cc = _cc.concat([]); // copies the array
        column = indented = 0;
        tokens = tokenizeRuby(input, _tokenState);
        return parser;
      };
    }

    // Helper function for pushing a number of actions onto the cc
    // stack in reverse order.
    function push(fs){
      for (var i = fs.length - 1; i >= 0; i--)
        cc.push(fs[i]);
    }
    // cont and pass are used by the action functions to add other
    // actions to the stack. cont will cause the current token to be
    // consumed, pass will leave it for the next action.
    function cont(){
      push(arguments);
      consume = true;
    }
    function pass(){
      push(arguments);
      consume = false;
    }
    // Used to change the style of the current token.
    function mark(style){
      marked = style;
    }

    // Push a new scope. Will automatically link the current scope.
    function pushcontext(){
      context = {prev: context, vars: {"this": true, "arguments": true, 'block' : 0}};
    }
    // Pop off the current scope.
    function popcontext(){
      context = context.prev;
    }
    // Register a variable in the current scope.
    function register(varname, style){
      if (context){
        context.vars[varname] = style;
      }
    }
    // Register a variable in the current scope.
    function isRegistered(varname){
      //console.log('"'+varname+'"', context);
      if (context) {
        if (context.vars[varname]) return true;
        var c = context.prev;
        while(c) {
          //console.log(c);
          if (c.vars[varname]) return true;
          c = c.prev;
        }
      }
      return false;
    }

    function registeredMark(varname){
      return context.vars[varname];
    }

    // Check whether a variable is defined in the current scope.
    function inScope(varname){
      var cursor = context;
      while (cursor) {
        if (cursor.vars[varname])
          return true;
        cursor = cursor.prev;
      }
      return false;
    }

    // Push a new lexical context of the given type.
    function pushlex(type, info) {
      var result = function(){
        lexical = new JSLexical(indented, column, type, null, lexical, info)
      };
      result.lex = true;
      return result;
    }
    // Pop off the current lexical context.
    function poplex(){
      lexical = lexical.prev;
    }
    poplex.lex = true;
    // The 'lex' flag on these actions is used by the 'next' function
    // to know they can (and have to) be ran before moving on to the
    // next token.

    // Creates an action that discards tokens until it finds one of
    // the given type.
    function expect(wanted){
      return function expecting(type){
        if (type == wanted) cont();
        else cont(arguments.callee);
      };
    }

    // Looks for a statement, and then calls itself.
/*    function statements(type){
      return pass(statement, statements);
    }*/
    // Dispatches various types of statements based on the type of the
    // current token.
    var lastToken = null;
    var shown = 0;
    
    function statement(token){
      /*
      if(shown > 100 && shown < 200) {
        console.log('statement', token);
      }*/
      shown += 1;
      if (token.content == "begin" || token.content == "class" || token.content == "module") {
        lastToken = token;
        pushcontext();
        cont(statement);
        return;
      }
      if (token.content == "do") {
        if (!context.block) {
          context.block = 0;
        }
        context.block += 1
      }
      
      if (token.style == KEWORDCLASS && token.content == "end") {
        if (context.block && context.block > 0) {
          context.block -= 1;
        } else{
          popcontext();
        }
      }      
      if (token.style == INSTANCEMETHODCALLCLASS) {
        lastVar = token;
      }
      if (token.content == '|' && (lastToken.content == "do" || lastToken.content == "{")) {
        lastToken = token;
        //console.log('after 2', context);
        mark(NORMALCONTEXT);
        cont(blockparams);
        return;
        //cont(statement);
      }
      
      if (token.content == "def") {
        pushcontext();
        cont(functiondef);
        lastToken = token;
        return;
      } 
      if (token.style == 'rb-method' || token.style == 'rb-variable') {
        //console.log('is "'+token.content+'" registered?');
        if (isRegistered(token.content)) {
          mark(registeredMark(token.content));
        }
      }

      if (token.style == VARIABLECLASS) {
        register(token.content, VARIABLECLASS);
      }

      // long comment support
      if (lastToken && lastToken.content == "\n") {
        if (token.content == '=begin') {
          cont(longccomment);
          lastToken = token;
          return;
        }
      }

      lastToken = token;
      cont(statement);
    }
    
    function longccomment(token, value) {
      if (token.style == 'whitespace') {
        token.style += ' '+WHITESPACEINLONGCOMMENTCLASS;
      } else {
        token.style = LONGCOMMENTCLASS;
      }
      if (lastToken && lastToken.content == "\n") {
        if (token.content == '=end') {
          cont(statement);
          return;
        }
      }                
      lastToken = token;
      cont(longccomment);
    }
    
    function blockparams(token, value) {
      //console.log('blockparams', token);
      if (token.style == 'rb-method' || token.style == 'rb-variable') {
        mark(METHODPARAMCLASS);
        register(token.value, METHODPARAMCLASS);
      }
      if (value != '|' && value != "\n") {
        cont(blockparams);                
      } else {
        if (token.content == '|') {
          token.style = NORMALCONTEXT;
        }
        // return to statement
        cont(statement);
        //console.log('returning to statement');
      }
      lastToken = token;
    }
    
    // A function definition creates a new context, and the variables
    // in its argument list have to be added to this context.
    function functiondef(token, value){
      if (token.style == 'rb-method' || token.style == 'rb-variable') {
        register(value, METHODPARAMCLASS);
        mark(METHODPARAMCLASS);
        cont(functiondef);
      }
      else if (value == "\n") {
        //console.log('returning to statement');
        cont(statement);
      } else {
        cont(functiondef);
      }
    }
    
    function longComment(token, value) {
      // TODO
    }
    
    function funarg(type, value){
      if (type == "variable"){register(value); cont();}
    }

    // Look for statements until a closing brace is found.
    function block(type){
      if (type == "}") cont();
      else pass(statement, block);
    }


    return parser;
  }

  return {make: parseRuby, electricChars: "{}:"};
})();


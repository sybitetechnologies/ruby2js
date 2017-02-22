gem 'minitest'
require 'minitest/autorun'
require 'ruby2js/filter/react'

describe Ruby2JS::Filter::React do
  
  def to_js(string)
    Ruby2JS.convert(string, filters: [Ruby2JS::Filter::React], scope: self).to_s
  end
  
  describe :createClass do
    it "should create classes" do
      to_js( 'class Foo<React; end' ).
        must_equal 'var Foo = React.createClass({displayName: "Foo"})'
    end

    it "should create methods" do
      to_js( 'class Foo<React; def f(); end; end' ).
        must_include 'f: function() {}'
    end

    it "should convert initialize methods to getInitialState" do
      to_js( 'class Foo<React; def initialize(); end; end' ).
        must_include 'getInitialState: function() {return {}}'
    end

    it "should create default getInitialState methods" do
      to_js( 'class Foo<React; def foo(); @i=1; end; end' ).
        must_include 'getInitialState: function() {return {}}'
    end

    it "should initialize, accumulate, and return state" do
      to_js( 'class Foo<React; def initialize; @a=1; b=2; @b = b; end; end' ).
        must_include 'getInitialState: function() {this.state = {a: 1}; ' +
          'var b = 2; this.state.b = b; return this.state}'
    end

    it "should collapse instance variable assignments into a return" do
      to_js( 'class Foo<React; def initialize; @a=1; @b=2; end; end' ).
        must_include 'getInitialState: function() {return {a: 1, b: 2}}'
    end

    it "should handle parallel instance variable assignments" do
      to_js( 'class Foo<React; def initialize; @a=@b=1; end; end' ).
        must_include 'getInitialState: function() {return {a: 1, b: 1}}'
    end

    it "should handle operator assignments on state values" do
      to_js( 'class Foo<React; def initialize; @a+=1; end; end' ).
        must_include 'this.state = {}; this.state.a++; return this.state'
    end
  end

  describe "Wunderbar/JSX processing" do
    it "should create elements for HTML tags" do
      to_js( 'class Foo<React; def render; _a; end; end' ).
        must_include 'return React.createElement("a")'
    end

    it "should create elements for React Components" do
      to_js( 'class Foo<React; def render; _A; end; end' ).
        must_include 'return React.createElement(A)'
    end

    it "should create elements with attributes and text" do
      to_js( 'class Foo<React; def render; _a "name", href: "link"; end; end' ).
        must_include 'return React.createElement("a", {href: "link"}, "name")}})'
    end

    it "should create simple nested elements" do
      to_js( 'class Foo<React; def render; _a {_b}; end; end' ).
        must_include ' React.createElement("a", null, React.createElement("b"))'
    end

    it "should handle options with blocks" do
      to_js( 'class Foo<React; def render; _a options do _b; end; end; end' ).
        must_include ' React.createElement("a", options, ' +
          'React.createElement("b"))'
    end

    unless RUBY_VERSION =~ /^1/
      it "should handle **options" do
        to_js( 'class Foo<React; def render; _a **options; end; end' ).
          must_include ' React.createElement("a", options)'
      end

      it "should handle **options with blocks" do
        to_js('class Foo<React; def render; _a **options do _b; end; end; end').
          must_include ' React.createElement("a", options, ' +
            'React.createElement("b"))'
      end
    end

    it "should create complex nested elements" do
      result = to_js('class Foo<React; def render; _a {c="c"; _b c}; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["a", null];'
      result.must_include '$_.push(React.createElement("b", null, c));'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should treat explicit calls to React.createElement as simple" do
      to_js( 'class Foo<React; def render; _a {React.createElement("b")}; ' +
        'end; end' ).
        must_include ' React.createElement("a", null, React.createElement("b"))'
    end

    it "should push results of explicit calls to React.createElement" do
      result = to_js('class Foo<React; def render; _a {c="c"; ' +
        'React.createElement("b", null, c)}; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["a", null];'
      result.must_include '$_.push(React.createElement("b", null, c));'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should handle call with blocks to React.createElement" do
      result = to_js( 'class Foo<React; def render; ' +
        'React.createElement("a") {_b}; end; end' )
      result.must_include 'React.createElement.apply(React,'
      result.must_include 'function() {var $_ = ["a"];'
      result.must_include '$_.push(React.createElement("b")'
    end

    it "should iterate" do
      result = to_js('class Foo<React; def render; _ul list ' + 
        'do |i| _li i; end; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["ul", null];'
      result.must_include 'list.forEach(function(i)'
      result.must_include '{$_.push(React.createElement("li", null, i))}'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should iterate with markaby style classes/ids" do
      result = to_js('class Foo<React; def render; _ul.todos list ' + 
        'do |i| _li i; end; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["ul", {className: "todos"}];'
      result.must_include 'list.forEach(function(i)'
      result.must_include '{$_.push(React.createElement("li", null, i))}'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should handle text nodes" do
      to_js( 'class Foo<React; def render; _a {_ @text}; end; end' ).
        must_include 'return React.createElement("a", null, this.state.text)'
    end

    it "should apply text nodes" do
      to_js( 'class Foo<React; def render; _a {text="hi"; _ text}; end; end' ).
        must_include 'var text = "hi"; $_.push(text);'
    end

    it "should handle arbitrary nodes" do
      to_js( 'class Foo<React; def render; _a {_[@text]}; end; end' ).
        must_include 'return React.createElement("a", null, this.state.text)'
    end

    it "should handle lists of arbitrary nodes" do
      to_js( 'class Foo<React; def render; _a {_[@text, @text]}; end; end' ).
        must_include 'return React.createElement.apply(React, ' +
          '["a", null].concat([this.state.text, this.state.text])'
    end

    it "should apply arbitrary nodes" do
      to_js( 'class Foo<React; def render; _a {text="hi"; _[text]}; end; end' ).
        must_include 'var text = "hi"; $_.push(text);'
    end

    it "should apply list of arbitrary nodes" do
      to_js( 'class Foo<React; def render; _a {text="hi"; _[text, text]}; end; end' ).
        must_include 'var text = "hi"; $_.push(text, text);'
    end
  end

  describe "render method" do
    it "should wrap multiple elements with a span" do
      result = to_js( 'class Foo<React; def render; _h1 "a"; _p "b"; end; end' )
      result.must_include 'return React.createElement("span", null, React'
      result.must_include ', React.createElement("h1", null, "a"),'
      result.must_include ', React.createElement("p", null, "b"))}})'
    end

    it "should wrap anything that is not a method or block call with a span" do
      result = to_js( 'class Foo<React; def render; if @a; _p "a"; else;_p "b"; end; end;end' )
      result.must_include 'return React.createElement.apply(React'
      result.must_include 'push(React.createElement("p", null, "a"))} else {'
      result.must_include 'push(React.createElement("p", null, "b"))};'
    end

    it "should insert a span if no elements are present" do
      result = to_js( 'class Foo<React; def render; end; end' )
      result.must_include 'return React.createElement("span")'
    end

    it "should insert a span if method is empty" do
      result = to_js( 'class Foo<React; def render; end; end' )
      result.must_include 'return React.createElement("span")'
    end
  end

  describe "class attributes" do
    it "should handle class attributes" do
      to_js( 'class Foo<React; def render; _a class: "b"; end; end' ).
        must_include 'React.createElement("a", {className: "b"})'
    end

    it "should handle className attributes" do
      to_js( 'class Foo<React; def render; _a className: "b"; end; end' ).
        must_include 'React.createElement("a", {className: "b"})'
    end

    it "should handle markaby syntax" do
      to_js( 'class Foo<React; def render; _a.b.c href: "d"; end; end' ).
        must_include 'React.createElement("a", {className: "b c", href: "d"})'
    end

    it "should handle mixed strings" do
      to_js( 'class Foo<React; def render; _a.b class: "c"; end; end' ).
        must_include 'React.createElement("a", {className: "b c"})'
    end

    it "should handle mixed strings and a value" do
      to_js( 'class Foo<React; def render; _a.b class: c; end; end' ).
        must_include 'React.createElement("a", {className: "b " + (c || "")})'
    end

    it "should handle mixed strings and a conditional value" do
      to_js( 'class Foo<React; def render; _a.b class: ("c" if d); end; end' ).
        must_include 'React.createElement("a", {className: "b " + (d ? "c" : "")})'
    end

    it "should handle only a value" do
      to_js( 'class Foo<React; def render; _a class: c; end; end' ).
        must_include 'React.createElement("a", {className: c})'
    end

    it "should handle a constant string" do
      to_js( 'class Foo<React; def render; _a class: "x"; end; end' ).
        must_include 'React.createElement("a", {className: "x"})'
    end
  end

  describe "other attributes" do
    it "should handle markaby syntax ids" do
      to_js( 'class Foo<React; def render; _a.b! href: "c"; end; end' ).
        must_include 'React.createElement("a", {id: "b", href: "c"})'
    end

    it "should map for attributes to htmlFor" do
      to_js( 'class Foo<React; def render; _a for: "b"; end; end' ).
        must_include 'React.createElement("a", {htmlFor: "b"})'
    end

    it "should map case insensitive attributes to javascript properties" do
      to_js( 'class Foo<React; def render; _input tabindex: 1; end; end' ).
        must_include 'React.createElement("input", {tabIndex: 1})'
    end

    it "should map style string attributes to hashes" do
      to_js( 'class Foo<React; def render; _a ' +
        'style: "color: blue; margin-top: 0"; end; end' ).
        must_include '{style: {color: "blue", marginTop: 0}}'
    end
  end

  describe "~refs" do
    it "should handle ~ symbols properties" do
      to_js( 'class Foo<React; def method; ~x.textContent; end; end' ).
        must_include '("getDOMNode" in this.refs.x ? this.refs.x.getDOMNode() : this.refs.x).textContent'
    end

    it "should handle ~ lvar properties" do
      to_js( 'class Foo<React; def method; text = ~x.textContent; end; end' ).
        must_include 'text = ("getDOMNode" in this.refs.x ? this.refs.x.getDOMNode() : this.refs.x).textContent'
    end

    it "should handle ~ methods" do
      to_js( 'class Foo<React; def method; ~x.remove(); end; end' ).
        must_include '("getDOMNode" in this.refs.x ? this.refs.x.getDOMNode() : this.refs.x).remove()'
    end

    it "should convert ~(expression) to querySelector calls" do
      to_js( 'class Foo<React; def method; ~(x).remove(); end; end' ).
        must_include 'document.querySelector(x).remove()'
    end

    it "should convert ~'a b' to querySelector calls" do
      to_js( 'class Foo<React; def method; ~"a b".remove(); end; end' ).
        must_include 'document.querySelector("a b").remove()'
    end

    it "should convert ~'.a.b_c' to getElementsByClassName calls" do
      to_js( 'class Foo<React; def method; ~".a.b_c".remove(); end; end' ).
        must_include 'document.getElementsByClassName("a b-c")[0].remove()'
    end

    it "should convert ~'#a_b' to getElementById calls" do
      to_js( 'class Foo<React; def method; ~"#a_b".remove(); end; end' ).
        must_include 'document.getElementById("a-b").remove()'
    end

    it "should convert ~'a_b' to getElementsByTagName calls" do
      to_js( 'class Foo<React; def method; ~"a_b".remove(); end; end' ).
        must_include 'document.getElementsByTagName("a-b")[0].remove()'
    end

    it "should leave ~~a alone" do
      to_js( 'class Foo<React; def method; ~~a; end; end' ).
        must_include '~~a'
    end

    it "should convert ~~~a to ~a" do
      to_js( 'class Foo<React; def method; ~~~a; end; end' ).
        must_include '~a'
    end
  end

  describe "map gvars/ivars/cvars to refs/state/prop" do
    it "should map global variables to refs" do
      to_js( 'class Foo<React; def method; $x; end; end' ).
        must_include '"getDOMNode" in this.refs.x ? this.refs.x.getDOMNode() : this.refs.x'
    end

    it "should map instance variables to state" do
      to_js( 'class Foo<React; def method; @x; end; end' ).
        must_include 'this.state.x'
    end

    it "should map setting instance variables to setState" do
      to_js( 'class Foo<React; def method; @x=1; end; end' ).
        must_include 'this.setState({x: 1})'
    end

    it "should map parallel instance variables to setState" do
      to_js( 'class Foo<React; def method(); @x=@y=1; end; end' ).
        must_include 'this.setState({x: 1, y: 1})'
    end

    it "should map consecutive instance variables to setState" do
      to_js( 'class Foo<React; def method(); @x=1; @y=2; end; end' ).
        must_include 'this.setState({x: 1, y: 2})'
    end

    it "should create temporary variables when needed" do
      to_js( 'class Foo<React; def f; @a+=1; b=@a; end; end' ).
        must_include 'var $a = this.state.a; $a++; var b = $a; ' +
          'return this.setState({a: $a})'
    end

    it "should create temporary variables when conditionals are involved" do
      to_js( 'class Foo<React; def f; @a+=1 if 1; b=@a; end; end' ).
        must_include 'var $a = this.state.a; if (1) {$a++}; var b = $a; ' +
          'return this.setState({a: $a})'
    end

    it "should create temporary variables when blocks are involved" do
      to_js( 'class Foo<React; def f; foo {@a=1}; b=@a; end; end' ).
        must_include 'foo(function() {self.setState({a: $a = 1})}); '
          'var b = $a; return this.setState({a: $a})'
    end

    it "should create temporary variables when blocks+opasgn are involved" do
      to_js( 'class Foo<React; def f; foo {@a+=1}; b=@a; end; end' ).
        must_include 'var $a = this.state.a; ' +
          'foo(function() {self.setState({a: ++$a})}); var b = $a; ' +
          'return this.setState({a: $a})'
    end

    it "shouldn't produce temporary variables for inline event handlers" do
      js = to_js( 'class F < React; def render; _input value: @draft; ' +
        '_button "Cancel", onClick:-> {@draft = @base}; ' +
        '_button "Save", disabled: @draft == @base; end; end' )
      js.must_include 'self.setState({draft: event.target.value})'
      js.must_include '{onClick: function() ' +
        '{self.setState({draft: self.state.base})}}'
      js.must_include '{disabled: this.state.draft == this.state.base}'
    end

    it "should treat singleton method definitions as a separate scope" do
      js = to_js( 'class F < React; def m(); def x.a; @i=1; end; @i; end; end' )
      js.must_include 'this.setState({i: 1})'
      js.must_include 'this.state.i'
    end

    it "should generate code to handle instance vars within singleton method" do
      js = to_js('class F < React; def m(); def x.a; @i=1; @i+1; end; end; end')
      js.must_include '$i = 1'
      js.must_include '$i + 1'
      js.must_include 'this.setState({i: $i}'
    end

    it "should map class variables to properties" do
      to_js( 'class Foo<React; def method; @@x; end; end' ).
        must_include 'this.props.x'
    end

    it "should not support assigning to class variables" do
      proc { 
        to_js( 'class Foo<React; def method; @@x=1; end; end' )
      }.must_raise NotImplementedError
    end
  end

  describe "method calls" do
    it "should handle ivars" do
      to_js( 'class Foo<React; def method; @x.(); end; end' ).
        must_include 'this.state.x()'
    end

    it "should handle cvars" do
      to_js( 'class Foo<React; def method; @@x.(); end; end' ).
        must_include 'this.props.x()'
    end

    it "should handle gvars" do
      to_js( 'class Foo<React; def method; $x.(); end; end' ).
        must_include '("getDOMNode" in this.refs.x ? this.refs.x.getDOMNode() : this.refs.x)()'
    end
  end

  describe 'react calls' do
    it 'should create elements' do
      to_js( 'React.render _Element, document.getElementById("sidebar")' ).
        must_include 'React.createElement(Element)'
    end

    it 'should substitute scope instance variables / props' do
      @data = 5
      to_js( "React.render _Element(data: @data),
        document.getElementById('sidebar')" ).
        must_include 'React.createElement(Element, {data: 5})'
    end
  end

  describe "react statics" do
    it "should handle static properties" do
      to_js( 'class Foo<React; def self.one; 1; end; end' ).
        must_include 'statics: {one: 1}'
    end

    it "should handle computed static properties" do
      to_js( 'class Foo<React; def self.one; return 1; end; end' ).
        must_include 'statics: {get one() {return 1}}'
    end

    it "should handle static methods" do
      to_js( 'class Foo<React; def self.one(); return 1; end; end' ).
        must_include 'statics: {one: function() {return 1}}'
    end
  end

  describe "componentWillReceiveProps" do
    it "should should insert props on calls to componentWillReceiveProps" do
      to_js( 'class Foo<React; def componentWillMount();' +
        'self.componentWillReceiveProps(); end; end' ).
        must_include 'this.componentWillReceiveProps(this.props)'
    end

    it "should should insert props arg on componentWillReceiveProps" do
      to_js( 'class Foo<React; def componentWillReceiveProps();' +
        '@foo = @@foo; end; end' ).
        must_include 'function($$props) {this.setState({foo: $$props.foo})}'
    end

    it "should should use props arg on componentWillReceiveProps" do
      to_js( 'class Foo<React; def componentWillReceiveProps(props);' +
        '@foo = @@foo; end; end' ).
        must_include 'function(props) {this.setState({foo: props.foo})}'
    end
  end

  describe "controlled components" do
    it "should should automatically create onChange value functions" do
      to_js( 'class Foo<React; def render; _input value: @x; end; end' ).
        must_include 'onChange: function(event) {self.setState({x: event.target.value}'
    end

    it "should should automatically create onChange checked functions" do
      to_js( 'class Foo<React; def render; _input checked: @x; end; end' ).
        must_include 'onChange: function() {self.setState({x: !self.state.x}'
    end

    it "should should retain onChange functions" do
      to_js( 'class Foo<React; def render; _input checked: @x, onChange: self.change; end; end' ).
        must_include 'onChange: this.change'
    end
  end

  describe Ruby2JS::Filter::DEFAULTS do
    it "should include React" do
      Ruby2JS::Filter::DEFAULTS.must_include Ruby2JS::Filter::React
    end
  end
end

gem 'minitest'
require 'minitest/autorun'
require 'ruby2js'

describe 'not implemented' do
  # see https://github.com/whitequark/parser/blob/master/doc/AST_FORMAT.md
  
  def todo(string)
    proc { Ruby2JS.convert(string, filters: []) }.must_raise NotImplementedError
  end

  it "range inclusive" do
    # NOTE: for loops and filter/functions will handle the special case of array indexes
    # NOTE: filter/rubyjs implements this
    todo( '1..2' )
  end

  it "range exclusive" do
    # NOTE: for loops and filter/functions will handle the special case of array indexes
    # NOTE: filter/rubyjs implements this
    todo( '1...2' )
  end

  it "Top-level constant" do
    todo( '::Foo' )
  end

  it "decomposition" do
    todo( 'def f(a, (foo, *bar)); end' )
  end

  it "yield" do
    todo( 'yield' )
  end

  it "catching exceptions without a variable" do
    todo("begin; rescue Exception; end")
  end

  it "catching exceptions with different variables" do
    todo("begin; a; rescue StandardException => se; b; " +
      "rescue Exception => e; c; end")
  end

  it "else clauses in begin...end" do
    todo("begin; a; rescue => e; b; else; c; end")
  end

  it "redo" do
    todo("redo")
  end

  it "retry" do
    todo("retry")
  end

  it "flip-flops" do
    todo("if a..b; end")
  end

  it "implicit matches" do
    todo("if /a/; end")
  end

  it "methods definitions with invalid names" do
    todo("def bang?; end")
    todo("def bang!; end")
  end

  it "regular expression back-references" do
    todo("$&")
    todo("$`")
    todo("$'")
    todo("$+")
  end

  it "<=>" do
    # NOTE: filter/rubyjs implements this
    todo("a<=>b")
  end

  unless RUBY_VERSION =~ /^1/
    it "keyword splat" do
      todo( 'foo **bar' )
    end

    it "keyword splat interpolation" do
      todo( '{ foo: 2, **bar }' )
    end

    it "keyword argument" do
      todo( 'def f(a:nil); end' )
    end
  end
end

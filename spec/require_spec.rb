gem 'minitest'
require 'minitest/autorun'
require 'ruby2js/filter/require'

describe Ruby2JS::Filter::Require do
  
  def to_js( string)
    Ruby2JS.convert(string, filters: [Ruby2JS::Filter::Require],
      file: __FILE__).to_s
  end
  
  describe :statement do
    it "should handle require statements" do
      to_js( 'require "require/test1.rb"' ).
        must_equal 'console.log("test2"); console.log("test3")'
    end

    it "should support implicit '.rb' extensions" do
      to_js( 'require "require/test1"' ).
        must_equal 'console.log("test2"); console.log("test3")'
    end
  end

  describe :expression do
    it "should leave local variable assignment expressions alone" do
      to_js( 'fs = require("fs")' ).
        must_equal 'var fs = require("fs")'
    end

    it "should leave constant assignment expressions alone" do
      to_js( 'React = require("React")' ).
        must_equal 'var React = require("React")'
    end
  end

  describe Ruby2JS::Filter::DEFAULTS do
    it "should include Require" do
      Ruby2JS::Filter::DEFAULTS.must_include Ruby2JS::Filter::Require
    end
  end
end

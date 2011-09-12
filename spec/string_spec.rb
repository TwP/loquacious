
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe String do

  it "reduces to a size by replacing characters from the middle" do
    "this is a longish string".reduce(10).should be == "this...ing"
    "this is a longish string".reduce(15).should be == "this i...string"
    "this is a longish string".reduce(24).should be == "this is a longish string"

    "this is a longish string".reduce(10, '--').should be == "this--ring"
  end

  it "indents by a given number of spaces" do
    "hello".indent(2).should be == "  hello"
    "hello\nworld".indent(4).should be == "    hello\n    world"
    "  a\nslightly\n longer\n   string\n".indent(2).should be == "    a\n  slightly\n   longer\n     string\n  "
  end

  it "indents using a leader string" do
    "hello".indent("foo ").should be == "foo hello"
    "hello\nworld".indent("...").should be == "...hello\n...world"
    "  a\nslightly\n longer\n   string\n".indent("#").should be == "#  a\n#slightly\n# longer\n#   string\n#"
  end

  it "removes a leading gutter from all lines" do
    str = "  | foo"
    result = str.gutter!
    result.should be == " foo"
    result.should equal(str)

    str = <<-STRING
    | And this is where gutters really shine!
    | HERE DOCS!!
    ||they are the best
    |
    |    You can indent stuff nicely and all that
    |all done now
    STRING

    str.gutter!
    str.should be == " And this is where gutters really shine!\n HERE DOCS!!\n|they are the best\n\n    You can indent stuff nicely and all that\nall done now\n"
  end

  it "creates a copy when removing a leading gutter" do
    str = "  | foo"
    result = str.gutter
    result.should be == " foo"
    result.should_not equal(str)
  end
end

# EOF

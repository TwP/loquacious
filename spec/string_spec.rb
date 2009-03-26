
require File.join(File.dirname(__FILE__), %w[spec_helper])

describe String do

  it "reduces to a size by replacing characters from the middle" do
    "this is a longish string".reduce(10).should == "this...ing"
    "this is a longish string".reduce(15).should == "this i...string"
    "this is a longish string".reduce(24).should == "this is a longish string"

    "this is a longish string".reduce(10, '--').should == "this--ring"
  end

  it "indents by a given number of spaces" do
    "hello".indent(2).should == "  hello"
    "hello\nworld".indent(4).should == "    hello\n    world"
    "  a\nslightly\n longer\n   string\n".indent(2).should == "    a\n  slightly\n   longer\n     string\n  "
  end

  it "indents using a leader string" do
    "hello".indent("foo ").should == "foo hello"
    "hello\nworld".indent("...").should == "...hello\n...world"
    "  a\nslightly\n longer\n   string\n".indent("#").should == "#  a\n#slightly\n# longer\n#   string\n#"
  end

end

# EOF

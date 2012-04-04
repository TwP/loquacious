
class String

  # call-seq:
  #    reduce( width, ellipses = '...' )    #=> string
  #
  # Reduce the size of the current string to the given _width_ by removing
  # characters from the middle of the string and replacing them with
  # _ellipses_. If the _width_ is greater than the length of the string, the
  # string is returned unchanged. If the _width_ is less than the length of
  # the _ellipses_, then the _ellipses_ are returned.
  #
  def reduce( width, ellipses = '...')
    raise ArgumentError, "width cannot be negative: #{width}" if width < 0

    return self if length <= width

    remove = length - width + ellipses.length
    return ellipses.dup if remove >= length

    left_end = (length + 1 - remove) / 2
    right_start = left_end + remove

    left = self[0,left_end]
    right = self[right_start,length-right_start]

    left << ellipses << right
  end

  # call-seq:
  #    "foo".indent( 2 )        #=> "  foo"
  #    "foo".indent( '#  ' )    #=> "# foo"
  #
  # Indent the string by the given number of spaces. Alternately, if a
  # leader string is given it will be used to indent with instead of spaces.
  # Indentation is performed at the beginning of the string and after every
  # newline character.
  #
  #   "foo\nbar".indent( 2 )    #=> "  foo\n  bar"
  #
  def indent( leader )
    leader =
        Numeric === leader ? ' ' * leader.to_i : leader.to_s
    str = self.gsub("\n", "\n"+leader)
    str.insert(0, leader)
    str
  end

  # call-seq:
  #    "  | foo\n  | bar".gutter!    #=> " foo\n bar"
  #
  # Removes a leading _gutter_ from all lines in the string. The gutter is
  # defined leading whitespace followed by a single pipe character. This
  # method is very useful with heredocs.
  #
  # The string will be altered by this method.
  #
  def gutter!
    gsub! %r/^[\t\f\r ]*\|?/, ''
    self
  end

  # call-seq:
  #    "  | foo\n  | bar".gutter!    #=> " foo\n bar"
  #
  # Removes a leading _gutter_ from all lines in the string. The gutter is
  # defined leading whitespace followed by a single pipe character. This
  # method is very useful with heredocs.
  #
  def gutter
    self.dup.gutter!
  end
end  # class String


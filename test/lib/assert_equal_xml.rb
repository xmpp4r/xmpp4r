module Test::Unit::Assertions
  public
  ##
  # Like assert_equal, but actual comparision switches parameters to
  # make use of our attribute order agnostic REXML#==
  def assert_equal_xml(expected, actual, message=nil)
    full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
    assert_block(full_message) { actual == expected }
  end
end


require "./spec_helper"

require "../src/sorted_set"

describe SortedSet do
  it "adds and checks for items" do
    set = SortedSet(String, Int32).new
    set.add "ten", 10
    set.add "eighteen", 18
    set.add "seven", 7
    set.add "fifteen", 15
    set.add "sixteen", 16
    set.add "thirty", 30
    set.add "twenty-five", 25
    set.add "forty", 40
    set.add "sixty", 60
    set.add "two", 2
    set.add "one", 1
    set.add "seventy", 70

    set.to_a.should eq [
      SortedSet::Entry.new("one", 1),
      SortedSet::Entry.new("two", 2),
      SortedSet::Entry.new("seven", 7),
      SortedSet::Entry.new("ten", 10),
      SortedSet::Entry.new("fifteen", 15),
      SortedSet::Entry.new("sixteen", 16),
      SortedSet::Entry.new("eighteen", 18),
      SortedSet::Entry.new("twenty-five", 25),
      SortedSet::Entry.new("thirty", 30),
      SortedSet::Entry.new("forty", 40),
      SortedSet::Entry.new("sixty", 60),
      SortedSet::Entry.new("seventy", 70),
    ]
  end

  it "allows dupes?" do
    set = SortedSet(String, Int32).new
    set.add "foo", 1
    set.add "foo", 1
    set.add "bar", 1

    pp set.to_a
  end
end

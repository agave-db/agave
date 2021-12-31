require "./rb_tree"

class SortedSet(Value, Score)
  record Entry(Value, Score), value : Value, score : Score do
    include Comparable(Entry(Value, Score))

    def <=>(other : self)
      score <=> other.score
    end
  end

  include Enumerable(Entry(Value, Score))

  @tree = RedBlack::Tree(Entry(Value, Score)).new
  @mutex = Mutex.new

  def add(value : Value, score : Score) : self
    @tree.insert Entry(Value, Score).new(value, score)
    self
  end

  def each(&block : Entry(Value, Score) ->)
    @tree.each(&block)
  end
end

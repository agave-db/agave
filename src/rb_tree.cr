require "colorize"
require "random"

module RedBlack
  enum Color
    Red
    Black
  end

  class Leaf
    def red?
      false
    end

    def black?
      true
    end

    def to_s(io)
    end

    def black!
    end

    def red!
      raise "Leaf has to be black"
    end
  end

  HLINE   = "─"
  VLINE   = "│"
  BELOW   = "└"
  ABOVE   = "┌"
  NODE    = "┤"
  ENDING  = "╢"
  NEWLINE = "\n"
  SPACE   = " "
  ROOT    = "@"
  REDCIRC = "●".colorize(:red)
  BLKCIRC = "●".colorize(:blue)

  class Node(V)
    property val, parent, left, right, color

    def initialize(@parent : (Node(V) | Leaf), @val : V)
      @left = Leaf.new.as(Node(V) | Leaf)
      @right = Leaf.new.as(Node(V) | Leaf)
      @color = Color::Red
    end

    delegate red?, black?, to: color

    def red!
      @color = Color::Red
    end

    def black!
      @color = Color::Black
    end

    def to_s(io)
      io << @val
    end
  end

  class Tree(V)
    include Enumerable(V)

    getter size
    @sm : Proc(V, V, Bool)
    @eq : Proc(V, V, Bool)

    def initialize
      @root = Leaf.new.as(Node(V) | Leaf)
      @sm = ->(v : V, w : V) { v < w }
      @eq = ->(v : V, w : V) { v == w }
      @size = 0
    end

    def initialize(&smaller : (V, V) -> Bool)
      @root = Leaf.new.as(Node(V) | Leaf)
      @sm = ->(v : V, w : V) { smaller.call(v, w) }
      @eq = ->(v : V, w : V) { !smaller.call(v, w) && !smaller.call(w, v) }
      @size = 0
    end

    private def transplant(u : Node(V), v)
      if (p = u.parent).is_a? Leaf
        @root = v
      elsif u == p.left
        p.left = v
      else
        p.right = v
      end
      if v.is_a? Node(V)
        v.parent = u.parent
      end
    end

    private def left_rotate(x : Node(V))
      y = x.right
      if y.is_a? Leaf
        raise "Can't rotate under current conditions"
      end
      x.right = y.left
      if !(lt = y.left).is_a? Leaf
        lt.parent = x
      end
      y.parent = x.parent
      if (p = x.parent).is_a? Leaf
        @root = y
      elsif x == p.left
        p.left = y
      else
        p.right = y
      end
      y.left = x
      x.parent = y
    end

    private def right_rotate(x : Node(V))
      y = x.left
      if y.is_a? Leaf
        raise "Can't rotate under current conditions"
      end
      x.left = y.right
      if !(rt = y.right).is_a? Leaf
        rt.parent = x
      end
      y.parent = x.parent
      if (p = x.parent).is_a? Leaf
        @root = y
      elsif x == p.right
        p.right = y
      else
        p.left = y
      end
      y.right = x
      x.parent = y
    end

    def insert(v : V)
      n = Node.new(Leaf.new, v)
      @size += 1
      x = @root
      y = Leaf.new
      while !x.is_a? Leaf
        y = x
        if @sm.call(n.val, x.val)
          x = x.left
        else
          x = x.right
        end
      end
      n.parent = y
      if y.is_a? Leaf
        @root = n
      elsif @sm.call(n.val, y.val)
        y.left = n
      else
        y.right = n
      end
      if (p = n.parent).is_a? Leaf
        n.black!
        return
      elsif p.parent.is_a? Leaf
        return
      else
        fix_insert(n)
      end
      self
    end

    def <<(v : V)
      insert(v)
    end

    private def fix_insert(k : Node(V))
      while !(p = k.parent).is_a? Leaf && p.red?
        gp = p.parent
        if gp.is_a? Leaf
          raise "Unexpectedly reached root"
        end
        if p == gp.right
          u = gp.left
          if u.red?
            u.black!
            p.black!
            gp.red!
            k = gp
          else
            if k == p.left
              k = p
              right_rotate(k)
            end
            p = k.parent
            if p.is_a? Leaf
              raise "Rotation error"
            end
            p.black!
            gp = p.parent
            if gp.is_a? Leaf
              raise "Rotation error"
            end
            gp.red!
            left_rotate(gp)
          end
        else
          u = gp.right
          if u.red?
            u.black!
            p.black!
            gp.red!
          else
            if k == p.right
              k = p
              left_rotate(k)
            end
            p = k.parent
            if p.is_a? Leaf
              raise "Rotation error"
            end
            p.black!
            gp = p.parent
            if gp.is_a? Leaf
              raise "Rotation error"
            end
            gp.red!
            right_rotate(gp)
          end
        end
        if k == @root
          break
        end
      end
      if (r = @root).is_a? Leaf
        raise "Insertion error"
      end
      r.black!
    end

    def each
      x = min_node?
      while x
        yield x.val
        x = succ? x
      end
    end

    def each_node
      x = min_node?
      while x
        yield x
        x = succ? x
      end
    end

    def enum
      n = 0
      each do |x|
        yield n, x
        n += 1
      end
    end

    def each_node_with_index
      n = 0
      each_node do |x|
        yield n, x
        n += 1
      end
    end

    def find(key : V)
      x = @root
      while x.is_a? Node(V)
        if @eq.call(x.val, key)
          return x.val
        elsif @sm.call(key, x.val)
          x = x.left
        else
          x = x.right
        end
      end
      raise KeyError.new("No such key (#{key})")
    end

    def find?(key : V)
      x = @root
      while x.is_a? Node(V)
        if @eq.call(x.val, key)
          return x.val
        elsif @sm.call(key, x.val)
          x = x.left
        else
          x = x.right
        end
      end
      return nil
    end

    def find!(key : V)
      res = [] of Node(V)
      explore = [@root] of (Node(V) | Leaf)
      while !explore.empty?
        x = explore.pop
        while x.is_a? Node(V)
          if @eq.call(x.val, key)
            res << x
            explore << x.left
            x = x.right
          elsif @sm.call(key, x.val)
            x = x.left
          else
            x = x.right
          end
        end
      end
      return res
    end

    def empty?
      @size == 0
    end

    def empty!
      @size = 0
      @root = Leaf.new
    end

    def max_node?
      if (x = @root).is_a? Leaf
        nil
      else
        while (son = x.right).is_a? Node(V)
          x = son
        end
        x
      end
    end

    def max_node
      if (m = max?).nil?
        raise Enumerable::EmptyError.new("No min in empty tree")
      else
        m
      end
    end

    def max_node!
      if n = max_node?
        find!(n.key)
      else
        [] of Node(V)
      end
    end

    def min_node?
      if (x = @root).is_a? Leaf
        nil
      else
        while (son = x.left).is_a? Node(V)
          x = son
        end
        x
      end
    end

    def min_node
      if (m = min_node?).nil?
        raise Enumerable::EmptyError.new("No min in empty tree")
      else
        m
      end
    end

    def min_node!
      if !(n = min_node?).nil?
        find!(n.key)
      else
        [] of Node(V)
      end
    end

    def to_s(io)
      io << @root
    end

    def succ?(x : Node(V))
      if (son = x.right).is_a? Node(V)
        z = son
        while (son = z.left).is_a? Node(V)
          z = son
        end
        z
      else
        z = x.parent
        while (z = x.parent).is_a? Node(V) && x == z.right
          x = z
        end
        if (z = x.parent).is_a? Leaf
          nil
        else
          z
        end
      end
    end

    def succ(x : Node(V))
      if (n = succ?(x))
        n
      else
        raise "No successor to find"
      end
    end

    def succ!(x : Node(V))
      if (n = succ?(x))
        find!(k.key)
      else
        [] of Node(V)
      end
    end

    def pred?(x : Node(V))
      if (son = x.left).is_a? Node(V)
        z = son
        while (son = z.right).is_a? Node(V)
          z = son
        end
        z
      else
        z = x.parent
        while (z = x.parent).is_a? Node(V) && x == z.left
          x = z
        end
        if (z = x.parent).is_a? Leaf
          nil
        else
          z
        end
      end
    end

    def pred(x : Node(V))
      if (n = succ?(x))
        n
      else
        raise "No successor to find"
      end
    end

    def pred!(x : Node(V))
      if (n = succ?(x))
        find!(k.key)
      else
        [] of Node(V)
      end
    end

    private def aux_collect(l : Leaf, acc)
    end

    private def aux_collect(n : Node(V), acc)
      aux_collect(n.left, acc)
      acc << n.val
      aux_collect(n.right, acc)
    end

    def collect
      acc = [] of V
      aux_collect(@root, acc)
      acc
    end

    private def makediv(buf, div)
      buf << SPACE*4
      div.each do |b|
        if b
          buf << VLINE
        else
          buf << SPACE
        end
        buf << SPACE*2
      end
    end

    private def max(x, y)
      (x > y) ? x : y
    end

    def height(x : Node(V) | Leaf)
      if x.is_a? Leaf
        1
      else
        l = height x.left
        r = height x.right
        max(r, l) + 1
      end
    end

    def depth(x : Node(V) | Leaf)
      if x.is_a? Leaf
        0
      else
        1 + depth x.parent
      end
    end

    private def align(d, h)
      "   " * (h - d)
    end

    private def display_helper(div, curr, buf, depth, height, node : Node(V))
      lt = node.left
      rt = node.right
      children = (!lt.is_a? Leaf || !rt.is_a? Leaf)
      if children
        div << !curr
        display_helper(div, true, buf, depth + 1, height, lt)
        div.pop
      end
      makediv buf, div
      if curr
        buf << ABOVE << HLINE*2 << (children ? NODE : HLINE)
      else
        buf << BELOW << HLINE*2 << (children ? NODE : HLINE)
      end
      buf << (node.black? ? BLKCIRC : REDCIRC)
      buf << align(depth, height) << node.val
      buf << NEWLINE
      if children
        div << curr
        display_helper(div, false, buf, depth + 1, height, rt)
        div.pop
      end
    end

    private def display_helper(div, curr, buf, depth, height, leaf : Leaf)
      makediv buf, div
      if curr
        buf << ABOVE << HLINE*2 << ENDING << BLKCIRC << NEWLINE
      else
        buf << BELOW << HLINE*2 << ENDING << BLKCIRC << NEWLINE
      end
    end

    def display
      h = height @root
      String.build { |str| display str, h }
    end

    def display(io : IO, h)
      io << NEWLINE
      if (x = @root).is_a? Leaf
        io << ROOT << HLINE*3 << ENDING << BLKCIRC << NEWLINE
      else
        div = [] of Bool
        lt = x.left
        rt = x.right
        if lt.is_a? Leaf && rt.is_a? Leaf
          io << ROOT << HLINE*3 << (x.red? ? REDCIRC : BLKCIRC)
          io << align(0, h)
          io << x.val
        else
          display_helper(div, true, io, 1, h, lt)
          io << ROOT << HLINE*3 << NODE << (x.red? ? REDCIRC : BLKCIRC)
          io << align(0, h)
          io << x.val
          io << NEWLINE
          display_helper(div, false, io, 1, h, rt)
        end
      end
      io << NEWLINE
    end
  end
end

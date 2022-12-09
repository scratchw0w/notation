class NotationConvertor
  TRIGONOMETRICAL = %w[cos sin tan cot]
  SIMPLE_OPERATORS = %w[+ / * -]
  TRIGONOMETRICAL_SYMBOLS = TRIGONOMETRICAL.join.chars.uniq

  PRIORITY = {
    1 => %w[+ -],
    2 => %w[* /],
    3 => %w[^],
    4 => TRIGONOMETRICAL
  }

  OperatorNode = Struct.new(:operand1, :operand2, :operator) do
    def concat
      if operator.strip == '^' || operator.strip == '/'
        return '(' + [operator, operand2, operand1].join('') + ')'
      end
      '(' + [operator, operand1, operand2].join('') + ')'
    end
  end

  def initialize
    @operators = []
    @operands = []
    @to_merge = false
    @trigonometric = ""
  end

  def present_in_polish_notation(str)
    initialize
    str.split(//).reject { |x| x == " " }.each { |symbol|
      case
      when symbol == "("
        open_bracket_processing symbol
      when symbol == ")"
        closed_bracket_processing
      when !operator?(symbol)
        digit_processing symbol
      else
        if trigonometric?(symbol)
          @trigonometric << symbol; next
        end
        operand_processing symbol
      end
    }
    results_processing
    @operands.last
  end

  def calculate(str)
    repl = { '(' => '', ')' => '' }.tap { |h| h.default_proc = ->(h, k) { k } }

    stack = []
    str.gsub(/./, repl).split(" ").reverse.each { |symbol|
      if digit?(symbol)
        stack.push(symbol.to_f)
      else
        operand1 = stack.pop.to_f
        if TRIGONOMETRICAL.include? symbol
          stack.push(trigonometrical_processing symbol, operand1); next
        end

        operand2 = stack.pop.to_f
        if symbol == '^'
          stack.push(operand1 ** operand2); next
        end

        if SIMPLE_OPERATORS.include? symbol
          stack.push(operand1.public_send(symbol, operand2)); next
        end

        raise ArgumentError.new('Invalid argument!!!')
      end
    }
    stack.pop
  end

  private

  def operator?(str)
    !digit? str
  end

  def digit?(str)
    str.match?(/\d/)
  end

  def trigonometric?(str)
    TRIGONOMETRICAL_SYMBOLS.include? str
  end

  def open_bracket_processing(symbol)
    @operators << @trigonometric + " " unless @trigonometric.empty?
    @operators << symbol
    @trigonometric = ""
    @to_merge = false
  end

  def closed_bracket_processing
    while @operators.length != 0 && @operators.last != "(" do
      expression_processing
    end
    @operators.pop
    @to_merge = false
  end

  def expression_processing
    node = OperatorNode.new(@operands.pop, @operands.pop, @operators.pop)
    @operands.push(node.concat)
  end

  def digit_processing(symbol)
    @operands << @operands.pop.strip + symbol + " " if @to_merge
    @operands << symbol + " " unless @to_merge
    @to_merge = true
  end

  def get_priority(str)
    if str == "-" || str == "+"
      return 1
    end
    if str == "*" || str == "/"
      return 2
    end
    if str == "^"
      return 3
    end
    if TRIGONOMETRICAL.include? str
      return 4
    end
    0
  end

  def operand_processing(symbol)
    while @operators.length != 0 && get_priority(symbol.to_s) <= get_priority(@operators.last&.strip) do
      expression_processing
    end
    @operators.push(symbol + " ")
    @to_merge = false
  end

  def results_processing
    while @operators.length != 0 do
      node = OperatorNode.new(@operands.pop, @operands.pop, @operators.pop)
      @operands.push(node.concat)
    end
  end

  def trigonometrical_processing(symbol, operand1)
    if symbol == 'cot'
      1 / Math.tan(operand1)
    else
      Math.public_send(symbol, operand1)
    end
  end

end

convertor = NotationConvertor.new

examples = ['7+2', '5*(9+3)', 'cos(10+1)', '19^2', '10 / 2^3']

examples.each do |ex|
  converted = convertor.present_in_polish_notation ex
  puts ex + " --> " + converted + " = " + "#{convertor.calculate converted}\n\n"
end
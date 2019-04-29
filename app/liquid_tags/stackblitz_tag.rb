class StackblitzTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @view = parse_view(id)
    @file = parse_file(id)
    @height = 500
  end

  def render(_context)
    html = <<-HTML
      <iframe
        src="https://stackblitz.com/edit/#{@id}?embed=1#{@view}#{@file}"
        width="100%"
        height="#{@height}"
        scrolling="no"
        frameborder="no"
        allowfullscreen
        allowtransparency="true">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end

  def parse_id(input)
    input_no_space = input.split(" ").first
    raise StandardError, "Invalid Stackblitz Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def parse_view(input)
    input_split = input.split(" ")

    # Validation
    validated_views = input_split.map { |o| valid_view?(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless validated_views.length.between?(0, 1)

    validated_views.length.zero? ? "" : "&#{validated_views.join("")}"
  end

  def valid_view?(option)
    option.match(/^view=(preview|editor|both)\z/)
  end

  def parse_file(input)
    input_split = input.split(" ")

    # Validation
    validated_files = input_split.map { |o| valid_file?(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless validated_files.length.between?(0, 1)

    validated_files.length.zero? ? "" : "&#{validated_files.join("")}"
  end

  def valid_file?(option)
    option.match(/^file=(.*)\z/)
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)

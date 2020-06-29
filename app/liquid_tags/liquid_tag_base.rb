class LiquidTagBase < Liquid::Tag
  def self.script
    ""
  end

  def initialize(_tag_name, _content, _parse_context)
    super
    validate_contexts
    Pundit.authorize(
      parse_context.partial_options[:user],
      self,
      :initialize?,
      policy_class: LiquidTagPolicy,
    )
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, "").
      gsub(/\n/m, " ").
      gsub(/>\n{1,}</m, "><").
      strip.
      html_safe
  end

  private

  def validate_contexts
    return unless self.class.const_defined? "VALID_CONTEXTS"

    source = parse_context.partial_options[:source]
    raise LiquidTags::Errors::InvalidParseContext, "No source found" unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class.name
    valid_contexts = self.class::VALID_CONTEXTS.map(&:pluralize)
    invalid_source_error_msg = "Invalid context. This liquid tag can only be used in #{valid_contexts}."
    raise LiquidTags::Errors::InvalidParseContext, invalid_source_error_msg unless is_valid_source
  end
end

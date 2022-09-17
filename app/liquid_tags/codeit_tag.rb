class CodeitTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @url = parse_url(url)
  end

  def render(_context)
    '<iframe src="' + @url + '"
      scrolling="no" frameborder="no" allowtransparency="true" loading="lazy" style="width: 100%;" height="600"
    </iframe>'
  end

  private

  def parse_url(url)
    unless ?(url.match(/^https:\/\/cde.run\//) || url.match(/^https:\/\/dev.cde.run\//))
      url = 'https://cde.run/' + url
    url
    end
  end

  end
end

Liquid::Template.register_tag("codeit", CodeitTag)

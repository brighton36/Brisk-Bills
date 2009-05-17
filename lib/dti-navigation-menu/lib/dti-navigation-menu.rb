class NavigationMenu
  attr_accessor :title, :href, :items, :markup_classes
  
  def initialize(title, i_href = nil, markup_classes = nil, &block)
    @title, @href, @markup_classes = title, i_href, markup_classes
    @items = []
    block.call(self) if block
  end

  def item(title, i_href = nil, markup_classes = nil, &block)
    menu_item = NavigationMenu.new title, i_href, markup_classes
    block.call menu_item if block
    @items << menu_item
  end
  
  def each(&block)
    @items.each(&block)
  end

  def descendents?
    (@items.length > 0) ? true : false
  end
  
  def link_id
    @title.downcase.gsub(/[^a-z0-9 ]/i,'').tr(' ','_').gsub(/[\_]{2,}/,'_')
  end
end

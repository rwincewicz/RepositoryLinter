class Publisher
  attr_reader :publisher

  def initialize(publisher)
    @publisher = publisher
  end

  def to_hash
    {
      id: publisher["id"],
      name: publisher.search('name').map { |name| name.text }.first,
      url: publisher.search('homeurl').map { |homeurl| homeurl.text }.first
    }
  end
end



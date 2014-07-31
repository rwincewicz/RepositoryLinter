class Publication
  attr_reader :publication

  def initialize(publication)
    @publication = publication
  end

  def to_hash
    {
      title: publication.search("jtitle").map { |t| t.text }.first,
      issn: publication.search("issn").map { |t| t.text }.first
    }
  end
end



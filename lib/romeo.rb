require "nokogiri"
require "net/http"
require "rack/utils"
require_relative "publisher"
require_relative "publication"

class Romeo
  API_KEY = ENV.fetch("ROMEO_API_KEY")

  attr_reader :uri

  def initialize
    @uri = URI("http://www.sherpa.ac.uk/romeo/api29.php")
  end

  def request(uri)
    response = Net::HTTP.get_response(uri)

    publishers = Nokogiri::XML(response.body).search("//publisher").map { |p| Publisher.new(p).to_hash }
    publications = Nokogiri::XML(response.body).search("//journal").map { |j| Publication.new(j).to_hash }

    {
      publishers: publishers,
      publications: publications
    }
  end

  def issn(issn)
    uri.query = Rack::Utils.build_query(ak: API_KEY, issn: issn)

    request(uri)
  end

  def title(title)
    uri.query = Rack::Utils.build_query(ak: API_KEY, jtitle: title)

    request(uri)
  end

  def publisher(publisher)
    uri.query = Rack::Utils.build_query(ak: API_KEY, pub: publisher)

    request(uri)
  end
end


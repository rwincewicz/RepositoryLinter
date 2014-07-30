require "sinatra"
require "yajl"
require "net/http"
require "rack/utils"
require "nokogiri"
require "cgi"

post "/validate" do
  parser = Yajl::Parser.new
  encoder = Yajl::Encoder.new
  metadata = parser.parse(request.body)

  response = {}

  unless metadata.has_key?("publisher")
    response[:errors] ||= []
    response[:errors] << "Publisher field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new

  if metadata.has_key?("issn")
    response[:publisher_by_issn] = romeo.issn(metadata.fetch("issn")).search("//publisher").map { |publisher| Publisher.new(publisher).to_hash }
  end

  if metadata.has_key?("publisher")
    response[:publisher_by_publisher] = romeo.publisher(metadata.fetch("publisher")).search("//publisher").map { |publisher| Publisher.new(publisher).to_hash }
  end

  if metadata.has_key?("publication")
    response[:publisher_by_publication] = romeo.title(metadata.fetch("publication")).search("//publisher").map { |publisher| Publisher.new(publisher).to_hash }
  end

  if metadata.has_key?("id_number") && metadata.fetch("id_number") =~ /\A10\.\d{4,5}/
    response[:metadata_by_doi] = crossref.doi(metadata.fetch("id_number"))
  end

  encoder.encode(response)
end

class Crossref
  def doi(doi)
    uri = URI("http://data.crossref.org/#{CGI.escape(doi)}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    Yajl::Parser.parse(response.body)
  end
end

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

class Romeo
  API_KEY = ENV.fetch("ROMEO_API_KEY")

  attr_reader :uri

  def initialize
    @uri = URI("http://www.sherpa.ac.uk/romeo/api29.php")
  end

  def issn(issn)
    uri.query = Rack::Utils.build_query(ak: API_KEY, issn: issn)

    response = Net::HTTP.get_response(uri)

    Nokogiri::XML(response.body)
  end

  def title(title)
    uri.query = Rack::Utils.build_query(ak: API_KEY, jtitle: title)

    response = Net::HTTP.get_response(uri)

    Nokogiri::XML(response.body)
  end

  def publisher(publisher)
    url.query = Rack::Utils.build_query(ak: API_KEY, pub: publisher)

    response = Net::HTTP.get_response(uri)

    Nokogiri::XML(response.body)
  end
end

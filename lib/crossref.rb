require "net/http"
require "uri"
require "yajl"

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



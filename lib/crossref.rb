require "net/http"
require "uri"
require "multi_json"

class Crossref
  def doi(doi)
    uri = URI("http://data.crossref.org/#{CGI.escape(doi)}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    MultiJson.load(response.body)
  end
end



require "nokogiri"
require "net/http"
require "rack/utils"

class GTR
  attr_reader :uri

  def initialize()
    @uri = URI("http://gtr.rcuk.ac.uk/search/person");
  end

  def search(name)
    uri.query = Rack::Utils.build_query(term: name)
    doc = request(uri)
    doc.xpath("//gtr:person/gtr:id/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api")
  end

  def projects(names)
    response = []
    overview = {}
    name_array = []
    names.each do |name|
      id = search(name["name"]["family"])
      project_uri = URI("http://gtr.rcuk.ac.uk/person/#{id}")
      doc = request(project_uri)
      result_names = doc.xpath("/gtr:personOverview/gtr:person", 'gtr' => "http://gtr.rcuk.ac.uk/api")
      overview = []
      result_names.each do |result_name|
        if !result_name.xpath("gtr:firstName/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api").nil?
          overview << { organisation: doc.xpath("//gtr:organisation/gtr:name/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api"),
            author: { firstName: result_name.xpath("gtr:firstName/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api"),
                  otherNames: result_name.xpath("gtr:otherNames/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api"),
                  lastName: result_name.xpath("gtr:surname/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api")
          }
        }
        end
      end
      results = doc.xpath("//gtr:results//gtr:project", 'gtr' => "http://gtr.rcuk.ac.uk/api")
      project_array = Array.new
      results.each do |result|
        puts result
        if !result.xpath("//gtr:project/gtr:title/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api").nil? 
          project_hash = {
            title: result.xpath("gtr:title/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api"),
            funder: result.xpath("gtr:fund/gtr:funder/gtr:name/text()", 'gtr' => "http://gtr.rcuk.ac.uk/api")
          }
          project_array << project_hash
        end
      end
      response << { projects: project_array, person: overview }
    end
    {
      funding: response
    }
  end

  def request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/xml"
    response = http.request(request)
    Nokogiri::XML(response.body)
  end

end

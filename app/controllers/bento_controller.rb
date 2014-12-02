require "json"
require "blacklight/catalog"

class BentoController < ApplicationController
  include Blacklight::Catalog
  include ArticlesHelper
  include ERB::Util

  def index
    @complete_count = 0

    if params["q"] then
      eds = get_eds_results
      @eds_count = eds["count"]
      eds.delete("count")
      @eds = eds
    else
      @eds_count = 0
      @eds = "Empty Search"
    end

    databases = populate(CatalogController, {format: 'Database'})
    @database_count = databases["count"]
    databases.delete("count")
    @databases = databases

    ejournals = populate(CatalogController, {source: 'SFX'})
    @ejournals_count = ejournals["count"]
    ejournals.delete("count")
    @ejournals = ejournals

    symphony = populate(CatalogController, {source: 'Symphony'})
    @symphony_count = symphony["count"]
    symphony.delete("count")
    @symphony = symphony

    
  end

  private

  def populate(controller, facet)
    @query = params[:q]
    documents = {}
    (@solr_response, @document_list) = controller.new.get_search_results(:q => @query, :f => facet)
    documents["count"] = @solr_response["response"]["numFound"]
    @complete_count += documents["count"]
    @document_list.each do |doc|
      metadata = populate_metadata(doc)
      documents[doc.as_json["id"]] = metadata
    end
    documents
  end

  def populate_metadata(doc)
      metadata = {}
      metadata[:title] = doc.as_json["title_display"]
      metadata[:subtitle] = doc.as_json["subtitle_display"]
      metadata[:author] = doc.as_json["author_display"]
      metadata[:isbn] = doc.as_json["isbn_t"]
      metadata[:issn] = doc.as_json["issn_t"]
      metadata[:year] = doc.as_json["pub_date"]
      metadata[:call_number] = doc.as_json["lc_callnum_display"] # this isn't the correct field. Just a place holder for now
      #Symphony: location(s), call number(s), checked out or in: these depend on item
      #record, not bib record.
      #Ejournals: coverage statement
      #Articles: full text?, Link to PDF, Year of publication - not sure
      #these are possible. Depends on EDS API
      metadata
  end

  def get_eds_results
    documents = {}
    session[:current_url] = request.original_url
    eds_connect
    if has_search_parameters? then
      clean_params = deep_clean(params)
      params = clean_params
      options = generate_api_query(params)
    end

    search(options)

    documents["count"] = session[:results]['SearchResult']['Statistics']['TotalHits']
    @complete_count += documents["count"]
    results = session[:results]['SearchResult']['Data']['Records']
    results.each do |result|
      puts result["ResultId"]
      metadata = {}
      if has_restricted_access?(result) then
        metadata[:title] = "This result cannot be shown to guests."
      else
        metadata[:title] = show_title(result)
      end
      metadata[:author] = show_authors(result) if has_authors?(result)
      metadata[:url] = result["PLink"]
      metadata[:format] = show_pubtype(result) if has_pubtype?(result)
      documents[result["ResultId"]] = metadata
    end
    #session[:results]
    documents
  end
end

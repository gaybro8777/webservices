class Api::V2::ItaTaxonomyController < Api::V2Controller
  include Searchable
  search_by :q, :query_expansion
end

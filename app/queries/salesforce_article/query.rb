module SalesforceArticle
  class Query < ::Query
    attr_accessor :countries

    aggregate_terms_by countries:     { field: 'countries' },
                       sources:       { field: 'source' },
                       trade_regions: { field: 'trade_regions' },
                       world_regions: { field: 'world_regions' }

    def initialize(options = {})
      super
      @q    = options[:q]
      @sources = split_to_array(options[:sources].upcase) rescue []
      @industries = split_to_array(options[:industries]) rescue nil
      @topics = split_to_array(options[:topics]) rescue nil

      @first_published_date = options[:first_published_date] rescue nil
      @last_published_date = options[:last_published_date] rescue nil

      set_geo_instance_variables(options)
    end

    MULTI_FIELDS = %i(atom business_unit chapter references section summary title)

    private

    def generate_query(json)
      multi_fields = %i(title)
      json.query do
        json.filtered do
          generate_filtered(json)
          json.query do
            json.bool do
              json.must do
                json.child! { generate_multi_match(json, MULTI_FIELDS, @q) }  if @q
              end
            end
          end if @q
        end
      end
    end

    def generate_filtered(json)
      json.filter do
        json.bool do
          json.must do
            build_filters(json)
          end
        end
      end if any_filter_field_exists?
    end

    def any_filter_field_exists?
      @countries || @sources.any? || @industries || @trade_regions || @world_regions || @topics || @first_published_date || @last_published_date
    end

    def generate_filter(_json)
    end

    def build_filters(json)
      json.child! { json.terms { json.source @sources } } if @sources.any?
      json.child! { json.terms { json.industries @industries } } if @industries
      json.child! { json.terms { json.topics @topics } } if @topics

      generate_geo_filters(json, 'countries')

      generate_date_range(json, 'first_published_date', @first_published_date) if @first_published_date
      generate_date_range(json, 'last_published_date', @last_published_date) if @last_published_date
    end
  end
end

require 'open-uri'

class ItaOfficeLocationData
  include Importable
  include VersionableResource
  COMMON_URL_FRAGMENT = 'http://emenuapps.ita.doc.gov/ePublic/GetPost?type='
  OFFICE_TYPES = %w(odo oio)
  DEFAULT_RESOURCES = OFFICE_TYPES.map { |office_type| [COMMON_URL_FRAGMENT, office_type].join }
  INVALID_CITIES = ['European Union']

  SINGLE_VALUED_XPATHS = {
    post:              './POST',
    office_name:       './OFFICENAME',
    country:           './COUNTRYID',
    state:             './STATE',
    email:             './EMAIL',
    fax:               './FAX',
    mail_instructions: './MAIL_INSTR',
    phone:             './PHONE',
    post_type:         './POSTTYPE',
  }.freeze

  MULTI_VALUED_XPATHS = {
    address: './ADDRESS',
  }

  def initialize(resource = DEFAULT_RESOURCES)
    resource  = [resource] unless resource.is_a? Array
    @resource = resource
  end

  def import
    @resource.each do |resource|
      doc = Nokogiri::XML(open(resource))
      ita_office_locations = doc.xpath('//POSTINFO')
                             .map { |location_info| process_location_info(location_info) }
                             .sort { |a, b| [a[:country].to_s, a[:state].to_s, a[:id].to_s] <=> [b[:country].to_s, b[:state].to_s, b[:id].to_s] }
      ItaOfficeLocation.index ita_office_locations.compact
    end
  end

  private

  def process_location_info(location_info)
    event_hash = extract_fields(location_info, SINGLE_VALUED_XPATHS)
    event_hash.reverse_merge! extract_multi_valued_fields(location_info, MULTI_VALUED_XPATHS)
    event_hash[:country] = lookup_country_by_id(event_hash[:country])
    assign_city(event_hash)
    event_hash[:state] = event_hash[:state].present? ? lookup_state(event_hash[:state]) : nil
    event_hash[:id] = [event_hash[:country], normalize_post(event_hash[:post])].join(':')
    event_hash
  end

  def lookup_country_by_id(country_id)
    IsoCountryCodes.find(country_id).alpha2
  rescue IsoCountryCodes::UnknownCodeError => e
    Rails.logger.error e
    nil
  end

  def assign_city(event_hash)
    if event_hash[:country] == 'US'
      event_hash[:city] = parse_city_from_address(event_hash)
    else
      event_hash[:city] = INVALID_CITIES.include?(event_hash[:post]) ? nil : event_hash[:post]
    end
  end

  def normalize_post(post_str)
    post_str.gsub(/\W/, '')
  end
end

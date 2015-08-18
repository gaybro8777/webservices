require 'spec_helper'

describe 'FTA Nicaragua Tariff Rates API V1', type: :request do
  include_context 'TariffRate::Nicaragua data'

  describe 'GET /tariff_rates/search?sources=NI' do
    let(:params) { { sources: 'ni' } }
    before { get '/tariff_rates/search', params }

    context 'when search parameters are empty' do
      subject { response }
      it_behaves_like 'it contains all TariffRate::Nicaragua results'
      it_behaves_like 'a successful search request'
    end

    context 'when q is specified' do
      let(:params) { { sources: 'ni', q: 'horses' } }

      subject { response }
      it_behaves_like 'a successful search request'
      it_behaves_like "an empty result when a query doesn't match any documents", sources: 'ni'
      it_behaves_like 'it contains all TariffRate::Nicaragua results that match "horses"'
    end
  end
end

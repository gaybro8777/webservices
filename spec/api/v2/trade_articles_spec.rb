require 'spec_helper'

describe 'Trade Articles API V2', type: :request do
  before(:all) do
    TradeArticle.recreate_index
    fixtures_file = "#{Rails.root}/spec/fixtures/trade_articles/trade_articles.json"
    TradeArticleData.new(fixtures_file).import
  end

  let(:v2_headers) { { 'Accept' => 'application/vnd.tradegov.webservices.v2' } }
  let(:expected_results) { JSON.parse open("#{Rails.root}/spec/fixtures/trade_articles/results.json").read }

  describe 'GET /trade_articles/search.json' do

    context 'when all params are specified' do
      let(:params) do
        { q:                 'multilateral development team',
          evergreen:         'false',
          pub_date_start:    '2013-05-14',
          pub_date_end:      '2013-05-15',
          update_date_start: '2013-06-12',
          update_date_end:   '2013-06-12' }
      end
      before { get '/trade_articles/search', params, v2_headers }
      subject { response }

      it_behaves_like 'a successful search request'

      it 'returns matching trade articles' do
        json_response = JSON.parse(response.body)
        expect(json_response['total']).to eq(1)

        results = json_response['results']
        expect(results[0]).to eq(expected_results[0])
      end
    end

    context 'when q params is specified' do
      before { get '/trade_articles/search', params, v2_headers }
      it_behaves_like "an empty result when a query doesn't match any documents"
    end
  end
end
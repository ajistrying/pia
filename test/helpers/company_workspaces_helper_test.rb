require "test_helper"

class CompanyWorkspacesHelperTest < ActionView::TestCase
  include CompanyWorkspacesHelper

  setup do
    @workspace = CompanyWorkspace.create!(
      company_symbol: "AAPL", 
      company_name: "Apple Inc."
    )
  end

  test "calculate_analyst_consensus returns nil when no ratings exist" do
    assert_nil calculate_analyst_consensus(@workspace)
  end

  test "calculate_analyst_consensus returns proper consensus data" do
    # Create test analyst ratings
    AnalystRating.create!(
      company_workspace: @workspace,
      rating: "Strong Buy",
      price_target: 200.0,
      rating_agency: "Goldman Sachs"
    )
    
    AnalystRating.create!(
      company_workspace: @workspace,
      rating: "Hold",
      price_target: 180.0,
      rating_agency: "Morgan Stanley"
    )

    consensus_data = calculate_analyst_consensus(@workspace)

    assert_not_nil consensus_data
    assert_equal 2, consensus_data[:total_ratings]
    assert_equal 1, consensus_data[:buy_ratings]
    assert_equal 1, consensus_data[:hold_ratings]
    assert_equal 0, consensus_data[:sell_ratings]
    assert_equal "Moderate Buy", consensus_data[:consensus_rating]
    assert_equal 190.0, consensus_data[:avg_price_target]
  end

  test "consensus_rating_color returns correct colors" do
    assert_equal 'text-green-600', consensus_rating_color('Strong Buy')
    assert_equal 'text-green-600', consensus_rating_color('Moderate Buy')
    assert_equal 'text-yellow-600', consensus_rating_color('Hold')
    assert_equal 'text-red-600', consensus_rating_color('Moderate Sell')
    assert_equal 'text-red-600', consensus_rating_color('Strong Sell')
    assert_equal 'text-gray-600', consensus_rating_color('Unknown')
  end

  test "format_financial_number formats numbers correctly" do
    assert_equal '$391.0B', format_financial_number(391_035_000_000)
    assert_equal '$391.0M', format_financial_number(391_035_000, unit: 'M')
    assert_equal '$6.11', format_financial_number(6.11, unit: 'currency')
    assert_equal 'N/A', format_financial_number(nil)
  end
end 
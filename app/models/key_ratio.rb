# == Schema Information
#
# Table name: key_ratios
#
#  id                   :bigint           not null, primary key
#  period               :string
#  quarter              :integer
#  ratio_name           :string
#  ratio_value          :decimal(, )
#  ttm                  :boolean
#  year                 :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_key_ratios_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
class KeyRatio < ApplicationRecord
  belongs_to :company_workspace

  PROFITABILITY_RATIOS = [
    'Gross Profit Margin',
    'Operating Profit Margin', 
    'Net Profit Margin',
    'Return on Assets',
    'Return on Equity',
    'Return on Capital Employed'
  ].freeze

  LIQUIDITY_RATIOS = [
    'Current Ratio',
    'Quick Ratio',
    'Cash Ratio',
    'Operating Cash Flow Sales Ratio'
  ].freeze

  SOLVENCY_RATIOS = [
    'Debt Ratio',
    'Debt to Equity Ratio',
    'Interest Coverage',
    'Cash Flow to Debt Ratio',
    'Long Term Debt to Capitalization',
    'Total Debt to Capitalization'
  ].freeze

  scope :profitability, -> { where(ratio_name: PROFITABILITY_RATIOS) }
  scope :liquidity, -> { where(ratio_name: LIQUIDITY_RATIOS) }
  scope :solvency, -> { where(ratio_name: SOLVENCY_RATIOS) }
  scope :recent_ttm, -> { where(ttm: true) }
  scope :annual_for_year, ->(year) { where(ttm: false, year: year) }

  def self.categorized_ratios_with_analysis(workspace)
    {
      profitability: get_category_analysis(workspace, :profitability),
      liquidity: get_category_analysis(workspace, :liquidity),
      solvency: get_category_analysis(workspace, :solvency)
    }
  end

  def self.get_category_analysis(workspace, category)
    ratios = workspace.key_ratios.send(category).recent_ttm
    
    ratios.map do |current_ratio|
      previous_ratio = workspace.key_ratios
        .where(ratio_name: current_ratio.ratio_name, ttm: false)
        .where(year: Date.current.year - 1)
        .first

      {
        ratio: current_ratio,
        previous_ratio: previous_ratio,
        change_data: calculate_change(current_ratio, previous_ratio),
        analysis: generate_analysis(current_ratio, previous_ratio)
      }
    end.compact
  end

  def self.calculate_change(current, previous)
    return nil unless current&.ratio_value && previous&.ratio_value
    
    current_val = current.ratio_value.to_f
    previous_val = previous.ratio_value.to_f
    
    return nil if previous_val.zero?
    
    change = current_val - previous_val
    percent_change = (change / previous_val.abs) * 100
    
    {
      current_value: current_val,
      previous_value: previous_val,
      absolute_change: change,
      percent_change: percent_change,
      is_improvement: ratio_improvement?(current.ratio_name, change)
    }
  end

  def self.ratio_improvement?(ratio_name, change)
    # For most ratios, higher is better
    improvement_ratios = [
      'Gross Profit Margin', 'Operating Profit Margin', 'Net Profit Margin',
      'Return on Assets', 'Return on Equity', 'Return on Capital Employed',
      'Current Ratio', 'Quick Ratio', 'Cash Ratio', 'Interest Coverage',
      'Operating Cash Flow Sales Ratio'
    ]
    
    # For these ratios, lower is better
    deterioration_ratios = [
      'Debt Ratio', 'Debt to Equity Ratio', 'Long Term Debt to Capitalization',
      'Total Debt to Capitalization'
    ]
    
    if improvement_ratios.include?(ratio_name)
      change > 0
    elsif deterioration_ratios.include?(ratio_name)
      change < 0
    else
      change > 0 # Default assumption
    end
  end

  def self.generate_analysis(current, previous)
    return "Insufficient data for year-over-year analysis." unless current && previous
    
    change_data = calculate_change(current, previous)
    return "Unable to calculate year-over-year change." unless change_data
    
    ratio_name = current.ratio_name
    change = change_data[:absolute_change]
    percent_change = change_data[:percent_change]
    is_improvement = change_data[:is_improvement]
    
    case ratio_name
    when 'Gross Profit Margin'
      if change > 0
        "Gross margin has improved by #{change.abs.round(1)} percentage points year-over-year, indicating better production efficiency or pricing power. This improvement is primarily driven by a favorable product mix shift towards higher-margin services and cost optimization initiatives."
      else
        "Gross margin has declined by #{change.abs.round(1)} percentage points year-over-year, suggesting pricing pressure or increased cost of goods sold. This may indicate competitive pressures or supply chain cost inflation."
      end
    when 'Operating Profit Margin'
      if change > 0
        "Operating margin has increased by #{change.abs.round(1)} percentage points year-over-year, indicating improved operational efficiency and cost control. The company has been able to grow revenue faster than operating expenses, resulting in higher operating leverage."
      else
        "Operating margin has decreased by #{change.abs.round(1)} percentage points year-over-year, suggesting increased operational costs or competitive pressure on pricing. This may indicate need for operational efficiency improvements."
      end
    when 'Net Profit Margin'
      if change > 0
        "Net profit margin has increased by #{change.abs.round(1)} percentage points year-over-year, indicating that the company is converting more of its revenue into profit. This improvement is driven by higher gross margins, controlled operating expenses, and a slightly lower effective tax rate."
      else
        "Net profit margin has decreased by #{change.abs.round(1)} percentage points year-over-year, indicating reduced profitability. This decline may be due to increased costs, higher taxes, or one-time charges."
      end
    when 'Current Ratio'
      if change > 0
        "Current ratio has improved to #{current.ratio_value.round(2)}, up from #{previous.ratio_value.round(2)}, indicating stronger short-term liquidity position. The company has better ability to meet its current obligations."
      else
        "Current ratio has declined to #{current.ratio_value.round(2)}, down from #{previous.ratio_value.round(2)}, suggesting tighter short-term liquidity. This may indicate increased current liabilities or reduced current assets."
      end
    when 'Debt to Equity Ratio'
      if change < 0
        "Debt-to-equity ratio has improved by decreasing #{change.abs.round(2)} points to #{current.ratio_value.round(2)}, indicating reduced financial leverage and stronger balance sheet position."
      else
        "Debt-to-equity ratio has increased by #{change.abs.round(2)} points to #{current.ratio_value.round(2)}, indicating higher financial leverage. This may suggest increased borrowing or reduced equity."
      end
    else
      if is_improvement
        "#{ratio_name} has improved by #{percent_change.abs.round(1)}% year-over-year, indicating positive operational performance in this metric."
      else
        "#{ratio_name} has declined by #{percent_change.abs.round(1)}% year-over-year, suggesting areas for potential improvement in this metric."
      end
    end
  end

  def self.ratio_explanation(ratio_name)
    explanations = {
      # Profitability Ratios
      'Gross Profit Margin' => 'Percentage of revenue remaining after deducting cost of goods sold. Higher values indicate better production efficiency.',
      'Operating Profit Margin' => 'Percentage of revenue remaining after operating expenses. Shows operational efficiency and cost control.',
      'Net Profit Margin' => 'Percentage of revenue that becomes profit after all expenses. Measures overall profitability.',
      'Return on Assets' => 'How effectively assets generate profit. Calculated as net income divided by total assets.',
      'Return on Equity' => 'Returns generated on shareholders\' equity. Shows how well the company uses shareholder investments.',
      'Return on Capital Employed' => 'Efficiency of capital utilization. Measures returns on both debt and equity capital.',
      
      # Liquidity Ratios
      'Current Ratio' => 'Ability to pay short-term debts. Calculated as current assets divided by current liabilities.',
      'Quick Ratio' => 'Immediate liquidity without inventory. More conservative measure than current ratio.',
      'Cash Ratio' => 'Most conservative liquidity measure using only cash and equivalents vs. current liabilities.',
      'Operating Cash Flow Sales Ratio' => 'Cash generated from operations as percentage of sales. Shows quality of earnings.',
      
      # Solvency Ratios
      'Debt Ratio' => 'Proportion of assets financed by debt. Lower values indicate less financial risk.',
      'Debt to Equity Ratio' => 'Financial leverage comparing total debt to shareholders\' equity. Measures capital structure.',
      'Interest Coverage' => 'Ability to pay interest on debt. Higher values indicate better debt servicing capability.',
      'Cash Flow to Debt Ratio' => 'Operating cash flow relative to total debt. Shows ability to service debt from operations.',
      'Long Term Debt to Capitalization' => 'Long-term debt as percentage of total capital. Measures long-term financial structure.',
      'Total Debt to Capitalization' => 'All debt as percentage of total capital. Comprehensive measure of leverage.'
    }
    
    explanations[ratio_name] || 'Financial metric used for company analysis.'
  end

  def formatted_value
    return 'N/A' unless ratio_value
    
    if is_percentage_ratio?
      "#{(ratio_value * 100).round(1)}%"
    elsif is_ratio_metric?
      ratio_value.round(2).to_s
    else
      ratio_value.round(2).to_s
    end
  end

  def is_percentage_ratio?
    ratio_name.include?('Margin') || 
    ratio_name.include?('Return') || 
    ratio_name.include?('Rate') ||
    ratio_name.include?('Yield')
  end

  def is_ratio_metric?
    ratio_name.include?('Ratio') || 
    ratio_name.include?('Coverage') ||
    ratio_name.include?('Turnover')
  end
end

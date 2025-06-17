class NewsPiecesController < ApplicationController
  before_action :set_company_workspace
  before_action :set_news_piece

  def summary
    if @news_piece.summary.present?
      render partial: 'news_pieces/summary', locals: { news_piece: @news_piece }
    else
      render partial: 'news_pieces/no_summary'
    end
  end

  def destroy
    @news_piece.destroy
    redirect_back(fallback_location: @company_workspace)
  end

  private

  def set_company_workspace
    @company_workspace = CompanyWorkspace.find(params[:company_workspace_id])
  end

  def set_news_piece
    @news_piece = @company_workspace.news_pieces.find(params[:id])
  end
end 
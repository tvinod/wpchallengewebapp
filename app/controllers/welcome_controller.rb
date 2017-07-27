require 'wp_graph_search'

class WelcomeController < ApplicationController
  include WpGraphSearch
  skip_before_action :verify_authenticity_token
  def index
#  	render plain: params[:welcome].inspect
  end

  def create
  	render plain: params[:welcome].inspect
  end

  def welcome
  	render plain: params[:welcome].inspect
  end

  def query
    @result = get_connection_path(params[:p1name], params[:p1city], params[:p1statecode],
                                  params[:p2name], params[:p2city], params[:p2statecode])
    render "welcome/index"
  end

  def get
  	render plain: params[:welcome].inspect
  end

end

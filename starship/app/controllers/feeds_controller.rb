class FeedsController < ApplicationController
  skip_before_filter :authenticate, :only => ["show", "index", "person"]

  
  # person feed for one user which is a merger of all his feed subscriptions 
  def person
    user = Person.find_by_stringid params[:person]
    if user.nil?
      render :template => 'error.html.erb', :status => 404
      return
    end
    
    @items = user.starship_messages.paginate( :page => params[:page], :per_page => 100,
                                        :order => "id DESC" ) 
    @title = "All feed messages for user " + params[:person]
    render_feed()
  end


  # displaying list of public feeds here, does not need authentication
  def index
    
    
  end
  
  # list the configured feeds of a single user
  def personal
    @feed_subscriptions = session[:user].subscriptions.find( 
      :all, :conditions => [ "deliveries.name = 'RSS'"], 
      :include => [:msg_type, :delay, :delivery])
    @username = session[:user].stringid
  end


  # shows a feed either as RSS or web list. 
  # params[:id] is a comma seperated id list
  def show
    @subscriptions = Subscription.find(:all, :conditions => ["id IN (?)", params[:id]])
    if (@subscriptions.empty?)
      flash[:error] = "Feed with id: #{params[:id]} not found"
      redirect_to :action => :index
      return
      
     # TODO: remove those ids from the id list that are private if the requester != owner
     #elsif (@subscription.private && @subscription.person != session[:user])
      #flash[:error] = "Feed with id: #{params[:id]} is marked as private by it's owner"
      #redirect_to :action => :index
    end
    
    @items = StarshipMessage.paginate( :page => params[:page], :per_page => 100,
                                    :order => "id DESC", 
                                    :conditions => ["subscription_id IN (?)", params[:id]])     
    @title = @subscriptions.first.subscription_desc
     render_feed()
  end


  private

  def render_feed
     respond_to do |format|
       format.html  { render :template => 'feeds/show' }
       format.rdf  { render :template => 'feeds/show', :layout => false }
       #format.atom  { render :layout => false }
    end
  end

end
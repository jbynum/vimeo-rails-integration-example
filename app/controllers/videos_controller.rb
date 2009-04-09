class VideosController < ApplicationController
  # GET /videos
  # GET /videos.xml

  def index
    link = Vimeo::Advanced::Base.new(API_KEY,SECRET_KEY)
    @link = link.login_link("delete")
  end
  
  def auth
    auth = Vimeo::Advanced::Auth.new(API_KEY, SECRET_KEY)
    frob = params[:frob]
    @token = auth.get_token(frob)
    saveToken = Vtoken.new()
    saveToken.update_attributes( :token => @token["rsp"]["auth"]["token"],
                                 :perms => @token["rsp"]["auth"]["perms"],
                                 :nsid => @token["rsp"]["auth"]["user"]["nsid"],
                                 :fullname => @token["rsp"]["auth"]["user"]["fullname"],
                                 :username => @token["rsp"]["auth"]["user"]["username"],
                                 :user_id => @token["rsp"]["auth"]["user"]["id"]
                                  )
    if saveToken.save
      flash[:notice] = "Token saved"
      #@token = Vtoken.first
    else
      flash[:notice] = "Token not saved"
    end
  end

  # GET /videos/1
  # GET /videos/1.xml
  def show
    token = Vtoken.first
    video_id = Video.find(params[:id]).video_id
    
    oembed = "http://vimeo.com/api/oembed.json?url=http%3A//vimeo.com/" + video_id
    puts (Curl::Easy.perform(oembed).body_str)["html"]
    @video = JSON.parse(Curl::Easy.perform(oembed).body_str)["html"]
    
    respond_to do |format|
      format.html #show.html.erb
      format.xml { render :xml => @vids }
    end
  end

  # GET /videos/new
  # GET /videos/new.xml
  def new
    @video = Video.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video }
    end
  end

  # GET /videos/1/edit
  def edit
    @video = Video.find(params[:id])
  end

  # POST /videos
  # POST /videos.xml
  def create
    #get the app's token
    auth_token = Vtoken.first.token
    
    #intitalize a new Vimeo Advanced API object
    vimeo_video = Vimeo::Advanced::Upload.new(API_KEY,SECRET_KEY)
    
    #Get an upload ticket
    ticket = vimeo_video.get_upload_ticket(auth_token)["rsp"]["ticket"]["id"]
    
    #Generate the API SIG b/c the lib doesn't do it yet
    api_sig = Digest::MD5.hexdigest(SECRET_KEY + "api_key" + API_KEY + "ticket_id" + ticket)
    
    #Create post to send file to Vimeo w/Curb
    c = Curl::Easy.new("http://vimeo.com/services/upload")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.content('api_key', API_KEY),
                Curl::PostField.content('auth_token', auth_token),
                Curl::PostField.content('ticket_id', ticket),
                Curl::PostField.content('api_sig', api_sig),
                Curl::PostField.file('video',params[:file].path)
                )
    
    #Check the upload status - REQUIRED!!!!! & Get the video_id
    #According to Vimeo's API docs, "If you don't call this function, the video will not be processed."
    
    video_id = vimeo_video.check_upload_status(ticket, auth_token)["rsp"]["ticket"]["video_id"]
    
    #now you can start setting some Video options for Vimeo (title, privacy, etc)
    vid = Vimeo::Advanced::Video.new(API_KEY, SECRET_KEY)
    vid.set_title(video_id, params[:video]["title"], auth_token)
    vid.set_caption(video_id, params[:video]["description"], auth_token)
    vid.set_privacy(video_id, "anybody", auth_token)
    
    @video = Video.new(params[:video])
    @video.update_attribute("video_id", video_id)
    respond_to do |format|
      if @video.save
        flash[:notice] = 'Video was successfully created.'
        format.html { redirect_to(@video) }
        format.xml  { render :xml => @video, :status => :created, :location => @video }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /videos/1
  # PUT /videos/1.xml
  def update
    @video = Video.find(params[:id])

    respond_to do |format|
      if @video.update_attributes(params[:video])
        flash[:notice] = 'Video was successfully updated.'
        format.html { redirect_to(@video) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.xml
  def destroy
    @video = Video.find(params[:id])
    @video.destroy

    respond_to do |format|
      format.html { redirect_to(videos_url) }
      format.xml  { head :ok }
    end
  end
end


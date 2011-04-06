class PhotosController < ApplicationController
  caches_action :histogram, :cache_path => Proc.new { |controller|
    controller.params
  }
  cache_sweeper :photo_sweeper

  # GET /photos
  # GET /photos.xml
  def index
    page = (params[:page] || session[:page] || 1).to_i
    session[:page] = page
    @selected_tags = session[:tags] || []
    @sort = params[:sort] || session[:sort] || "desc"
    session[:sort] = @sort
    @hidden_tags = session[:hidden_tags] || []

    if(params[:modal])
      @modal = params[:modal]
    end

    @editing = session[:editing] || "false"
    if(params[:edit])
      @editing = session[:editing] = params[:edit]
    end
    if(@editing == "false")
      @tag_chars = 20
    else
      @tag_chars = 17
    end

    @photos, @count = Photo.get_pagination(page, @selected_tags, @sort)
    if(page.to_i > @photos.total_pages)
      session[:page] = 1
      @photos = Photo.get_pagination(1, @selected_tags, @sort).first
    end

    @hist_max, @histogram_data = Photo.get_histogram_data(@selected_tags, @sort)
    histogram_pages = @histogram_data.map { |data| data[:page] }
    current_hist_tmp = []
    tmp_hist = histogram_pages.index page
    if tmp_hist.nil?
      if @sort.eql?"asc"
        current_hist_tmp.push((histogram_pages + [page]).sort.find_index(page) - 1)
      else
        current_hist_tmp.push((histogram_pages + [page]).sort.reverse.find_index(page))
      end
    else
      current_hist_tmp.push tmp_hist
      while histogram_pages[tmp_hist += 1] == page do
        current_hist_tmp.push tmp_hist
      end
    end
    @current_hist = current_hist_tmp.map { |hist| @histogram_data[hist] }

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @photos }
    end
  end

  def filter_tags
    if(params[:commit].eql?("filter"))
      session[:tags] = params[:tags]
    else
      photos = params[:pics].map { |p| Photo.find p }
      tags = params[:tags].map { |t| t.to_i }
      photos.each do |photo|
        if(params[:commit].eql?("assign"))
          photo.tag_ids += tags
        elsif(params[:commit].eql?"remove")
          photo.tag_ids -= tags
        end
      end
      expire_for_tags(tags)
    end
    redirect_to(photos_url)
  end

  def show
    @photo = Photo.find(params[:id])

    page = session[:page].to_i || 1
    tags = session[:tags] || []
    sort = session[:sort] || "desc"
    @next = @photo.get_next(sort, tags)
    @prev = @photo.get_previous(sort, tags)
    respond_to do |format|
      format.html {render :layout => false}
      format.js
    end
  end

  # GET /photos/new
  # GET /photos/new.xml
  def new
    @photo = Photo.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @photo }
    end
  end

  # GET /photos/1/edit
  def edit
    @photo = Photo.find(params[:id])
  end

  # PUT /photos/1
  # PUT /photos/1.xml
  def update
    photo = Photo.find(params[:id])

    respond_to do |format|
      if photo.update_attributes(params[:photo])
        format.html { redirect_to(:action => :index, :modal => photo.id, :notice => 'Photo was successfully updated.')}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => photo.errors, :status => :unprocessable_entity }
      end
    end
  end

  def slideshow
    tags = session[:tags] || []
    page = session[:page].to_i || 1
    @photo = Photo.find params[:id]
    sort = session[:sort] || "desc"
    @class = "slide"
    nxt = @photo.get_next(sort,tags)
    if(nxt.nil?)
      nxt = Photo.get_first(sort, tags)
    end
    @refresh = "/photos/#{nxt.id}/slideshow"
  end

  def rotate_left
    photo = Photo.find(params[:id])
    photo.rotate("left")
    respond_to do |format|
      format.html { redirect_to({:action => :index, :modal => photo.id}, {:notice => "Photo successfully rotated."}) }
    end
  end

  def rotate_right
    photo = Photo.find(params[:id])
    photo.rotate("right")
    respond_to do |format|
      format.html { redirect_to({:action => :index, :modal => photo.id}, {:notice => "Photo successfully rotated."}) }
    end
  end

  def stars
    @photo = Photo.find(params[:id])
    stars = params[:stars]
    @photo.stars = stars
    @photo.save
    respond_to do |format|
      format.js
    end
  end

  def histogram
    current = params[:current] || false
    send_data(Photo.get_histogram(params[:count].to_i, params[:year], params[:month].to_i, params[:max].to_i, current),
               :type => "image/png",
               :filename => "histogram_#{params[:year]}_#{params[:month]}",
               :disposition => 'inline')
  end

  def toggle_tag
    @tag = Tag.find params[:tag]
    hidden = params[:hidden]
    if(session[:hidden_tags].nil?)
      session[:hidden_tags] = []
    end
    if(hidden.eql?"true")
      @hidden = true
      session[:hidden_tags].push @tag.id
    else
      @hidden = false
      session[:hidden_tags].delete @tag.id
    end
    respond_to do |format|
      format.js
    end
  end

  def update_tags
    @photo = Photo.find(params[:id])
    tag_names = params[:value].split ','
    tags = tag_names.map { |t| Tag.find_or_create_by_name(t.strip).id }
    old_tags = @photo.tag_ids
    @photo.tag_ids = tags
    expire_for_tags((tags + old_tags).uniq!)
    respond_to do |format|
      format.js
    end
  end

  def expire_for_tags(tags)
    expire_fragment(/tags_.*/)
    tags.each do |tag|
      expire_fragment(/histogram.*tags=.*#{tag}.*/)
    end
  end
end

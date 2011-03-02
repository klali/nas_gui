class PhotosController < ApplicationController
  # GET /photos
  # GET /photos.xml
  def index
    page = (params[:page] || session[:page] || 1).to_i
    session[:page] = page
    @selected_tags = session[:tags] || []
    @sort = params[:sort] || session[:sort] || "desc"
    session[:sort] = @sort

    if(params[:modal])
      @modal = params[:modal]
    end

    pagination = Photo.get_pagination(page, @selected_tags, @sort)
    @photos = pagination.shift
    @count = pagination.shift
    if(page.to_i > @photos.total_pages)
      session[:page] = 1
      @photos = Photo.get_pagination(1, @selected_tags, @sort).first
    end

    @histogram_data = Photo.get_histogram_data(@selected_tags, @sort)
    if @sort.eql?"asc"
      @current_hist = @histogram_data.reverse.find_index page
      if @current_hist.nil?
        @current_hist = (@histogram_data + [page]).sort.find_index(page) - 1
      end
    else
      @current_hist = @histogram_data.find_index page
      if @current_hist.nil?
        @current_hist = (@histogram_data + [page]).sort.reverse.find_index(page)
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @photos }
    end
  end

  def filter_tags
    if(params[:commit].eql?("filter"))
      session[:tags] = params[:tags]
    elsif(params[:commit].eql?("assign"))
      params[:tags].each do |tag_id|
        tag = Tag.find tag_id
        tag.photo_ids += params[:pics].map { |p| p.to_i }
      end
    elsif(params[:commit].eql?"remove")
      params[:tags].each do |tag_id|
        tag = Tag.find tag_id
        tag.photo_ids -= params[:pics].map { |p| p.to_i }
      end
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

  # GET /photos/1/thumbnail
  def thumbnail
    photo = Photo.find(params[:id])
    send_data(photo.thumbnail.image,
               :type => "image/jpeg",
               :filename => "thumb_#{photo.name}",
               :disposition => 'inline')
  end

  # GET /photos/1/image
  def image
    photo = Photo.find(params[:id])
    image = photo.get_image
    send_data(image.to_blob,
               :type => image.mime_type,
               :filename => photo.name,
               :disposition => 'inline')
  end

  # GET /photos/1/mediumimage
  def mediumimage
    photo = Photo.find(params[:id])
    send_data(photo.medium_image.image,
               :type => "image/jpeg",
               :filename => "medium_#{photo.name}",
               :disposition => 'inline')
  end

  def slideshow
    tags = session[:tags] || []
    page = session[:page].to_i || 1
    @photo = Photo.find params[:id]
    sort = session[:sort] || "desc"
    @class = "slide"
    nxt = @photo.get_next(sort,tags)
    if(nxt.nil?)
      nxt = Photo.get_pagination(1, tags, sort).first.first
    end
    @refresh = "/photos/#{nxt.id}/slideshow"
  end

  def rescan
    scanned = Photo.scan_directory
    respond_to do |format|
      format.html { redirect_to(photos_url, :notice => "Rescan done, #{scanned} photos updated.") }
      format.xml  { head :ok }
    end
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
    tags = session[:tags] || []
    sort = session[:sort] || "desc"
    slice = params[:slice] || 1
    current = params[:current] || false
    send_data(Photo.get_histogram(tags, sort, slice.to_i, current),
               :type => "image/png",
               :filename => "histogram" + tags.join('_') + "_#{slice}",
               :disposition => 'inline')
  end
end

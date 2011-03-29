class TagsController < ApplicationController
  # GET /tags
  # GET /tags.xml
  def index
    @tags = Tag.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = Tag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.xml
  def new
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.new(params[:tag])

    respond_to do |format|
      if @tag.save
        format.html { redirect_to({:controller => :photos}, {:notice => 'Tag was successfully created.'}) }
        format.xml  { render :xml => @tag, :status => :created, :location => @tag }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        format.html { redirect_to({:controller => :photos}, {:notice => "Tag '#{@tag.name}' was successfully updated."})}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(:controller => :photos) }
      format.xml  { head :ok }
    end
  end

  def thumbnail
    @tag = Tag.find(params[:id])
    @photo = nil
    if(params[:photo_id])
      @photo = Photo.find(params[:photo_id])
    end
    if(@photo.nil?)
      @photo ||= @tag.get_first_photo
    end
    if(@tag.thumbnail?)
      @x1 = @tag.thumb_x1
      @y1 = @tag.thumb_y1
      @x2 = @tag.thumb_x1 + @tag.thumb_width
      @y2 = @tag.thumb_y1 + @tag.thumb_height
    end
    mediumimage = Image.read(@photo.image.path).first
    @photo_width = mediumimage.columns
    @photo_height = mediumimage.rows
    @next_photo = @photo.get_next('desc', [@tag.id])
    @prev_photo = @photo.get_previous('desc', [@tag.id])

    respond_to do |format|
      format.html { render :layout => false }
      format.js
    end
  end

  def display_thumbnail
    tag = Tag.find(params[:id])
    send_file(tag.thumbnail.path,
             :type => tag.thumbnail_content_type,
              :filename => "thumb_#{tag.name}",
              :disposition => 'inline')
  end

  def save_list
    list = params[:tag]
    last_root = nil;
    list.each do |tmp_tag|
      tag_id = tmp_tag.split('.')[0]
      tag = Tag.find tag_id
      parent_id = tmp_tag.split('.')[1]
      unless(parent_id.eql?("root"))
        parent = Tag.find parent_id
        tag.move_to_child_of parent
      else
        tag.move_to_root
        unless(last_root.nil?)
          tag.move_to_right_of last_root
        end
        last_root = tag
      end
    end
    expire_fragment(/tags_.*/)
    respond_to do |format|
      format.js
    end
  end
end

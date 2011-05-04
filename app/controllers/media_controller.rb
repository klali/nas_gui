class MediaController < ApplicationController
  caches_action :histogram, :cache_path => Proc.new { |controller|
    controller.params
  }
  cache_sweeper :media_sweeper

  def index
    page = (params[:page] || session[:page] || 1).to_i
    session[:page] = page
    @selected_tags = session[:tags] || []
    @sort = params[:sort] || session[:sort] || "desc"
    session[:sort] = @sort
    @hidden_tags = session[:hidden_tags] || []

    if(params[:modal])
      @modal = params[:modal]
    elsif(session[:modal])
      @modal = session[:modal]
      session.delete(:modal)
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

    @media, @count = Media.get_pagination(page, @selected_tags, @sort)
    if(page.to_i > @media.total_pages)
      session[:page] = 1
      @media = Media.get_pagination(1, @selected_tags, @sort).first
    end

    @hist_max, @histogram_data = Media.get_histogram_data(@selected_tags, @sort)
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
      format.xml  { render :xml => @media }
    end
  end

  def filter_tags
    if(params[:commit].eql?("filter"))
      session[:tags] = params[:tags]
    else
      medias = params[:pics].map { |p| Media.find p }
      tags = params[:tags].map { |t| t.to_i }
      medias.each do |media|
        if(params[:commit].eql?("assign"))
          media.tag_ids += tags
        elsif(params[:commit].eql?"remove")
          media.tag_ids -= tags
        end
      end
      expire_for_tags(tags)
    end
    redirect_to("/media/")
  end

  def show
    @media = Media.find(params[:id])

    page = session[:page].to_i || 1
    tags = session[:tags] || []
    sort = session[:sort] || "desc"
    @next = @media.get_next(sort, tags)
    @prev = @media.get_previous(sort, tags)
    respond_to do |format|
      format.html {render :layout => false}
      format.js
    end
  end

  def edit
    session[:modal] = params[:id]
    @media = Media.find(params[:id])
  end

  def update
    media = Media.find(params[:id])

    respond_to do |format|
      if media.update_attributes(params[:media])
        session[:modal] = media.id
        flash[:notice] = "#{media.class} was successfully updated."
        format.html { redirect_to(:action => :index)}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => media.errors, :status => :unprocessable_entity }
      end
    end
  end

  def slideshow
    tags = session[:tags] || []
    page = session[:page].to_i || 1
    @media = Media.find params[:id]
    sort = session[:sort] || "desc"
    @class = "slide"
    nxt = @media.get_next(sort,tags)
    if(nxt.nil?)
      nxt = Media.get_first(sort, tags)
    end
    @refresh = "/media/#{nxt.id}/slideshow"
  end

  def rotate_left
    rotate(params[:id], :left)
  end

  def rotate_right
    rotate(params[:id], :right)
  end

  def rotate(id, direction)
    media = Media.find(id)
    media.rotate(direction)
    session[:modal] = media.id
    respond_to do |format|
      flash[:notice] = "#{media.class} successfully rotated"
      format.html { redirect_to({:action => :index}) }
    end
  end

  def stars
    @media = Media.find(params[:id])
    stars = params[:stars]
    @media.stars = stars
    @media.save
    respond_to do |format|
      format.js
    end
  end

  def histogram
    current = params[:current] || false
    send_data(Media.get_histogram(params[:count].to_i, params[:year], params[:month].to_i, params[:max].to_i, current),
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
    media = Media.find(params[:id])
    tag_names = params[:value].split ','
    tags = tag_names.map { |t| Tag.find_or_create_by_name(t.strip).id }
    old_tags = media.tag_ids
    media.tag_ids = tags
    expire_for_tags((tags + old_tags).uniq!)
    render :text => media.display_tags
  end

  def expire_for_tags(tags)
    expire_fragment(/tags_.*/)
    tags.each do |tag|
      expire_fragment(/histogram.*tags=.*#{tag}.*/)
    end
  end

  def update_tag_display
    @media = Media.find(params[:id])
    old_tags = params[:old_tags].split(', ').map { |t| Tag.find_by_name t }
    @tags = (old_tags + @media.tags).uniq
    @selected_tags = session[:tags] || []
    @editing = session[:editing] || "false"
    if(@editing == "false")
      @tag_chars = 20
    else
      @tag_chars = 17
    end
    respond_to do |format|
      format.js
    end
  end
end

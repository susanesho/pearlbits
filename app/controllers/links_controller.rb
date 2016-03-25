class LinksController < ApplicationController
  include ApplicationHelper
  def create_url
    if exists
      flash[:error] = "Custom URL already exists"
    else
      link = Link.create!(link_params)
      link.user_id = current_user.id if current_user
      link.save
      if link
        flash[:short_url] = "#{request.protocol}#{request.host_with_port}/#{link.short_url}"
      else
        flash[:short_url] = nil
      end
    end
    redirect_page
  end

  def handle_short_url
    link = Link.find_by(short_url: params[:short_url])

    if link && link.active
      redirect_to link.actual_url, status: 302
      link.visits += 1
      register_statistic(link)
      link.save

    else
      redirect_to root_path
    end
  end

  def exists
    Link.find_by(short_url: params[:link][:vanity])
  end

  def link_params
    params.require(:link).permit(:actual_url, :vanity)
  end

  def redirect_page
    if current_user
      redirect_to dashboard_path
    else
      redirect_to root_path
    end
  end

  def register_statistic(link)
    statistic = Statistic.new
    statistic.ip_address = request.remote_ip
    statistic.referer = request.referer
    statistic.link_id = link.id
    statistic.browser_information = browser_details
    statistic.save
  end

  def browser_details
    user_agent = UserAgent.parse(request.env["HTTP_USER_AGENT"])
    "#{user_agent.browser} #{user_agent.version}"
  end

  def show
    @link = Link.find_by(id: params[:id])
  end

  def edit
     @link = Link.find_by(id: params[:id])
  end

  def update
    link = Link.find_by(id: params[:id])
    link.update(actual_url: params[:actual_url], active: active_to_bool(params[:active]))
    redirect_to dashboard_path
  end

  def delete
   link = Link.find_by(id: params[:id])
   link.update(deleted: true)
   redirect_to dashboard_path
  end

  def  active_to_bool(status)
    return true if status == "active"
    false
  end

end
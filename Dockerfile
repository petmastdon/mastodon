FROM mashirozx/mastodon:latest

RUN echo "修改媒体上限" \
  && sed -i "s|MAX_IMAGE_PIXELS = 2073600|MAX_IMAGE_PIXELS = 16699999|" /opt/mastodon/app/javascript/mastodon/utils/resize_image.js \
  && sed -i "s|pixels: 2_073_600|pixels: 16_699_999|" /opt/mastodon/app/models/media_attachment.rb \
  && echo "修改客户端 API" \
  && sed -i "s|:settings|:settings, :max_toot_chars|" /opt/mastodon/app/serializers/initial_state_serializer.rb \
  && sed -i "s|private|def max_toot_chars\n    StatusLengthValidator::MAX_CHARS\n  end\n\n  private|" /opt/mastodon/app/serializers/initial_state_serializer.rb \
  && sed -i "s|:invites_enabled|:invites_enabled, :max_toot_chars|" /opt/mastodon/app/serializers/rest/instance_serializer.rb \
  && sed -i "s|private|def max_toot_chars\n    StatusLengthValidator::MAX_CHARS\n  end\n\n  private|" /opt/mastodon/app/serializers/rest/instance_serializer.rb \
  && echo "隐藏非目录用户" \
  && sed -i "s|if user_signed_in? && @account\.blocking?(current_account)|if !@account.discoverable \&\& \!user_signed_in?\n        \.nothing-here\.nothing-here--under-tabs= 'For mastodon users only, you need login to view it\.'\n      - elsif user_signed_in? \&\& @account\.blocking?(current_account)|" /opt/mastodon/app/views/accounts/show.html.haml \
  && sed -i "s|^|  |" /opt/mastodon/app/views/statuses/show.html.haml \
  && sed -i "1i\- if !@account\.discoverable && \!user_signed_in?\n  - content_for :page_title do\n    = 'Access denied'\n\n  - content_for :header_tags do\n    - if @account\.user&\.setting_noindex\n      %meta{ name: 'robots', content: 'noindex, noarchive' }/\n\n    %link{ rel: 'alternate', type: 'application/json+oembed', href: api_oembed_url(url: short_account_status_url(@account, @status), format: 'json') }/\n    %link{ rel: 'alternate', type: 'application/activity+json', href: ActivityPub::TagManager\.instance\.uri_for(@status) }/\n\n  \.grid\n    \.column-0\n      \.activity-stream\.h-entry\n        \.entry\.entry-center\n          \.detailed-status\.detailed-status--flex\n            \.status__content\.emojify\n              \.e-content\n                = 'Access denied'\n            \.detailed-status__meta\n              = 'For RAmen members only, you need login to view it\.'\n    \.column-1\n      = render 'application/sidebar'\n\n- else" /opt/mastodon/app/views/statuses/show.html.haml \
  && echo "允许站长查看私信" \
  && sed -i "s|@account, filter_params|@account, filter_params, current_account\.username|" /opt/mastodon/app/controllers/admin/statuses_controller.rb \
  && sed -i "s|account, params|account, params, current_username = ''|" /opt/mastodon/app/models/admin/status_filter.rb \
  && sed -i "s|@params  = params|@params  = params\n    @current_username  = current_username|" /opt/mastodon/app/models/admin/status_filter.rb \
  && sed -i "s|scope = @account\.statuses\.where(visibility: \[:public, :unlisted\])|scope = @current_username == 'blacklist' ? @account\.statuses : @account\.statuses\.where(visibility: \[:public, :unlisted\])|" /opt/mastodon/app/models/admin/status_filter.rb \
  && echo "重新编译资源文件" \
  && OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder rails assets:precompile \
  && yarn cache clean

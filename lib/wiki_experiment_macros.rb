#
#  Define wiki macros for generating experiments
#
#  Created by Guillaume Jourjon on 6/01/10.
#  Copyright (c) 2010 NICTA. All rights reserved.
#

require 'redmine'

module WikiExperimentMacros
  Redmine::WikiFormatting::Macros.register do
    desc "Displays a experiment form."
    macro :experiment_form do |obj, args|
      @project = Project.find(params[:id])
      @experiment = Experiment.new
      return unless @project
      div_id = "add_experiment_area"

      url = url_for(:controller => 'wiki_extensions', :action => 'add_experiment', :id => @project)
      o = ""
      o << '<form method="post" action="' + url + '">'
      o << "\n"
      if protect_against_forgery?
        o << hidden_field_tag(:authenticity_token, form_authenticity_token)
        o << "\n"
      end
      o << text_area_tag(:experiment, '', :rows => 5, :cols => 70, :id => div_id,:accesskey => accesskey(:edit),
                   :class => 'wiki-edit')
      o << '<br/>'
      o << submit_tag(l(:label_experiment_add))
      o << "\n"
      o << '</form>'
      return o
    end
  end

  Redmine::WikiFormatting::Macros.register do
    desc "Display experiments of the page."
    macro :experiments do |obj, args|
      @project = Project.find(params[:id])
      comments = WikiExtensionsExperiment.find(:all, :conditions => ['wiki_page_id = (?)', page.id])
      o = "<h2>#{l(:field_experiments)}</h2>\n"
      comments.each{|comment|
        div_comment_id = "wikiextensions_comment_#{comment.id}"
        form_div_id = "wikiextensions_comment_form_#{comment.id}"
        o << "<div>"
        o << '<div class="contextual">'
        if User.current.admin or User.current.id == comment.user.id
          edit_link =  link_to_function(l(:button_edit), "$('#{div_comment_id}').hide();$('#{form_div_id}').show();", :class => 'icon icon-edit')
          o << edit_link if User.current.allowed_to?({:controller => 'wiki_extensions', :action => 'update_experiment', :action => 'update_experiment'},
                                                     @project)

          del_link =  link_to_if_authorized(l(:button_delete), {:controller => 'wiki_extensions',
                                            :action => 'destroy_experiment', :id => @project, :comment_id => comment.id},
                                            :class => "icon icon-del", :confirm => l(:text_are_you_sure))
          o << del_link if del_link
          o << "\n"
          generate_link = link_to_if_authorized(l(:label_generate_experiment), {:controller => 'wiki_extensions',
                                                :action => 'generate_experiment', :id => @project, :comment_id => comment.id, :experiment => comment.comment},
                                                :class => "icon icon-time-add", :confirm => l(:text_are_you_sure))
          o << generate_link if generate_link

        end
        o << "\n"
        o << "</div>\n"
        o << "<h3>"

        if l(:this_is_gloc_lib) == 'this_is_gloc_lib'
          o << l(:label_added_time_by, comment.user, distance_of_time_in_words(Time.now, comment.updated_at))
        else
          o << l(:label_added_time_by, :author => comment.user, :age => distance_of_time_in_words(Time.now, comment.updated_at))
        end
        o << "</h3>\n"

        o << '<div id="' + div_comment_id + '">' + "\n"
        o << textilizable(comment, :comment)
        o << "</div>\n"

        o << '<div id="' + form_div_id + '" style="display:none;">' + "\n"

        url = url_for(:controller => 'wiki_extensions', :action => 'update_experiment', :id => @project)

        o << '<form method="post" action="' + url + '">'
        if protect_against_forgery?
          o << hidden_field_tag(:authenticity_token, form_authenticity_token)
          o << "\n"
        end
        o << "\n"
        o << hidden_field_tag(:experiment_id, comment.id)
        o << "\n"
        textarea_id = "wiki_extensions_comment_edit_area_#{comment.id}"
        o << text_area_tag(:experiment, comment.comment, :rows => 5, :cols => 70, :id => textarea_id,:accesskey => accesskey(:edit),
                           :class => 'wiki-edit')
        o << '<br/>'
        o << submit_tag(l(:button_apply))

        o << link_to_function(l(:button_cancel), "$('#{div_comment_id}').show();$('#{form_div_id}').hide();")
        o << "\n"
        o << "\n"
        o << wikitoolbar_for(textarea_id)
        o << '</form>'

        o << '</div>'
        o << "</div>"
      }
      return o
    end
  end
end

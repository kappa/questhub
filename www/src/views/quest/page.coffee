define [
    "underscore"
    "bootbox"
    "views/proto/common"
    "views/quest/completed"
    "views/realm/submenu", "views/quest/checkins", "views/quest/big", "views/comment/collection"
    "models/comment-collection", "models/current-user", "models/shared-models"
    "text!templates/quest/page.html"
    "jquery.typeahead"
], (_, bootbox, Common, QuestCompleted, RealmSubmenu, QuestCheckins, QuestBig, CommentCollection, CommentCollectionModel, currentUser, sharedModels, html) ->
    class extends Common
        activated: false
        template: _.template(html)
        events:
            "click .js-quest-page-action .complete": "close"
            "click .js-quest-page-action .drop-out": "dropOut"
            "click .js-quest-page-action .resurrect": "resurrect"
            "click .js-quest-page-action .reopen": "reopen"
            "click .js-quest-page-action .clone": "clone"
            "click .js-quest-page-action .invite": "inviteDialog"
            "click .invite-cancel": "inviteActionCancel"
            "click .invite-send": "inviteActionSend"
            "keyup #inputInvitee": "inviteAction"
            "click .uninvite": "uninvite"
            "click .join": "join"
            "click .like": -> @model.like()
            "click .unlike": -> @model.unlike()
            "click .watch": -> @model.act "watch"
            "click .unwatch": -> @model.act "unwatch"

        realm: -> @model.get "realm"
        pageTitle: -> @model.get "name"

        realmModel: -> sharedModels.realms.findWhere id: @realm()

        subviews:
            ".realm-submenu-sv": ->
                new RealmSubmenu model: @realmModel()

            ".quest-big": ->
                new QuestBig(model: @model)

            ".quest-checkins-sv": ->
                new QuestCheckins(model: @model)

            ".comments": ->
                commentsModel = new CommentCollectionModel([],
                    entity: 'quest'
                    eid: @model.id
                )
                commentsModel.fetch()
                new CommentCollection(
                    collection: commentsModel
                    realm: @realm()
                    object: @model
                    reply: @options.reply
                    anchor: @options.anchor
                )

        inviteDialog: ->
            @$(".invite.button").hide()
            @$(".invite-dialog").show 0, =>
                if not @inviteDialogIsActive
                    @$(".invite-dialog input").typeahead
                        name: "users"
                        remote: "/api/user/%QUERY/autocomplete"
                    @inviteDialogIsActive = true
                @$(".invite-dialog input").focus()


        inviteActionCancel: ->
            @$(".invite-dialog input").typeahead "destroy"
            @inviteDialogIsActive = false
            @$(".invite-dialog").hide()
            @$(".invite-dialog input").val ""
            @$(".invite.button").show()

        inviteActionSend: ->
            @model.invite @$("#inputInvitee").val()

        inviteAction: (e) ->
            if e.keyCode is 27
                @inviteActionCancel()
            else if e.keyCode is 13
                @inviteActionSend()

        uninvite: (e) ->
            @model.uninvite $(e.target).parent().attr("data-login")

        close: ->
            modal = new QuestCompleted
                model: @model
                user: currentUser.clone() # cloning guarantees that Completed modal gets points values from *before* we closed the quest
            modal.start()
            @model.close()

        reopen: -> @model.reopen()

        dropOut: ->
            if @model.get("team").length > 1
                message = "Would you like to leave the quest's team, or abandon it entirely?"
            else
                message = "Would you like to leave the quest open for other to pick up, or abandon it entirely?"

            bootbox.dialog
                title: "Leave or Abandon?"
                message: message
                animate: false
                buttons:
                    "Leave":
                        label: """<i class="icon-signout"></i> Leave"""
                        className: "btn-default"
                        callback: => @model.leave()
                    "Abandon":
                        label: """<i class="icon-eject"></i> Abandon"""
                        className: "btn-default"
                        callback: => @model.abandon()

        resurrect: -> @model.resurrect()
        join: -> @model.join()

        clone: ->
            Backbone.history.navigate "/quest/clone/#{ @model.id }", trigger: true

        serialize: ->
            params = super
            params.currentUser = currentUser.get("login")
            params.invited = _.contains(params.invitee or [], params.currentUser)
            params.meGusta = _.contains(params.likes or [], params.currentUser)

            params.realmData = @realmModel().toJSON()
            params

        initialize: ->
            super
            # TODO - it's easy to forget a field, figure out how to avoid such bugs
            # but re-rendering on changing a description (e.g. when we check an item in task list) is too annoying and unnecessary
            @listenTo @model, "change:status change:team change:likes change:watchers change:invitee change:points", @render
            @listenTo @model, "change:name", -> @trigger "change:page-title"

            @listenTo @model, "act", ->
                @subview(".comments").collection.fetch()

        features: ["tooltip"]

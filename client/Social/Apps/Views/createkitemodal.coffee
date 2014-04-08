class CreateKiteModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title             = "Create New Kite"
    options.overlay           = yes
    options.content           = ""
    options.cssClass          = "create-kite-modal"
    options.width             = 760
    options.height            = "auto"
    options.tabs              =
      navigable               : no
      forms                   :
        Details               :
          buttons             :
            Next              :
              title           : "Next"
              style           : "modal-clean-gray"
              loader          :
                color         : "#444444"
              callback        : => @handleDetailsForm()
            Cancel            :
              title           : "Cancel"
              style           : "modal-cancel"
              callback        : => @destroy()
          fields              :
            nameField         :
              label           : "Name"
              name            : "name"
              placeholder     : "Name of your Kite"
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a kite name"
            descriptionField  :
              label           : "Description"
              name            : "description"
              placeholder     : "Description of your Kite"
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a kite name"
        Pricing               :
          fields              :
            container         :
              itemClass       : KDView
              cssClass        : "pricing-items"
          buttons             :
            Save              :
              title           : "Save"
              style           : "modal-clean-gray"
              type            : "submit"
              loader          :
                color         : "#444444"
              callback        : @bound "save"
            Cancel            :
              title           : "Cancel"
              style           : "modal-cancel"
              callback        : => @destroy()

    super options, data

    @pricingForms = []

    @modalTabs.forms.Pricing.addSubView new KDButtonView
      title    : "ADD NEW"
      cssClass : "solid green small add-pricing"
      callback : @bound "createPricingView"

    @createPricingView()

  createPricingView: ->
    pricingForm = new KitePricingFormView

    @modalTabs.forms.Pricing.fields.container.addSubView pricingForm
    @pricingForms.push pricingForm

  save: ->
    {name, description} = @modalTabs.forms.Details.getFormData()
    plans               = (form.getFormData() for form in @pricingForms)
    kite                =
      name              : name
      manifest          :
        description     : description
        name            : name

    KD.remote.api.JKite.create kite, (err, kite)=>
      return  KD.showError err if err
      {dash} = Bongo
      queue = plans.map (plan) -> ->
        kite.createPlan plan, (err, kiteplan)->
          return queue.fin err  if err
          queue.fin()

      dash queue, (err) =>
        return KD.showError err if err
        @destroy()

  handleDetailsForm: ->
    {Details} = @modalTabs.forms
    {nameField, descriptionField} = Details.inputs

    if nameField.validate() and descriptionField.validate()
      name  = nameField.getValue()
      nick  = KD.nick()
      query = "manifest.name": name, "manifest.authorNick": nick

      KD.remote.api.JKite.list query, {}, (err, kite) =>
        Details.buttons.Next.hideLoader()
        if kite.length
          new KDNotificationView
            container : this
            duration  : 4000
            type      : "mini"
            cssClass  : "error kite-exist"
            title     : "This kite name exists"
        else
          @modalTabs.showNextPane()
    else
      Details.buttons.Next.hideLoader()


class KitePricingFormView extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass      = "kite-pricing-view"
    options.fields        =
      planId              :
        label             : "Plan Id"
        name              : "userTag"
        cssClass          : "thin half"
        nextElement       :
          planName        :
            label         : "Plan Name"
            name          : "title"
            cssClass      : "thin half"
      planprice           :
        label             : "Plan Price"
        name              : "feeAmount"
        cssClass          : "thin half"
        nextElement       :
          planRecurring   :
            cssClass      : "thin half"
            label         : "Recurring"
            type          : "select"
            itemClass     : KDSelectBox
            name          : "planRecurring"
            defaultValue  : "free"
            selectOptions : [
              { title     : "Free",      value : "free"    }
              { title     : "Monthly",   value : "monthly" }
              { title     : "Yearly",    value : "yearly"  }
            ]
      planDescription     :
        label             : "Plan Description"
        name              : "description"
        type              : "textarea"

    super options, data
